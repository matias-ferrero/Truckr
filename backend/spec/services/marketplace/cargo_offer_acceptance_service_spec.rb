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
  end
end
