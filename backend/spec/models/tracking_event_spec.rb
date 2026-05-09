require "rails_helper"

RSpec.describe TrackingEvent, type: :model do
  it { is_expected.to belong_to(:shipment) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }
  it { is_expected.to validate_presence_of(:recorded_at) }

  it "requires from_status / to_status on status_change" do
    e = build(:tracking_event, kind: "status_change", from_status: nil)
    expect(e).not_to be_valid
  end

  it "requires lat/lng on gps_update" do
    e = build(:tracking_event, :gps_update, lat: nil, lng: nil)
    expect(e).not_to be_valid
  end

  it "scopes .gps and .recent work" do
    s = create(:shipment, :in_transit)
    create(:tracking_event, :gps_update, shipment: s, recorded_at: 2.minutes.ago)
    create(:tracking_event, shipment: s, recorded_at: 1.minute.ago)
    expect(s.tracking_events.gps.count).to eq(1)
    expect(s.tracking_events.recent(10).first.recorded_at)
      .to be_within(1.second).of(1.minute.ago)
  end
end
