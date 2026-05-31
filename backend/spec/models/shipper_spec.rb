require "rails_helper"

RSpec.describe Shipper, type: :model do
  describe "validations" do
    subject { build(:shipper) }

    it { is_expected.to validate_uniqueness_of(:user_id) }
    it { is_expected.to validate_uniqueness_of(:tax_id).allow_blank.ignoring_case_sensitivity }

    it "accepts blank tax_id (multiple shippers can have null tax_id)" do
      create(:shipper, tax_id: nil)
      expect(build(:shipper, tax_id: nil)).to be_valid
    end

    it "rejects duplicate non-null tax_id" do
      create(:shipper, tax_id: "20000000009")
      expect(build(:shipper, tax_id: "20000000009")).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:cargos).dependent(:restrict_with_error) }
  end

  describe "ransack allowlists (ActiveAdmin)" do
    it "exposes the columns and associations ActiveAdmin needs" do
      expect(Shipper.ransackable_attributes).to include("company_name", "tax_id")
      expect(Shipper.ransackable_associations).to contain_exactly("user", "cargos")
    end
  end
end
