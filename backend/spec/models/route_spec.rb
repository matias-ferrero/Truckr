require "rails_helper"

RSpec.describe Route, type: :model do
  it { is_expected.to belong_to(:shipment) }

  describe "uniqueness of shipment_id" do
    subject { build(:route, shipment: create(:shipment, :draft)) }
    it { is_expected.to validate_uniqueness_of(:shipment_id) }
  end

  it "is not calculated until polyline + calculated_at are set" do
    r = build(:route)
    expect(r.calculated?).to eq(false)
    r.polyline = "abc"
    r.calculated_at = Time.current
    expect(r.calculated?).to eq(true)
  end
end
