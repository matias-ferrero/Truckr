# frozen_string_literal: true

require "rails_helper"

# US30 ([[REQ-BE-00044]]) — Review model. These specs lock the data invariants
# the Carrier review guard (Reviews::Create) relies on.
RSpec.describe Review, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shipment) }
    it { is_expected.to belong_to(:shipper) }
    it { is_expected.to belong_to(:carrier) }
  end

  describe "validations" do
    subject { build(:review) }

    it { is_expected.to validate_presence_of(:rating) }

    it "accepts ratings within 1..5" do
      (1..5).each { |r| expect(build(:review, rating: r)).to be_valid }
    end

    it "rejects ratings outside 1..5" do
      expect(build(:review, rating: 0)).not_to be_valid
      expect(build(:review, rating: 6)).not_to be_valid
    end

    it "allows a nil body" do
      expect(build(:review, body: nil)).to be_valid
    end

    it "rejects a body longer than 1000 characters" do
      expect(build(:review, body: "x" * 1_001)).not_to be_valid
      expect(build(:review, body: "x" * 1_000)).to be_valid
    end

    it "enforces one review per (shipment, authored_by) direction" do
      existing = create(:review, :carrier_authored)
      dup = build(:review, :carrier_authored,
                  shipment: existing.shipment,
                  shipper:  existing.shipper,
                  carrier:  existing.carrier)

      expect(dup).not_to be_valid
      expect(dup.errors[:shipment_id]).to be_present
    end

    it "allows both directions to coexist for the same shipment" do
      shipper_review = create(:review, :shipper_authored)

      carrier_review = build(:review, :carrier_authored,
                             shipment: shipper_review.shipment,
                             shipper:  shipper_review.shipper,
                             carrier:  shipper_review.carrier)

      expect(carrier_review).to be_valid
    end
  end

  describe "authored_by enum" do
    it "exposes both directions" do
      expect(described_class.authored_bies.keys).to contain_exactly("shipper_authored", "carrier_authored")
    end

    it "maps to the persisted string values" do
      expect(build(:review, :shipper_authored).authored_by).to eq("shipper_authored")
      expect(build(:review, :carrier_authored).authored_by).to eq("carrier_authored")
    end

    it "rejects unknown authorship via the enum" do
      expect { described_class.new(authored_by: "system") }.to raise_error(ArgumentError)
    end
  end
end
