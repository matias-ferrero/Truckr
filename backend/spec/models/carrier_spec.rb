require "rails_helper"

RSpec.describe Carrier, type: :model do
  describe "validations" do
    subject { build(:carrier) }

    it { is_expected.to validate_uniqueness_of(:user_id) }
    it { is_expected.to validate_uniqueness_of(:tax_id).allow_blank }
    it { is_expected.to validate_numericality_of(:rating_avg).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(5) }
    it { is_expected.to validate_numericality_of(:completed_shipments).only_integer.is_greater_than_or_equal_to(0) }

    it "rejects rating_avg above 5" do
      expect(build(:carrier, rating_avg: 5.01)).not_to be_valid
    end

    it "accepts blank tax_id (multiple carriers can have null tax_id)" do
      create(:carrier, tax_id: nil)
      expect(build(:carrier, tax_id: nil)).to be_valid
    end

    it "rejects duplicate non-null tax_id" do
      create(:carrier, tax_id: "30000000001")
      expect(build(:carrier, tax_id: "30000000001")).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:vehicles).dependent(:destroy) }
    it { is_expected.to have_many(:transport_windows).through(:vehicles) }
    it { is_expected.to have_many(:quotes).dependent(:restrict_with_error) }
  end

  describe "defaults" do
    it "defaults rating_avg to 0.0 and completed_shipments to 0 from the schema" do
      carrier = Carrier.new(user: build(:user))
      expect(carrier.rating_avg).to eq(0.0)
      expect(carrier.completed_shipments).to eq(0)
    end
  end

  describe "cascading destroy" do
    it "destroys vehicles when the carrier is destroyed" do
      carrier = create(:carrier)
      create_list(:vehicle, 2, carrier: carrier)
      expect { carrier.destroy }.to change(Vehicle, :count).by(-2)
    end
  end

  describe "ransack allowlists (ActiveAdmin)" do
    it "exposes the columns and associations ActiveAdmin needs" do
      expect(Carrier.ransackable_attributes).to include("legal_name", "tax_id", "rating_avg")
      expect(Carrier.ransackable_associations).to contain_exactly("user", "vehicles", "transport_windows", "quotes")
    end
  end
end
