# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vehicle, type: :model do
  describe "discard semantics (ADR-009)" do
    let(:vehicle) { create(:vehicle) }

    it "discards a vehicle with no commitments" do
      expect(vehicle.discard).to be true
      expect(vehicle.reload.discarded?).to be true
    end

    it "rejects discard when there are active transport windows" do
      create(:transport_window, vehicle: vehicle, active: true)
      expect(vehicle.discard).to be_falsey
      expect(vehicle.errors.details[:base].first[:error]).to eq(:has_active_windows)
    end

    it "rejects discard when there are pending commitments (cargo offers)" do
      cargo_offer = create(:cargo_offer, status: "pending")  # Pending (live) offer
      tw = cargo_offer.transport_window
      tw.update!(vehicle: vehicle, active: false)
      expect(vehicle.discard).to be_falsey
      expect(vehicle.errors.details[:base].first[:error]).to eq(:has_pending_commitments)
    end

    it "allows discard when cargo offer is accepted (controlled by shipment state)" do
      v = create(:vehicle)
      cargo_offer = create(:cargo_offer, status: "accepted")  # Accepted offer
      tw = cargo_offer.transport_window
      tw.update!(vehicle: v, active: false)  # Set to inactive
      # Create a shipment in a terminal state; accepted offer should not block
      create(:shipment, cargo_offer: cargo_offer, status: "delivered", delivered_at: 1.hour.ago)
      expect(v.discard).to be true
    end

    it "allows discard when cargo offer is rejected (terminal state)" do
      v = create(:vehicle)
      cargo_offer = create(:cargo_offer, status: "rejected")  # Rejected offer (terminal)
      tw = cargo_offer.transport_window
      tw.update!(vehicle: v, active: false)  # Set to inactive
      expect(v.discard).to be true
    end

    it "discard! raises Vehicle::NotDiscardable when guards fail" do
      create(:transport_window, vehicle: vehicle, active: true)
      expect { vehicle.discard! }.to raise_error(Vehicle::NotDiscardable)
    end

    it "default scope excludes discarded records" do
      id = vehicle.id
      vehicle.update!(discarded_at: Time.current)
      expect { Vehicle.find(id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(Vehicle.with_discarded.find(id)).to be_present
    end

    it "allows discard when shipments are in terminal states (delivered, cancelled)" do
      # Create a separate vehicle for this test to avoid plate conflicts
      v = create(:vehicle)
      cargo_offer = create(:cargo_offer, status: "expired")  # Terminal offer
      tw = cargo_offer.transport_window
      tw.update!(vehicle: v, active: false)  # Set to inactive
      create(:shipment, cargo_offer: cargo_offer, status: "delivered", delivered_at: 1.hour.ago)
      expect(v.discard).to be true
    end

    it "allows discard when shipments are pending_payment" do
      v = create(:vehicle)
      cargo_offer = create(:cargo_offer, status: "expired")  # Terminal offer
      tw = cargo_offer.transport_window
      tw.update!(vehicle: v, active: false)  # Set to inactive
      create(:shipment, cargo_offer: cargo_offer, status: "pending_payment", payment_received_at: Time.current)
      expect(v.discard).to be true
    end

    it "rejects discard when there is a shipment in accepted state" do
      v = create(:vehicle)
      cargo_offer = create(:cargo_offer, status: "expired")  # Terminal offer
      tw = cargo_offer.transport_window
      tw.update!(vehicle: v, active: false)
      create(:shipment, cargo_offer: cargo_offer, status: "accepted", accepted_at: Time.current)
      expect(v.discard).to be_falsey
      expect(v.errors.details[:base].first[:error]).to eq(:has_active_shipments)
    end

    it "rejects discard when there is a shipment in in_transit state" do
      v = create(:vehicle)
      cargo_offer = create(:cargo_offer, status: "expired")  # Terminal offer
      tw = cargo_offer.transport_window
      tw.update!(vehicle: v, active: false)
      create(:shipment, cargo_offer: cargo_offer, status: "in_transit", picked_up_at: Time.current)
      expect(v.discard).to be_falsey
      expect(v.errors.details[:base].first[:error]).to eq(:has_active_shipments)
    end
  end
end
require "rails_helper"

RSpec.describe Vehicle, type: :model do
  describe "validations" do
    subject { build(:vehicle) }

    it { is_expected.to validate_presence_of(:plate) }
    it { is_expected.to validate_uniqueness_of(:plate).case_insensitive }
    it { is_expected.to validate_length_of(:plate).is_at_least(6).is_at_most(8) }
    it { is_expected.to validate_numericality_of(:max_load_kg).is_greater_than(0) }
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
    it "destroys cleanly when no CargoOffer model is loaded" do
      vehicle = create(:vehicle)
      expect { vehicle.destroy }.to change(Vehicle, :count).by(-1)
    end
  end

  describe "ransack allowlists (ActiveAdmin)" do
    it "exposes the columns and associations ActiveAdmin needs" do
      expect(Vehicle.ransackable_attributes).to include("plate", "vehicle_type", "max_load_kg")
      expect(Vehicle.ransackable_associations).to contain_exactly("carrier", "transport_windows")
    end
  end

  describe "registration fields (REQ-BE-00009)" do
    it { is_expected.to validate_presence_of(:make) }
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_length_of(:make).is_at_most(64) }
    it { is_expected.to validate_length_of(:model).is_at_most(64) }

    it "rejects year before 1980" do
      expect(build(:vehicle, year: 1979)).not_to be_valid
    end

    it "rejects year more than one year ahead" do
      expect(build(:vehicle, year: Date.current.year + 2)).not_to be_valid
    end

    it "allows nil year" do
      expect(build(:vehicle, year: nil)).to be_valid
    end

    it "rejects non-positive dimensions" do
      expect(build(:vehicle, length_cm: 0)).not_to be_valid
      expect(build(:vehicle, width_cm: -10)).not_to be_valid
    end

    it "allows nil dimensions" do
      expect(build(:vehicle, length_cm: nil, width_cm: nil, height_cm: nil)).to be_valid
    end

    it "rejects malformed plates" do
      expect(build(:vehicle, plate: "with sp")).not_to be_valid
      expect(build(:vehicle, plate: "AB!@#1")).not_to be_valid
    end
  end

  describe "#compute_volume_cm3" do
    it "computes volume from dimensions on save" do
      v = create(:vehicle, length_cm: 600, width_cm: 200, height_cm: 250)
      expect(v.volume_cm3).to eq(600 * 200 * 250)
    end

    it "is nil when any dimension is missing" do
      v = create(:vehicle, length_cm: nil, width_cm: 200, height_cm: 250)
      expect(v.volume_cm3).to be_nil
    end
  end

  describe "photos (ActiveStorage)" do
    let(:carrier) { create(:carrier) }

    def png_blob
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("\x89PNG\r\n\x1a\n" + ("0" * 32)),
        filename: "photo.png",
        content_type: "image/png"
      )
    end

    it "accepts up to MAX_PHOTOS photos" do
      vehicle = build(:vehicle, carrier: carrier)
      Vehicle::MAX_PHOTOS.times { vehicle.photos.attach(png_blob.signed_id) }
      expect(vehicle).to be_valid
    end

    it "rejects more than MAX_PHOTOS photos" do
      vehicle = build(:vehicle, carrier: carrier)
      (Vehicle::MAX_PHOTOS + 1).times { vehicle.photos.attach(png_blob.signed_id) }
      expect(vehicle).not_to be_valid
      expect(vehicle.errors[:photos]).to include(/5 or fewer/)
    end

    it "rejects disallowed content types" do
      vehicle = build(:vehicle, carrier: carrier)
      bad = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("nope"), filename: "x.gif", content_type: "image/gif"
      )
      vehicle.photos.attach(bad.signed_id)
      expect(vehicle).not_to be_valid
      expect(vehicle.errors[:photos].join).to match(/invalid content type/)
    end
  end
end
