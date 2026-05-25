require "rails_helper"

RSpec.describe Cargo, type: :model do
  describe "factory" do
    it "builds a valid Cargo" do
      expect(build(:cargo)).to be_valid
    end

    it "supports the :cancelled trait" do
      expect(build(:cargo, :cancelled).status).to eq("cancelled")
    end
  end

  describe "validations" do
    subject { build(:cargo) }

    it { is_expected.to validate_presence_of(:pickup_address) }
    it { is_expected.to validate_presence_of(:delivery_address) }
    it { is_expected.to validate_presence_of(:pickup_zone) }
    it { is_expected.to validate_presence_of(:delivery_zone) }
    it { is_expected.to validate_presence_of(:cargo_description) }
    it { is_expected.to validate_presence_of(:pickup_window_start) }
    it { is_expected.to validate_presence_of(:pickup_window_end) }
    it { is_expected.to validate_length_of(:cargo_description).is_at_most(200) }
    it { is_expected.to validate_numericality_of(:weight_kg).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:volume_cm3).only_integer.is_greater_than(0).allow_nil }
    it { is_expected.to validate_numericality_of(:declared_value_cents).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Cargo::STATUSES) }

    it "accepts a nil volume_cm3" do
      expect(build(:cargo, volume_cm3: nil)).to be_valid
    end

    it "rejects a pickup_window_end at or before the start" do
      instant = 5.days.from_now
      cargo = build(:cargo, pickup_window_start: instant, pickup_window_end: instant)
      expect(cargo).not_to be_valid
      expect(cargo.errors[:pickup_window_end]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:shipper) }
    it { is_expected.to have_many(:cargo_offers).dependent(:destroy) }

    it "accepted_cargo_offer returns only the accepted bid" do
      cargo = create(:cargo)
      create(:cargo_offer, :pending, cargo: cargo)
      accepted = create(:cargo_offer, :accepted, cargo: cargo)
      expect(cargo.reload.accepted_cargo_offer).to eq(accepted)
    end
  end

  describe "zone normalization" do
    it "transliterates the zone fields on save" do
      cargo = create(:cargo, pickup_zone: "Córdoba", delivery_zone: "Tucumán")
      expect(cargo.pickup_zone_normalized).to eq("cordoba")
      expect(cargo.delivery_zone_normalized).to eq("tucuman")
    end
  end

  describe "#editable? / #cancellable?" do
    it "is true for an open cargo with no accepted offer" do
      cargo = create(:cargo)
      expect(cargo).to be_editable
      expect(cargo).to be_cancellable
    end

    it "is false once an accepted offer exists" do
      cargo = create(:cargo)
      create(:cargo_offer, :accepted, cargo: cargo)
      cargo.reload
      expect(cargo).not_to be_editable
      expect(cargo).not_to be_cancellable
    end

    it "is false once the cargo is no longer open" do
      cargo = create(:cargo, :cancelled)
      expect(cargo).not_to be_editable
      expect(cargo).not_to be_cancellable
    end
  end

  describe "constants" do
    it "freezes STATUSES" do
      expect(Cargo::STATUSES).to be_frozen
    end

    it "freezes ALLOWED_TRANSITIONS" do
      expect(Cargo::ALLOWED_TRANSITIONS).to be_frozen
    end
  end

  describe "#transition_to!" do
    it "allows open → accepted" do
      cargo = create(:cargo)
      cargo.transition_to!(:accepted)
      expect(cargo.reload.status).to eq("accepted")
    end

    it "allows open → cancelled and stamps cancelled_at + reason" do
      cargo = create(:cargo)
      cargo.transition_to!(:cancelled, reason: "Plans changed")
      cargo.reload
      expect(cargo.status).to eq("cancelled")
      expect(cargo.cancelled_at).to be_present
      expect(cargo.cancellation_reason).to eq("Plans changed")
    end

    it "expires pending cargo_offers when transitioning to cancelled" do
      cargo = create(:cargo)
      pending_offer = create(:cargo_offer, :pending, cargo: cargo)

      cargo.transition_to!(:cancelled)

      expect(pending_offer.reload.status).to eq("expired")
    end

    it "does not touch already-expired or cancelled cargo_offers on cancellation" do
      cargo = create(:cargo)
      expired_offer   = create(:cargo_offer, :expired,   cargo: cargo)
      cancelled_offer = create(:cargo_offer, :cancelled, cargo: cargo)

      cargo.transition_to!(:cancelled)

      expect(expired_offer.reload.status).to eq("expired")
      expect(cancelled_offer.reload.status).to eq("cancelled")
    end

    it "raises IllegalTransition out of the accepted terminal state" do
      cargo = create(:cargo, :accepted)
      expect { cargo.transition_to!(:cancelled) }.to raise_error(Cargo::IllegalTransition)
    end

    it "raises IllegalTransition out of the cancelled terminal state" do
      cargo = create(:cargo, :cancelled)
      expect { cargo.transition_to!(:accepted) }.to raise_error(Cargo::IllegalTransition)
    end

    it "IllegalTransition descends from StandardError" do
      expect(Cargo::IllegalTransition.ancestors).to include(StandardError)
    end
  end

  describe "#matching_windows" do
    let(:cargo) do
      create(:cargo,
             pickup_zone: "Buenos Aires", delivery_zone: "Córdoba", weight_kg: 1500,
             pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
    end
    let(:vehicle) { create(:vehicle, max_load_kg: 5000) }

    def make_window(overrides = {})
      create(:transport_window, {
        vehicle:           vehicle,
        origin_province:   "Buenos Aires",
        destination_province: "Córdoba",
        available_from:    2.days.from_now,
        available_to:      10.days.from_now
      }.merge(overrides))
    end

    it "returns windows whose zone, dates and capacity match" do
      win = make_window
      expect(cargo.matching_windows).to include(win)
    end

    it "excludes inactive windows" do
      win = make_window(active: false)
      expect(cargo.matching_windows).not_to include(win)
    end

    it "excludes windows with a pending contender" do
      win = make_window
      create(:cargo_offer, :pending, transport_window: win,
             cargo: create(:cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now))
      expect(cargo.matching_windows).not_to include(win)
    end

    it "excludes windows whose vehicle capacity is too small" do
      tiny = create(:vehicle, max_load_kg: 100)
      win  = make_window(vehicle: tiny)
      expect(cargo.matching_windows).not_to include(win)
    end

    it "excludes windows whose origin zone does not match" do
      win = make_window(origin_province: "Mendoza")
      expect(cargo.matching_windows).not_to include(win)
    end

    it "includes open-destination windows (destination_province nil)" do
      win = create(:transport_window, :open_destination,
                   vehicle: vehicle, origin_province: "Buenos Aires",
                   available_from: 2.days.from_now, available_to: 10.days.from_now)
      expect(cargo.matching_windows).to include(win)
    end
  end

  describe "scopes" do
    it ".with_status filters by status when present" do
      open_cargo      = create(:cargo)
      cancelled_cargo = create(:cargo, :cancelled)
      expect(Cargo.with_status("open")).to contain_exactly(open_cargo)
      expect(Cargo.with_status(nil)).to include(open_cargo, cancelled_cargo)
    end

    it ".for_shipper filters by shipper" do
      shipper = create(:shipper)
      mine    = create(:cargo, shipper: shipper)
      _other  = create(:cargo)
      expect(Cargo.for_shipper(shipper)).to contain_exactly(mine)
    end
  end
end
