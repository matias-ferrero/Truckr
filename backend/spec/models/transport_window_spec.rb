require "rails_helper"

RSpec.describe TransportWindow, type: :model do
  describe "factory" do
    it "builds a valid TransportWindow" do
      expect(build(:transport_window)).to be_valid
    end

    it "builds a valid open-destination TransportWindow" do
      expect(build(:transport_window, :open_destination)).to be_valid
    end
  end

  describe "validations" do
    subject { build(:transport_window) }

    it { is_expected.to validate_presence_of(:origin_province) }
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
    it { is_expected.to have_many(:cargo_offers).dependent(:restrict_with_error) }
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
    it "normalizes origin_province and destination_province on save" do
      tw = create(:transport_window, origin_province: "Buenos Aires", destination_province: "Córdoba")
      expect(tw.origin_province_normalized).to eq("buenos aires")
      expect(tw.destination_province_normalized).to eq("cordoba")
    end

    it "normalizes origin_locality and destination_locality when present" do
      tw = create(:transport_window, origin_locality: "CABA", destination_locality: "Córdoba Capital")
      expect(tw.origin_locality_normalized).to eq("caba")
      expect(tw.destination_locality_normalized).to eq("cordoba capital")
    end

    it "handles diacritics during normalization" do
      tw = create(:transport_window, origin_province: "São Paulo", destination_province: "Zürich")
      expect(tw.origin_province_normalized).to eq("sao paulo")
      expect(tw.destination_province_normalized).to eq("zurich")
    end

    it "stores nil destination_province_normalized when destination_province is blank" do
      tw = create(:transport_window, :open_destination)
      expect(tw.destination_province).to be_nil
      expect(tw.destination_province_normalized).to be_nil
    end

    it "coerces empty string destination_province to nil" do
      tw = create(:transport_window, destination_province: "")
      expect(tw.destination_province).to be_nil
    end

    it "coerces empty string origin_locality to nil" do
      tw = create(:transport_window, origin_locality: "")
      expect(tw.origin_locality).to be_nil
    end
  end

  describe "#locality_requires_province" do
    it "rejects origin_locality without origin_province" do
      tw = build(:transport_window, origin_province: nil, origin_locality: "CABA")
      expect(tw).not_to be_valid
      expect(tw.errors[:origin_locality]).to include(/requiere que se especifique la provincia de origen/)
    end

    it "rejects destination_locality without destination_province" do
      tw = build(:transport_window, destination_province: nil, destination_locality: "Córdoba Capital")
      expect(tw).not_to be_valid
      expect(tw.errors[:destination_locality]).to include(/requiere que se especifique la provincia de destino/)
    end

    it "allows origin_locality when origin_province is present" do
      tw = build(:transport_window, origin_province: "Buenos Aires", origin_locality: "CABA")
      tw.valid?
      expect(tw.errors[:origin_locality]).to be_empty
    end

    it "allows destination_locality when destination_province is present" do
      tw = build(:transport_window, destination_province: "Córdoba", destination_locality: "Córdoba Capital")
      tw.valid?
      expect(tw.errors[:destination_locality]).to be_empty
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
