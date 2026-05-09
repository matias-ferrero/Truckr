require "rails_helper"

RSpec.describe Vehicle, type: :model do
  describe "validations" do
    subject { build(:vehicle) }

    it { is_expected.to validate_presence_of(:plate) }
    it { is_expected.to validate_uniqueness_of(:plate).case_insensitive }
    it { is_expected.to validate_length_of(:plate).is_at_least(6).is_at_most(8) }
    it { is_expected.to validate_numericality_of(:capacity_kg).only_integer.is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:vehicle_type).in_array(Vehicle::VEHICLE_TYPES) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:carrier) }
    it { is_expected.to have_many(:transport_windows).dependent(:destroy) }
  end

  describe "vehicle_type values" do
    Vehicle::VEHICLE_TYPES.each do |type|
      it "accepts vehicle_type=#{type}" do
        expect(build(:vehicle, vehicle_type: type)).to be_valid
      end
    end

    it "rejects an unknown vehicle_type" do
      expect(build(:vehicle, vehicle_type: "rocket")).not_to be_valid
    end
  end

  describe "carrier ↔ vehicle cardinality (1:N — supersedes REQ-BE-00010)" do
    it "allows multiple vehicles for the same carrier" do
      carrier = create(:carrier)
      v1 = create(:vehicle, carrier: carrier)
      v2 = create(:vehicle, carrier: carrier)
      expect(carrier.vehicles).to contain_exactly(v1, v2)
    end
  end

  describe "before_destroy guard (no live commitments)" do
    it "destroys cleanly when no Quote model is loaded" do
      vehicle = create(:vehicle)
      expect { vehicle.destroy }.to change(Vehicle, :count).by(-1)
    end
  end

  describe "ransack allowlists (ActiveAdmin)" do
    it "exposes the columns and associations ActiveAdmin needs" do
      expect(Vehicle.ransackable_attributes).to include("plate", "vehicle_type", "capacity_kg")
      expect(Vehicle.ransackable_associations).to contain_exactly("carrier", "transport_windows")
    end
  end
end
