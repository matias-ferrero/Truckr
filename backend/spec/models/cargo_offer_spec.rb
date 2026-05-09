require "rails_helper"

RSpec.describe CargoOffer, type: :model do
  describe "factory" do
    it "builds a valid CargoOffer" do
      expect(build(:cargo_offer)).to be_valid
    end
  end

  describe "validations" do
    subject { build(:cargo_offer) }

    it { is_expected.to validate_presence_of(:pickup_address) }
    it { is_expected.to validate_presence_of(:delivery_address) }
    it { is_expected.to validate_presence_of(:cargo_description) }
    it { is_expected.to validate_presence_of(:pickup_date) }
    it { is_expected.to validate_numericality_of(:weight_kg).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:volume_cm3).only_integer.is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:declared_value_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:shipper) }
    it { is_expected.to have_many(:quotes).dependent(:restrict_with_error) }
  end
end
