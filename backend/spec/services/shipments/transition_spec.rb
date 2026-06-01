# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shipments::Transition do
  let(:carrier_user) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:cargo)        { create(:cargo, shipper: shipper_user.shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier_user.carrier) }

  describe ".call" do
    it "transitions accepted -> in_transit when escrowed payment exists" do
      shipment = create(:shipment, :accepted, cargo_offer: offer)
      create(:payment, :escrowed, shipment: shipment)

      result = described_class.call(
        shipment: shipment,
        target_status: :in_transit,
        reason: "carrier_started_transit"
      )

      expect(result).to eq(shipment)
      expect(shipment.reload.status).to eq("in_transit")
      expect(shipment.picked_up_at).to be_present
    end

    it "transitions in_transit -> delivered" do
      shipment = create(:shipment, :in_transit, cargo_offer: offer)

      described_class.call(
        shipment: shipment,
        target_status: :delivered,
        reason: "carrier_delivered"
      )

      expect(shipment.reload.status).to eq("delivered")
      expect(shipment.delivered_at).to be_present
    end

    it "raises ConflictError(:shipment_not_accepted) for start_transit outside accepted" do
      shipment = create(:shipment, :in_transit, cargo_offer: offer)

      expect {
        described_class.call(
          shipment: shipment,
          target_status: :in_transit,
          reason: "carrier_started_transit"
        )
      }.to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:shipment_not_accepted) }
    end

    it "raises ConflictError(:shipment_not_paid) when accepted has no escrowed payment" do
      shipment = create(:shipment, :accepted, cargo_offer: offer)

      expect {
        described_class.call(
          shipment: shipment,
          target_status: :in_transit,
          reason: "carrier_started_transit"
        )
      }.to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:shipment_not_paid) }
    end

    it "raises ConflictError(:shipment_not_in_transit) when delivering from accepted" do
      shipment = create(:shipment, :accepted, cargo_offer: offer)
      create(:payment, :escrowed, shipment: shipment)

      expect {
        described_class.call(
          shipment: shipment,
          target_status: :delivered,
          reason: "carrier_delivered"
        )
      }.to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:shipment_not_in_transit) }
    end

    it "is race-safe — two concurrent start_transit calls leave only one transition" do
      shipment = create(:shipment, :accepted, cargo_offer: offer)
      create(:payment, :escrowed, shipment: shipment)

      barrier = Concurrent::CyclicBarrier.new(2) if defined?(Concurrent::CyclicBarrier)
      target_id = shipment.id

      threads = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            barrier&.wait
            described_class.call(
              shipment: Shipment.find(target_id),
              target_status: :in_transit,
              reason: "carrier_started_transit"
            )
          rescue described_class::ConflictError
            nil
          end
        end
      end

      threads.each(&:join)

      shipment.reload
      expect(shipment.status).to eq("in_transit")
      expect(shipment.tracking_events.where(kind: "status_change", to_status: "in_transit").count).to eq(1)
    end
  end
end
