# frozen_string_literal: true

require "rails_helper"

# US30 / [[REQ-BE-00044]] — race-safe Carrier→Shipper review creation.
RSpec.describe Reviews::Create do
  let(:carrier_user) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier) }
  let(:shipment)     { create(:shipment, :delivered, cargo_offer: offer) }

  def call(rating: 5, body: "Todo perfecto.")
    described_class.call(shipment: shipment, carrier: carrier, rating: rating, body: body)
  end

  describe ".call" do
    it "persists a carrier-authored Review derived from the shipment's parties" do
      review = call

      expect(review).to be_persisted
      expect(review.authored_by).to eq("carrier_authored")
      expect(review.carrier_id).to eq(carrier.id)
      expect(review.shipper_id).to eq(shipper.id)
      expect(review.shipment_id).to eq(shipment.id)
      expect(review.rating).to eq(5)
    end

    it "raises ConflictError(:shipment_not_delivered) when the Shipment is not delivered" do
      not_delivered = create(:shipment, :accepted, cargo_offer: offer)

      expect {
        described_class.call(shipment: not_delivered, carrier: carrier, rating: 5, body: nil)
      }.to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:shipment_not_delivered) }

      expect(Review.count).to eq(0)
    end

    it "raises ConflictError(:already_reviewed) when a carrier review already exists" do
      call
      expect { call }
        .to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:already_reviewed) }

      expect(Review.carrier_authored.where(shipment_id: shipment.id).count).to eq(1)
    end

    it "does not block a shipper review from coexisting with a carrier review" do
      call # carrier review
      shipper_review = Review.create!(
        shipment: shipment, carrier: carrier, shipper: shipper,
        rating: 4, body: nil, authored_by: :shipper_authored
      )

      expect(shipper_review).to be_persisted
      expect(Review.where(shipment_id: shipment.id).count).to eq(2)
    end

    it "propagates RecordInvalid for an out-of-range rating (→ 422 upstream)" do
      expect { call(rating: 0) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Review.count).to eq(0)
    end
  end
end
