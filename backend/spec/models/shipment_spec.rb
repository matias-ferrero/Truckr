require "rails_helper"

RSpec.describe Shipment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cargo_offer) }
    it { is_expected.to have_many(:tracking_events).dependent(:destroy) }
    it { is_expected.to have_one(:route).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:cargo_offer_id) }

    it "STATUSES contains the canonical 4 states" do
      expect(described_class::STATUSES).to eq(%w[pending_payment to_pick_up in_transit delivered])
    end

    it "rejects unknown status assignments via the enum" do
      expect { described_class.new(status: "totally_not_a_status") }
        .to raise_error(ArgumentError)
    end

    it "requires accepted_at when pending_payment" do
      s = build(:shipment, status: "pending_payment", accepted_at: nil)
      expect(s).not_to be_valid
      expect(s.errors[:accepted_at]).to be_present
    end
  end

  describe "ALLOWED_TRANSITIONS" do
    it "is frozen and contains the canonical map" do
      expect(described_class::ALLOWED_TRANSITIONS).to be_frozen
      expect(described_class::ALLOWED_TRANSITIONS).to eq(
        pending_payment: [ :to_pick_up ],
        to_pick_up:      [ :in_transit ],
        in_transit:      [ :delivered ],
        delivered:       []
      )
    end
  end

  describe "#transition_to! — permitted transitions" do
    permitted = [
      [ :pending_payment, :to_pick_up, {} ],
      [ :to_pick_up,      :in_transit, {} ],
      [ :in_transit,      :delivered,  {} ]
    ]

    permitted.each do |from, to, extra|
      it "transitions #{from} -> #{to}" do
        s = create(:shipment, from)
        expect { s.transition_to!(to, **extra) }.to change { s.reload.status.to_sym }.from(from).to(to)
      end

      it "emits a status_change tracking event for #{from} -> #{to}" do
        s = create(:shipment, from)
        expect { s.transition_to!(to, **extra) }.to change { s.tracking_events.count }.by(1)
        ev = s.tracking_events.order(:recorded_at).last
        expect(ev.kind).to eq("status_change")
        expect(ev.from_status).to eq(from.to_s)
        expect(ev.to_status).to eq(to.to_s)
      end
    end
  end

  describe "#transition_to! — rejected transitions" do
    rejected = [
      [ :delivered,       :in_transit ],
      [ :pending_payment, :delivered ],
      [ :to_pick_up,      :pending_payment ],
      [ :in_transit,      :to_pick_up ]
    ]

    rejected.each do |from, to|
      it "rejects #{from} -> #{to}" do
        s = create(:shipment, from)
        expect {
          s.transition_to!(to, reason: "n/a")
        }.to raise_error(Shipment::IllegalTransition)
        expect(s.reload.status.to_sym).to eq(from)
      end
    end
  end

  describe "#transition_to! — locking" do
    it "wraps the transition in a row lock" do
      s = create(:shipment, :pending_payment)
      expect(s).to receive(:with_lock).and_call_original
      s.transition_to!(:to_pick_up)
    end
  end

  describe "scopes" do
    let!(:pending_payment) { create(:shipment, :pending_payment) }
    let!(:to_pick_up)      { create(:shipment, :to_pick_up) }
    let!(:in_transit) { create(:shipment, :in_transit) }
    let!(:delivered)  { create(:shipment, :delivered) }

    it ".active includes only active shipment states" do
      expect(Shipment.active).to match_array([ pending_payment, to_pick_up, in_transit ])
    end

    it ".completed includes delivered shipments" do
      expect(Shipment.completed).to match_array([ delivered ])
    end

    it ".in_progress matches the active shipment queue" do
      expect(Shipment.in_progress).to match_array([ pending_payment, to_pick_up, in_transit ])
    end
  end

  describe "soft-delete" do
    it "hides discarded rows from the default scope" do
      s = create(:shipment, :delivered)
      s.discard!
      expect(Shipment.where(id: s.id)).to be_empty
      expect(Shipment.with_discarded.where(id: s.id)).to include(s)
    end
  end
end
