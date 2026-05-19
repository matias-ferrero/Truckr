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
    it { is_expected.to have_many(:cargo_offers).dependent(:restrict_with_error) }
  end

  describe "defaults" do
    it "defaults rating_avg to 0.0 and completed_shipments to 0 from the schema" do
      carrier = Carrier.new(user: build(:user))
      expect(carrier.rating_avg).to eq(0.0)
      expect(carrier.completed_shipments).to eq(0)
    end

    it "defaults reviews_count to 0" do
      carrier = Carrier.new(user: build(:user))
      expect(carrier.reviews_count).to eq(0)
    end
  end

  describe "#active_transport_windows" do
    it "returns only windows whose vehicle belongs to this carrier and which are active" do
      carrier = create(:carrier)
      vehicle = create(:vehicle, carrier: carrier)
      active_win = create(:transport_window, vehicle: vehicle, active: true,
                                             available_from: 1.day.from_now,
                                             available_to:   10.days.from_now)
      _inactive  = create(:transport_window, vehicle: vehicle, active: false,
                                             available_from: 30.days.from_now,
                                             available_to:   45.days.from_now)
      # Another carrier — should not leak.
      other_vehicle = create(:vehicle, carrier: create(:carrier))
      _other_win = create(:transport_window, vehicle: other_vehicle, active: true,
                                             available_from: 1.day.from_now,
                                             available_to:   10.days.from_now)

      expect(carrier.active_transport_windows).to contain_exactly(active_win)
    end
  end

  describe "validations (extended)" do
    it "rejects a description longer than 2000 characters" do
      expect(build(:carrier, description: "x" * 2_001)).not_to be_valid
    end

    it "accepts a blank description" do
      expect(build(:carrier, description: nil)).to be_valid
    end

    it "rejects a negative reviews_count" do
      expect(build(:carrier, reviews_count: -1)).not_to be_valid
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
      expect(Carrier.ransackable_associations).to contain_exactly("user", "vehicles", "transport_windows", "cargo_offers")
    end
  end
end
