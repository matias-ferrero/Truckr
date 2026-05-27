# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::Create do
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:carrier_user) { create(:user, :with_carrier) }
  let(:cargo)        { create(:cargo, shipper: shipper_user.shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier_user.carrier, amount_cents: 12_000_000) }
  let(:shipment)     { create(:shipment, :accepted, cargo_offer: offer) }

  describe ".call" do
    it "writes an escrowed Payment whose amount is frozen from the CargoOffer" do
      payment = described_class.call(shipment: shipment)

      expect(payment).to be_persisted
      expect(payment.state).to eq("escrowed")
      expect(payment.shipment_id).to eq(shipment.id)
      expect(payment.amount_cents).to eq(12_000_000)
      expect(payment.currency).to eq(offer.currency)
      expect(payment.provider).to eq("fake")
      expect(payment.provider_reference).to start_with("fake-")
      expect(payment.escrowed_at).to be_present
      expect(payment.failed_at).to be_nil
    end

    it "freezes amount_cents to the CargoOffer value at the moment of create" do
      payment = described_class.call(shipment: shipment)
      expect { offer.update_column(:amount_cents, 99) }.not_to(change { payment.reload.amount_cents })
      expect(payment.amount_cents).to eq(12_000_000)
    end

    it "advances the Shipment FSM accepted → pending_payment after a successful escrow" do
      described_class.call(shipment: shipment)
      expect(shipment.reload).to be_status_pending_payment
      expect(shipment.payment_received_at).to be_present
    end

    it "raises ConflictError(:shipment_not_accepted) when the Shipment is not accepted" do
      escrowed_first = described_class.call(shipment: shipment)
      # First call already moved the shipment to :pending_payment; a second
      # attempt must be rejected on the status guard.
      expect { described_class.call(shipment: shipment.reload) }
        .to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:shipment_not_accepted) }
      expect(escrowed_first).to be_state_escrowed
    end

    it "raises ConflictError(:already_paid) when an escrowed Payment exists on a still-accepted Shipment" do
      # Pre-existing escrowed Payment without the matching status transition
      # (defensive branch — keeps the invariant if the FSM advance is ever
      # decoupled from Payments::Create).
      create(:payment, :escrowed, shipment: shipment)

      expect { described_class.call(shipment: shipment.reload) }
        .to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:already_paid) }
    end

    it "is race-safe — two concurrent threads land at most one escrowed row" do
      target = shipment
      barrier = Concurrent::CyclicBarrier.new(2) if defined?(Concurrent::CyclicBarrier)

      threads = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            barrier&.wait
            described_class.call(shipment: Shipment.find(target.id))
          rescue described_class::ConflictError
            nil
          end
        end
      end
      threads.each(&:join)

      expect(target.payments.where(state: "escrowed").count).to eq(1)
    end
  end
end
