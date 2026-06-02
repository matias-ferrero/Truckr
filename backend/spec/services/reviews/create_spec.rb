# frozen_string_literal: true

require "rails_helper"

# US20 / US30 — race-safe review creation (both directions).
RSpec.describe Reviews::Create do
  let(:carrier_user) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier) }
  let(:shipment)     { create(:shipment, :delivered, cargo_offer: offer) }

  describe ".call (carrier-authored — US30)" do
    def call(rating: 5, body: "Todo perfecto.")
      described_class.call(
        shipment: shipment, authored_by: :carrier_authored,
        carrier: carrier, rating: rating, body: body
      )
    end

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
        described_class.call(
          shipment: not_delivered, authored_by: :carrier_authored,
          carrier: carrier, rating: 5, body: nil
        )
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
      call
      shipper_review = described_class.call(
        shipment: shipment, authored_by: :shipper_authored,
        shipper: shipper, rating: 4, body: nil
      )

      expect(shipper_review).to be_persisted
      expect(Review.where(shipment_id: shipment.id).count).to eq(2)
    end

    it "propagates RecordInvalid for an out-of-range rating (→ 422 upstream)" do
      expect { call(rating: 0) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Review.count).to eq(0)
    end
  end

  describe ".call (shipper-authored — US20)" do
    def call(rating: 5, body: "Todo perfecto.")
      described_class.call(
        shipment: shipment, authored_by: :shipper_authored,
        shipper: shipper, rating: rating, body: body
      )
    end

    it "persists a shipper-authored Review derived from the shipment's parties" do
      review = call

      expect(review).to be_persisted
      expect(review.authored_by).to eq("shipper_authored")
      expect(review.shipper_id).to eq(shipper.id)
      expect(review.carrier_id).to eq(carrier.id)
      expect(review.shipment_id).to eq(shipment.id)
      expect(review.rating).to eq(5)
    end

    it "raises ConflictError(:shipment_not_delivered) when the Shipment is not delivered" do
      not_delivered = create(:shipment, :accepted, cargo_offer: offer)

      expect {
        described_class.call(
          shipment: not_delivered, authored_by: :shipper_authored,
          shipper: shipper, rating: 5, body: nil
        )
      }.to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:shipment_not_delivered) }

      expect(Review.count).to eq(0)
    end

    it "raises ConflictError(:already_reviewed) when a shipper review already exists" do
      call
      expect { call }
        .to raise_error(described_class::ConflictError) { |e| expect(e.reason).to eq(:already_reviewed) }

      expect(Review.shipper_authored.where(shipment_id: shipment.id).count).to eq(1)
    end

    it "does not block a carrier review from coexisting with a shipper review" do
      call
      carrier_review = described_class.call(
        shipment: shipment, authored_by: :carrier_authored,
        carrier: carrier, rating: 4, body: nil
      )

      expect(carrier_review).to be_persisted
      expect(Review.where(shipment_id: shipment.id).count).to eq(2)
    end

    it "propagates RecordInvalid for an out-of-range rating (→ 422 upstream)" do
      expect { call(rating: 0) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Review.count).to eq(0)
    end
  end

  describe ".call argument validation" do
    it "raises ArgumentError when shipper is missing for shipper-authored reviews" do
      expect {
        described_class.call(
          shipment: shipment, authored_by: :shipper_authored,
          shipper: nil, rating: 5, body: nil
        )
      }.to raise_error(ArgumentError, "shipper is required for shipper_authored")
    end

    it "raises ArgumentError when carrier is missing for carrier-authored reviews" do
      expect {
        described_class.call(
          shipment: shipment, authored_by: :carrier_authored,
          carrier: nil, rating: 5, body: nil
        )
      }.to raise_error(ArgumentError, "carrier is required for carrier_authored")
    end
  end
end
