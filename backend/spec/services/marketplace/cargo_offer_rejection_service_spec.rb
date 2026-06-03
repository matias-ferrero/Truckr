# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketplace::CargoOfferRejectionService do
  describe "#call" do
    let(:shipper)  { create(:shipper) }
    let(:carrier)  { create(:carrier) }
    let(:cargo) do
      create(:cargo, shipper: shipper, status: "open",
             pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
    end
    let(:window) do
      create(:transport_window, vehicle: create(:vehicle, carrier: carrier), status: "pending_offer",
             available_from: 2.days.from_now, available_to: 10.days.from_now)
    end
    let(:offer) do
      create(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window,
             status: "pending", expires_at: 2.days.from_now)
    end

    subject(:service) { described_class.new(cargo_offer: offer) }

    it "transitions the offer to rejected and reverts the window to open" do
      service.call
      expect(offer.reload.status).to eq("rejected")
      expect(window.reload.status).to eq("open")
    end

    it "sets rejected_at on the offer" do
      now = Time.current
      allow(Time).to receive(:current).and_return(now)
      service.call
      expect(offer.reload.rejected_at).to be_within(1.second).of(now)
    end

    it "returns the cargo_offer" do
      result = service.call
      expect(result).to eq(offer)
    end

    context "when the offer is not pending" do
      before { offer.update!(status: "accepted") }

      it "raises ConflictError" do
        expect { service.call }.to raise_error(described_class::ConflictError)
      end

      it "does not change the window status" do
        expect { service.call rescue nil }.not_to change { window.reload.status }
      end
    end

    context "when the offer is expired" do
      before { offer.update!(expires_at: 1.day.ago) }

      it "raises ConflictError" do
        expect { service.call }.to raise_error(described_class::ConflictError)
      end
    end
  end
end
