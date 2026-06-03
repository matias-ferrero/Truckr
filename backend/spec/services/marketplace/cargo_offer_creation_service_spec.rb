# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketplace::CargoOfferCreationService do
  describe "#call" do
    let(:shipper)  { create(:shipper) }
    let(:carrier)  { create(:carrier) }
    let(:cargo) do
      create(:cargo, shipper: shipper, status: "open",
             pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
    end
    let(:window) do
      create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "open",
             available_from: 2.days.from_now, available_to: 10.days.from_now)
    end

    subject(:service) { described_class.new(cargo: cargo, window: window, estimated_km: "500") }

    it "creates a CargoOffer and transitions the window to pending_offer" do
      expect { service.call }.to change(CargoOffer, :count).by(1)
      expect(window.reload.status).to eq("pending_offer")
    end

    it "returns the created CargoOffer" do
      result = service.call
      expect(result).to be_a(CargoOffer)
      expect(result).to be_persisted
      expect(result.cargo).to eq(cargo)
      expect(result.transport_window).to eq(window)
    end

    it "raises ConflictError when the window is already taken" do
      window.update!(status: "pending_offer")

      expect { service.call }.to raise_error(described_class::ConflictError)
    end

    it "does not create an offer when the window is taken (rollback)" do
      window.update!(status: "pending_offer")

      expect { service.call rescue nil }.not_to change(CargoOffer, :count)
    end
  end
end
