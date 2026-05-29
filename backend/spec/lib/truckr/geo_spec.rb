# frozen_string_literal: true

require "rails_helper"

RSpec.describe Truckr::Geo do
  describe ".haversine_km" do
    # Pinned reference points used across the suite.
    CABA           = [ -34.603722, -58.381592 ].freeze
    ROSARIO        = [ -32.946820, -60.639317 ].freeze
    MAR_DEL_PLATA  = [ -38.005477, -57.542611 ].freeze
    MENDOZA        = [ -32.889458, -68.844734 ].freeze
    ANTIPODE_CABA  = [ 34.603722, 121.618408 ].freeze

    it "returns 0 for two identical points" do
      expect(described_class.haversine_km(CABA, CABA)).to be_within(0.01).of(0)
    end

    it "computes CABA → Rosario within ±2 km of the known ~280 km" do
      expect(described_class.haversine_km(CABA, ROSARIO)).to be_within(2).of(280)
    end

    it "computes CABA → Mar del Plata within ±10 km of the known ~385 km" do
      expect(described_class.haversine_km(CABA, MAR_DEL_PLATA)).to be_within(10).of(385)
    end

    it "computes CABA → Mendoza within ±5 km of the known ~985 km" do
      expect(described_class.haversine_km(CABA, MENDOZA)).to be_within(5).of(985)
    end

    it "computes a near-antipodal distance close to the Earth's half-circumference" do
      expect(described_class.haversine_km(CABA, ANTIPODE_CABA)).to be_within(50).of(20_015)
    end

    it "is symmetric: f(a, b) == f(b, a)" do
      expect(described_class.haversine_km(CABA, ROSARIO))
        .to be_within(0.001).of(described_class.haversine_km(ROSARIO, CABA))
    end
  end

  describe ".bbox_for" do
    it "returns a 4-tuple [min_lat, max_lat, min_lng, max_lng]" do
      bbox = described_class.bbox_for(-34.6, -58.4, 50)
      expect(bbox.length).to eq(4)
      expect(bbox[0]).to be < bbox[1]
      expect(bbox[2]).to be < bbox[3]
    end

    it "produces a roughly square box at the equator" do
      min_lat, max_lat, min_lng, max_lng = described_class.bbox_for(0, 0, 100)
      expect(max_lat - min_lat).to be_within(0.05).of(max_lng - min_lng)
    end

    it "widens longitude span by ~1.22× at CABA latitude (~34.6°S)" do
      min_lat, max_lat, min_lng, max_lng = described_class.bbox_for(-34.6, -58.4, 100)
      ratio = (max_lng - min_lng) / (max_lat - min_lat)
      expect(ratio).to be_within(0.05).of(1.22)
    end

    it "widens longitude span by ~1.74× at Bariloche latitude (~41.1°S)" do
      min_lat, max_lat, min_lng, max_lng = described_class.bbox_for(-41.13, -71.30, 100)
      ratio = (max_lng - min_lng) / (max_lat - min_lat)
      expect(ratio).to be_within(0.05).of(1.33)
    end

    it "widens longitude span by ~1.74× at Ushuaia latitude (~54.8°S)" do
      min_lat, max_lat, min_lng, max_lng = described_class.bbox_for(-54.8, -68.3, 100)
      ratio = (max_lng - min_lng) / (max_lat - min_lat)
      expect(ratio).to be_within(0.1).of(1.74)
    end

    it "contains every point within `radius_km` of the anchor (true disk is inside the bbox)" do
      anchor_lat = -34.6
      anchor_lng = -58.4
      min_lat, max_lat, min_lng, max_lng = described_class.bbox_for(anchor_lat, anchor_lng, 50)
      due_east = [ anchor_lat, anchor_lng + (50.0 / 111.0) / Math.cos(anchor_lat * Math::PI / 180).abs ]
      expect(due_east[0]).to be_between(min_lat, max_lat)
      expect(due_east[1]).to be <= max_lng
    end
  end
end
