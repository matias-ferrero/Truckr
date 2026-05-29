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

    it { is_expected.to validate_presence_of(:origin_address) }
    it { is_expected.to validate_presence_of(:origin_locality) }
    it { is_expected.to validate_presence_of(:origin_admin_area) }
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

  describe "#open_destination_consistency" do
    it "allows the all-NULL destination block (destino abierto)" do
      tw = build(:transport_window, :open_destination)
      expect(tw).to be_valid
    end

    it "allows the all-set destination block" do
      tw = build(:transport_window)
      expect(tw.destination_lat).not_to be_nil
      expect(tw).to be_valid
    end

    it "rejects a partial state with destination_lat set but dropoff_radius_km nil" do
      tw = build(:transport_window, dropoff_radius_km: nil)
      expect(tw).not_to be_valid
      expect(tw.errors[:base]).to include(/destino/i)
    end

    it "rejects a partial state with destination_address nil but coords + radius set" do
      tw = build(:transport_window, destination_address: nil)
      expect(tw).not_to be_valid
      expect(tw.errors[:base]).to be_present
    end

    it "rejects a partial state with destination_locality nil" do
      tw = build(:transport_window, destination_locality: nil)
      expect(tw).not_to be_valid
      expect(tw.errors[:base]).to be_present
    end

    it "rejects a partial state with destination_admin_area nil" do
      tw = build(:transport_window, destination_admin_area: nil)
      expect(tw).not_to be_valid
      expect(tw.errors[:base]).to be_present
    end
  end

  describe "coordinate validations" do
    it "requires origin_lat and origin_lng" do
      tw = build(:transport_window, origin_lat: nil, origin_lng: nil)
      expect(tw).not_to be_valid
      expect(tw.errors[:origin_lat]).to be_present
      expect(tw.errors[:origin_lng]).to be_present
    end

    it "rejects origin_lat outside the valid range" do
      expect(build(:transport_window, origin_lat: -91)).not_to be_valid
      expect(build(:transport_window, origin_lat:  91)).not_to be_valid
    end

    it "rejects origin_lng outside the valid range" do
      expect(build(:transport_window, origin_lng: -181)).not_to be_valid
      expect(build(:transport_window, origin_lng:  181)).not_to be_valid
    end

    it "allows destination_lat and destination_lng to be nil" do
      tw = build(:transport_window, :open_destination)
      expect(tw).to be_valid
    end

    it "rejects destination_lat outside the valid range when present" do
      expect(build(:transport_window, destination_lat: 91)).not_to be_valid
    end

    it "rejects destination_lng outside the valid range when present" do
      expect(build(:transport_window, destination_lng: -181)).not_to be_valid
    end

    it "accepts boundary values (-90, 90, -180, 180)" do
      tw = build(:transport_window,
                 origin_lat: -90,  origin_lng: -180,
                 destination_lat: 90, destination_lng: 180)
      expect(tw).to be_valid
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

  describe "pickup_radius_km validations" do
    it "requires pickup_radius_km" do
      tw = build(:transport_window, pickup_radius_km: nil)
      expect(tw).not_to be_valid
      expect(tw.errors[:pickup_radius_km]).to be_present
    end

    it "rejects values below the minimum (1)" do
      expect(build(:transport_window, pickup_radius_km: 0)).not_to be_valid
      expect(build(:transport_window, pickup_radius_km: -10)).not_to be_valid
    end

    it "rejects values above the maximum (200)" do
      expect(build(:transport_window, pickup_radius_km: 201)).not_to be_valid
    end

    it "rejects non-integer values" do
      expect(build(:transport_window, pickup_radius_km: 12.5)).not_to be_valid
      expect(build(:transport_window, pickup_radius_km: "abc")).not_to be_valid
    end

    it "accepts boundary values (1 and 200)" do
      expect(build(:transport_window, pickup_radius_km: 1)).to be_valid
      expect(build(:transport_window, pickup_radius_km: 200)).to be_valid
    end
  end

  describe "dropoff_radius_km validations" do
    it "allows nil iff the destination block is open" do
      tw = build(:transport_window, :open_destination)
      expect(tw).to be_valid
    end

    it "rejects values below the minimum (1) when present" do
      expect(build(:transport_window, dropoff_radius_km: 0)).not_to be_valid
    end

    it "rejects values above the maximum (200) when present" do
      expect(build(:transport_window, dropoff_radius_km: 201)).not_to be_valid
    end

    it "accepts boundary values (1 and 200)" do
      expect(build(:transport_window, dropoff_radius_km: 1)).to be_valid
      expect(build(:transport_window, dropoff_radius_km: 200)).to be_valid
    end
  end

  describe "scope :within_bbox_of" do
    let(:vehicle) { create(:vehicle) }

    it "includes a window whose origin pin sits inside the bbox" do
      win = create(:transport_window, vehicle: vehicle,
                                       origin_lat: -34.603722, origin_lng: -58.381592)
      expect(TransportWindow.within_bbox_of(-34.603722, -58.381592, 50)).to include(win)
    end

    it "excludes a window whose origin pin is far outside the bbox" do
      win = create(:transport_window, vehicle: vehicle,
                                       origin_lat: -24.7821, origin_lng: -65.4232,
                                       available_from: 30.days.from_now, available_to: 40.days.from_now)
      expect(TransportWindow.within_bbox_of(-34.603722, -58.381592, 50)).not_to include(win)
    end
  end

  describe "scope :within_pickup_radius_of" do
    let(:cargo) { create(:cargo, pickup_lat: -34.603722, pickup_lng: -58.381592) }
    let(:vehicle) { create(:vehicle) }

    it "includes a window whose origin coincides with the cargo pickup" do
      win = create(:transport_window, vehicle: vehicle,
                                       origin_lat: -34.603722, origin_lng: -58.381592,
                                       pickup_radius_km: 5)
      expect(TransportWindow.within_pickup_radius_of(cargo)).to include(win)
    end

    it "excludes a Salta-origin window with a 50 km radius (too far from CABA)" do
      win = create(:transport_window, vehicle: vehicle,
                                       origin_lat: -24.7821, origin_lng: -65.4232,
                                       pickup_radius_km: 50,
                                       available_from: 30.days.from_now,
                                       available_to:   40.days.from_now)
      expect(TransportWindow.within_pickup_radius_of(cargo)).not_to include(win)
    end

    it "returns an ActiveRecord::Relation so the callsite can still chain" do
      create(:transport_window, vehicle: vehicle,
                                 origin_lat: -34.603722, origin_lng: -58.381592)
      relation = TransportWindow.within_pickup_radius_of(cargo)
      expect(relation).to be_a(ActiveRecord::Relation)
      expect(relation.limit(1).to_a.size).to be <= 1
    end

    it "composes with another scope without losing relation shape" do
      _included = create(:transport_window, vehicle: vehicle,
                                             origin_lat: -34.603722, origin_lng: -58.381592,
                                             active: true)
      _excluded = create(:transport_window, vehicle: create(:vehicle),
                                             origin_lat: -34.603722, origin_lng: -58.381592,
                                             active: false)
      relation = TransportWindow.active.within_pickup_radius_of(cargo)
      expect(relation.where(active: false)).to be_empty
    end
  end

  describe "scope :within_dropoff_radius_of" do
    let(:cargo) { create(:cargo, delivery_lat: -31.420083, delivery_lng: -64.188776) } # Córdoba
    let(:vehicle) { create(:vehicle) }

    it "includes an open-destination window regardless of cargo delivery" do
      win = create(:transport_window, :open_destination, vehicle: vehicle)
      expect(TransportWindow.within_dropoff_radius_of(cargo)).to include(win)
    end

    it "includes a window whose destination coincides with the cargo delivery" do
      win = create(:transport_window, vehicle: vehicle,
                                       destination_lat: -31.420083, destination_lng: -64.188776,
                                       dropoff_radius_km: 5)
      expect(TransportWindow.within_dropoff_radius_of(cargo)).to include(win)
    end

    it "excludes a bounded-destination window whose pin is far from the cargo delivery" do
      win = create(:transport_window, vehicle: vehicle,
                                       destination_lat: -38.005477, destination_lng: -57.542611, # Mar del Plata
                                       dropoff_radius_km: 20,
                                       available_from: 30.days.from_now, available_to: 40.days.from_now)
      expect(TransportWindow.within_dropoff_radius_of(cargo)).not_to include(win)
    end
  end

  describe "scope :order_by_distance_to" do
    let(:cargo) { create(:cargo, pickup_lat: -34.603722, pickup_lng: -58.381592) }

    it "returns windows ordered by ascending distance from the cargo pickup" do
      near = create(:transport_window, vehicle: create(:vehicle),
                                        origin_lat: -34.603722, origin_lng: -58.381592)
      mid  = create(:transport_window, vehicle: create(:vehicle),
                                        origin_lat: -32.946820, origin_lng: -60.639317)
      far  = create(:transport_window, vehicle: create(:vehicle),
                                        origin_lat: -32.889458, origin_lng: -68.844734)
      ids = TransportWindow.order_by_distance_to(cargo).pluck(:id)
      expect(ids).to eq([ near.id, mid.id, far.id ])
    end

    it "returns an empty relation when there are no candidates" do
      expect(TransportWindow.none.order_by_distance_to(cargo)).to be_empty
    end
  end
end
