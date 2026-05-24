require "rails_helper"

RSpec.describe CargoOffer, type: :model do
  describe "factory" do
    it "builds a valid CargoOffer" do
      expect(build(:cargo_offer)).to be_valid
    end

    CargoOffer::STATES.each do |state|
      it "supports the :#{state} trait" do
        expect(build(:cargo_offer, state.to_sym).status).to eq(state)
      end
    end
  end

  describe "validations" do
    subject { build(:cargo_offer) }

    it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:currency).in_array(%w[ARS]) }
    it { is_expected.to validate_inclusion_of(:status).in_array(CargoOffer::STATES) }

    # `expires_at` is derived by a before_validation callback from the
    # transport_window's available_to (capped at 72h). The shoulda matcher
    # for presence can't see past the callback, so we test it directly.
    it "requires expires_at (and derives it from the transport_window)" do
      co = build(:cargo_offer, expires_at: nil)
      expect(co).to be_valid
      expect(co.expires_at).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:cargo) }
    it { is_expected.to belong_to(:carrier) }
    it { is_expected.to belong_to(:transport_window) }
  end

  describe "constants" do
    it "freezes STATES" do
      expect(CargoOffer::STATES).to be_frozen
    end

    it "freezes TERMINAL_STATES" do
      expect(CargoOffer::TERMINAL_STATES).to be_frozen
      expect(CargoOffer::TERMINAL_STATES).to contain_exactly("paid", "rejected", "expired", "cancelled")
    end

    it "freezes ALLOWED_TRANSITIONS and matches the documented table" do
      expect(CargoOffer::ALLOWED_TRANSITIONS).to be_frozen
      expect(CargoOffer::ALLOWED_TRANSITIONS).to eq(
        "pending"   => %w[accepted expired rejected cancelled],
        "accepted"  => %w[paid cancelled],
        "paid"      => [],
        "rejected"  => [],
        "expired"   => [],
        "cancelled" => []
      )
    end
  end

  describe "scopes" do
    let!(:pending_co)   { create(:cargo_offer, :pending) }
    let!(:accepted_co)  { create(:cargo_offer, :accepted) }
    let!(:paid_co)      { create(:cargo_offer, :paid) }
    let!(:rejected_co)  { create(:cargo_offer, :rejected) }
    let!(:expired_co)   { create(:cargo_offer, :expired) }
    let!(:cancelled_co) { create(:cargo_offer, :cancelled) }

    it ".pending returns only status=pending" do
      expect(CargoOffer.pending).to contain_exactly(pending_co)
    end

    it ".accepted returns only status=accepted" do
      expect(CargoOffer.accepted).to contain_exactly(accepted_co)
    end

    it ".paid returns only status=paid" do
      expect(CargoOffer.paid).to contain_exactly(paid_co)
    end

    it ".cancelled returns only status=cancelled" do
      expect(CargoOffer.cancelled).to contain_exactly(cancelled_co)
    end

    it ".rejected returns only status=rejected" do
      expect(CargoOffer.rejected).to contain_exactly(rejected_co)
    end

    it ".expired returns only status=expired" do
      expect(CargoOffer.expired).to contain_exactly(expired_co)
    end

    it ".past_expiry returns rows whose expires_at has elapsed (regardless of status)" do
      stale = create(:cargo_offer, :pending, expires_at: 1.hour.ago)
      expect(CargoOffer.past_expiry).to include(stale)
      expect(CargoOffer.past_expiry).not_to include(pending_co)
    end
  end

  describe "#can_transition_to? — matrix-driven contract test" do
    CargoOffer::STATES.product(CargoOffer::STATES).each do |from, to|
      allowed = CargoOffer::ALLOWED_TRANSITIONS.fetch(from).include?(to)

      it "returns #{allowed} for #{from} → #{to}" do
        cargo_offer = build(:cargo_offer, status: from)
        expect(cargo_offer.can_transition_to?(to)).to eq(allowed)
      end
    end

    it "accepts a Symbol argument" do
      cargo_offer = build(:cargo_offer, status: "pending")
      expect(cargo_offer.can_transition_to?(:accepted)).to be(true)
    end
  end

  describe "cross-record validations" do
    let(:carrier) { create(:carrier) }
    let(:vehicle) { create(:vehicle, carrier: carrier, max_load_kg: 5000) }
    let(:window) do
      create(:transport_window, vehicle: vehicle,
             available_from: 2.days.from_now, available_to: 10.days.from_now)
    end

    describe "pickup_window_overlaps_transport_window" do
      it "is valid when the cargo's pickup window overlaps the transport window" do
        cargo = create(:cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
        offer = build(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window)
        expect(offer).to be_valid
      end

      it "is invalid when the cargo's pickup window is entirely after the transport window" do
        cargo = create(:cargo, pickup_window_start: 20.days.from_now, pickup_window_end: 22.days.from_now)
        offer = build(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window)
        expect(offer).not_to be_valid
        expect(offer.errors[:pickup_window]).to be_present
      end
    end

    describe "within_vehicle_capacity" do
      it "tolerates a nil cargo volume_cm3" do
        cargo = create(:cargo, volume_cm3: nil, weight_kg: 1000,
                       pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
        offer = build(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window)
        expect(offer).to be_valid
      end

      it "rejects a cargo heavier than the vehicle's max load" do
        cargo = create(:cargo, weight_kg: 9999,
                       pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
        offer = build(:cargo_offer, cargo: cargo, carrier: carrier, transport_window: window)
        expect(offer).not_to be_valid
        expect(offer.errors[:weight_kg]).to be_present
      end
    end

    describe "transport_window_not_already_taken (window-lock)" do
      it "rejects a second offer against an already-contended window" do
        create(:cargo_offer, :pending, carrier: carrier, transport_window: window,
               cargo: create(:cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now))
        second = build(:cargo_offer, carrier: carrier, transport_window: window,
                       cargo: create(:cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now))
        expect(second).not_to be_valid
        expect(second.errors[:transport_window]).to be_present
      end

      it "allows an offer when the window's prior offers are all expired/cancelled" do
        prior = create(:cargo_offer, :pending, carrier: carrier, transport_window: window,
               cargo: create(:cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now))
        prior.transition_to!(:expired)
        second = build(:cargo_offer, carrier: carrier, transport_window: window,
                       cargo: create(:cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now))
        expect(second).to be_valid
      end
    end
  end

  describe "#transition_to!" do
    it "updates status on a legal transition" do
      cargo_offer = create(:cargo_offer, :pending)
      cargo_offer.transition_to!("accepted")
      expect(cargo_offer.reload.status).to eq("accepted")
    end

    it "accepts a Symbol argument" do
      cargo_offer = create(:cargo_offer, :pending)
      cargo_offer.transition_to!(:accepted)
      expect(cargo_offer.reload.status).to eq("accepted")
    end

    it "raises CargoOffer::InvalidTransition on a disallowed transition" do
      cargo_offer = create(:cargo_offer, :paid)
      expect { cargo_offer.transition_to!("accepted") }.to raise_error(CargoOffer::InvalidTransition)
    end

    it "CargoOffer::InvalidTransition descends from StandardError (not RuntimeError)" do
      expect(CargoOffer::InvalidTransition.ancestors).to include(StandardError)
    end

    CargoOffer::TERMINAL_STATES.each do |terminal|
      it "rejects every transition out of terminal state #{terminal}" do
        cargo_offer = create(:cargo_offer, terminal.to_sym)
        CargoOffer::STATES.each do |target|
          expect { cargo_offer.transition_to!(target) }.to raise_error(CargoOffer::InvalidTransition)
        end
      end
    end
  end
end
