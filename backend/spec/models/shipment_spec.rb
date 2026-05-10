require "rails_helper"

RSpec.describe Shipment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:quote) }
    it { is_expected.to have_many(:tracking_events).dependent(:destroy) }
    it { is_expected.to have_one(:route).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quote_id) }

    it "STATUSES contains the canonical 7 states" do
      expect(described_class::STATUSES).to eq(%w[draft quoted accepted in_transit delivered settled cancelled])
    end

    it "rejects unknown status assignments via the enum" do
      expect { described_class.new(status: "totally_not_a_status") }
        .to raise_error(ArgumentError)
    end

    it "requires cancellation_reason when cancelled" do
      s = create(:shipment, :quoted)
      expect { s.transition_to!(:cancelled) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "ALLOWED_TRANSITIONS" do
    it "is frozen and contains the canonical map" do
      expect(described_class::ALLOWED_TRANSITIONS).to be_frozen
      expect(described_class::ALLOWED_TRANSITIONS).to eq(
        draft:      [ :quoted ],
        quoted:     [ :accepted, :cancelled ],
        accepted:   [ :in_transit, :cancelled ],
        in_transit: [ :delivered, :cancelled ],
        delivered:  [ :settled ],
        settled:    [],
        cancelled:  []
      )
    end
  end

  describe "#transition_to! — permitted transitions" do
    permitted = [
      [ :draft,      :quoted,     {} ],
      [ :quoted,     :accepted,   {} ],
      [ :quoted,     :cancelled,  { reason: "buyer changed mind" } ],
      [ :accepted,   :in_transit, {} ],
      [ :accepted,   :cancelled,  { reason: "carrier no-show" } ],
      [ :in_transit, :delivered,  {} ],
      [ :in_transit, :cancelled,  { reason: "vehicle failure" } ],
      [ :delivered,  :settled,    {} ]
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
      [ :delivered,  :in_transit ],
      [ :settled,    :in_transit ],
      [ :cancelled,  :quoted ],
      [ :draft,      :delivered ],
      [ :delivered,  :cancelled ] # explicit: no rollback after delivery
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
      s = create(:shipment, :quoted)
      expect(s).to receive(:with_lock).and_call_original
      s.transition_to!(:accepted)
    end
  end

  describe "scopes" do
    let!(:draft)      { create(:shipment, :draft) }
    let!(:in_transit) { create(:shipment, :in_transit) }
    let!(:settled)    { create(:shipment, :settled) }
    let!(:cancelled)  { create(:shipment, :cancelled) }

    it ".active excludes settled and cancelled" do
      expect(Shipment.active).to match_array([ draft, in_transit ])
    end

    it ".completed includes settled and cancelled" do
      expect(Shipment.completed).to match_array([ settled, cancelled ])
    end

    it ".in_progress matches accepted/in_transit only" do
      expect(Shipment.in_progress).to match_array([ in_transit ])
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
