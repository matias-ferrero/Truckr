require "rails_helper"

RSpec.describe TransportWindow, type: :model do
  describe "factory" do
    it "builds a valid TransportWindow" do
      expect(build(:transport_window)).to be_valid
    end
  end

  describe "validations" do
    subject { build(:transport_window) }

    it { is_expected.to validate_presence_of(:origin_zone) }
    it { is_expected.to validate_presence_of(:destination_zone) }
    it { is_expected.to validate_presence_of(:available_from) }
    it { is_expected.to validate_presence_of(:available_to) }
    it { is_expected.to validate_numericality_of(:price_per_km).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:max_km).only_integer.is_greater_than(0) }

    it "rejects available_to <= available_from" do
      tw = build(:transport_window, available_from: 2.days.from_now, available_to: 1.day.from_now)
      expect(tw).not_to be_valid
      expect(tw.errors[:available_to]).to include("must be after available_from")
    end

    it "rejects available_to == available_from" do
      now = 1.day.from_now
      tw = build(:transport_window, available_from: now, available_to: now)
      expect(tw).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:vehicle) }
    it { is_expected.to have_many(:quotes).dependent(:restrict_with_error) }
  end

  describe "#carrier delegation" do
    it "returns the vehicle's carrier" do
      tw = create(:transport_window)
      expect(tw.carrier).to eq(tw.vehicle.carrier)
    end
  end

  describe "scope :active" do
    it "returns only active=true rows" do
      active   = create(:transport_window, active: true)
      inactive = create(:transport_window, active: false)
      expect(TransportWindow.active).to include(active)
      expect(TransportWindow.active).not_to include(inactive)
    end
  end

  describe "normalized search fields callback" do
    it "normalizes origin_zone and destination_zone on save" do
      tw = create(:transport_window, origin_zone: "Buenos Aires", destination_zone: "Córdoba")
      expect(tw.origin_zone_normalized).to eq("buenos aires")
      expect(tw.destination_zone_normalized).to eq("cordoba")
    end

    it "handles diacritics during normalization" do
      tw = create(:transport_window, origin_zone: "São Paulo", destination_zone: "Zürich")
      expect(tw.origin_zone_normalized).to eq("sao paulo")
      expect(tw.destination_zone_normalized).to eq("zurich")
    end
  end

  describe "#no_vehicle_overlap" do
    let(:vehicle) { create(:vehicle) }
    let!(:base) do
      create(:transport_window,
             vehicle: vehicle,
             available_from: Time.zone.parse("2026-06-01 08:00"),
             available_to:   Time.zone.parse("2026-06-10 18:00"))
    end

    it "rejects an identical interval on the same vehicle" do
      dup = build(:transport_window,
                  vehicle: vehicle,
                  available_from: base.available_from,
                  available_to:   base.available_to)
      expect(dup).not_to be_valid
      expect(dup.errors[:base]).to include(/overlapping/)
    end

    it "rejects a partially overlapping interval" do
      partial = build(:transport_window,
                      vehicle: vehicle,
                      available_from: Time.zone.parse("2026-06-08 00:00"),
                      available_to:   Time.zone.parse("2026-06-12 00:00"))
      expect(partial).not_to be_valid
    end

    it "allows an edge-touching interval (boundary equality, no overlap)" do
      touching = build(:transport_window,
                       vehicle: vehicle,
                       available_from: base.available_to,
                       available_to:   base.available_to + 5.days)
      expect(touching).to be_valid
    end

    it "allows a fully-disjoint interval" do
      disjoint = build(:transport_window,
                       vehicle: vehicle,
                       available_from: base.available_to + 1.day,
                       available_to:   base.available_to + 5.days)
      expect(disjoint).to be_valid
    end

    it "allows two windows on different vehicles with the same interval" do
      other_vehicle = create(:vehicle)
      twin = build(:transport_window,
                   vehicle: other_vehicle,
                   available_from: base.available_from,
                   available_to:   base.available_to)
      expect(twin).to be_valid
    end
  end
end
