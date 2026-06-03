# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketplace::CargoOfferAcceptanceService do
  describe "#call" do
    let(:shipper) { create(:shipper) }
    let(:cargo) do
      create(:cargo, shipper: shipper, status: "open",
             pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
    end
    let(:carrier) { create(:carrier) }
    let(:winner_window) do
      create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
             available_from: 2.days.from_now, available_to: 10.days.from_now)
    end
    let(:winner) do
      create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: winner_window,
             status: "pending", expires_at: 2.days.from_now)
    end

    it "uses with_lock around the winner offer" do
      service = described_class.new(cargo_offer: winner)

      expect(winner).to receive(:with_lock).and_call_original
      service.call
    end

    it "rolls back the full transaction if sibling reject fails" do
      sibling_carrier = create(:carrier)
      sibling_window = create(:transport_window, vehicle: create(:vehicle, carrier: sibling_carrier), status: "pending_offer",
              available_from: 2.days.from_now, available_to: 10.days.from_now)
      create(:cargo_offer, cargo: cargo, carrier: sibling_carrier, transport_window: sibling_window,
             status: "pending", expires_at: 2.days.from_now)

      service = described_class.new(
        cargo_offer: winner,
        sibling_rejector: ->(_sibling) { raise "step_4_failure" }
      )

      expect { service.call }.to raise_error(RuntimeError, "step_4_failure")

      expect(winner.reload.status).to eq("pending")
      expect(winner.accepted_at).to be_nil
      expect(winner_window.reload.status).to eq("pending_offer")
      expect(cargo.reload.status).to eq("open")
      expect(Shipment.find_by(cargo_offer_id: winner.id)).to be_nil
    end

    it "creates a shipment in accepted state" do
      shipment = described_class.new(cargo_offer: winner).call

      expect(shipment.status).to eq("accepted")
      expect(shipment.accepted_at).to be_present
    end

    describe "realtime notifications (REQ-FE-00030)" do
      before { allow(Notifications::Publisher).to receive(:publish) }

      it "emits the broadcast after the transaction commits, not inside it (SQLite single-writer)" do
        # Regression for the Solid Cable self-lock: a broadcast writes to the
        # primary SQLite DB on its own connection, so emitting while the accept
        # transaction holds the write lock self-locks (SQLite3::BusyException).
        # With transactional fixtures the example holds one transaction; emitting
        # inside the service's own would show a second (savepoint) level. The
        # :test ActionCable adapter hides the real exception, so assert depth.
        observed = []
        allow(Notifications::Publisher).to receive(:publish) do
          observed << ActiveRecord::Base.connection.open_transactions
        end

        described_class.new(cargo_offer: winner).call

        expect(observed).not_to be_empty
        expect(observed).to all(eq(1))
      end

      it "publishes cargo_offer_accepted to the accepted offer's shipper with a shipment_id payload" do
        shipment = described_class.new(cargo_offer: winner).call

        expect(Notifications::Publisher).to have_received(:publish).with(
          user_id: shipper.user_id,
          type: :cargo_offer_accepted,
          payload: hash_including(
            cargo_offer_id: winner.id,
            cargo_id: cargo.id,
            amount_cents: winner.amount_cents,
            currency: winner.currency,
            shipment_id: shipment.id
          )
        )
      end

      it "publishes cargo_offer_rejected for every auto-rejected sibling, addressed to its shipper" do
        sibling_carrier = create(:carrier)
        sibling_window = create(:transport_window, vehicle: create(:vehicle, carrier: sibling_carrier),
                status: "pending_offer", available_from: 2.days.from_now, available_to: 10.days.from_now)
        # Siblings live on the same Cargo, so they share the cargo's single
        # Shipper; the cascade addresses each sibling's own shipper resolution.
        sibling = create(:cargo_offer, cargo: cargo, carrier: sibling_carrier, transport_window: sibling_window,
                         status: "pending", expires_at: 2.days.from_now)

        described_class.new(cargo_offer: winner).call

        expect(sibling.reload.status).to eq("rejected")
        expect(Notifications::Publisher).to have_received(:publish).with(
          user_id: shipper.user_id,
          type: :cargo_offer_rejected,
          payload: hash_including(cargo_offer_id: sibling.id, cargo_id: cargo.id)
        )
      end

      it "does not publish for a sibling that did not end rejected" do
        sibling_carrier = create(:carrier)
        sibling_window = create(:transport_window, vehicle: create(:vehicle, carrier: sibling_carrier),
                status: "pending_offer", available_from: 2.days.from_now, available_to: 10.days.from_now)
        sibling = create(:cargo_offer, cargo: cargo, carrier: sibling_carrier, transport_window: sibling_window,
                         status: "pending", expires_at: 2.days.from_now)

        # A rejector that leaves the sibling pending exercises the
        # `next unless sibling.status == "rejected"` guard.
        described_class.new(cargo_offer: winner, sibling_rejector: ->(_sibling) { }).call

        expect(Notifications::Publisher).not_to have_received(:publish).with(
          hash_including(type: :cargo_offer_rejected, payload: hash_including(cargo_offer_id: sibling.id))
        )
      end

      it "still enqueues the durable acceptance email alongside the notification (no regression)" do
        allow(CargoOfferMailer).to receive(:notify_shipper_offer_accepted).and_call_original

        described_class.new(cargo_offer: winner).call

        expect(CargoOfferMailer).to have_received(:notify_shipper_offer_accepted).with(winner)
      end
    end
  end
end
