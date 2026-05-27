require "rails_helper"

RSpec.describe Shipment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cargo_offer) }
    it { is_expected.to have_many(:tracking_events).dependent(:destroy) }
    it { is_expected.to have_many(:payments).dependent(:restrict_with_error) }
    it { is_expected.to have_one(:route).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:cargo_offer_id) }

    it "STATUSES contains the canonical 5 states" do
      expect(described_class::STATUSES).to eq(%w[accepted pending_payment in_transit delivered cancelled])
    end

    it "rejects unknown status assignments via the enum" do
      expect { described_class.new(status: "totally_not_a_status") }
        .to raise_error(ArgumentError)
    end

    it "requires accepted_at when accepted" do
      s = build(:shipment, status: "accepted", accepted_at: nil)
      expect(s).not_to be_valid
      expect(s.errors[:accepted_at]).to be_present
    end

    it "requires cancelled_at when cancelled" do
      s = build(:shipment, :cancelled, cancelled_at: nil)
      expect(s).not_to be_valid
      expect(s.errors[:cancelled_at]).to be_present
    end
  end

  describe "defaults" do
    it "defaults new shipments to status accepted" do
      s = Shipment.new
      expect(s.status).to eq("accepted")
    end
  end

  describe "ALLOWED_TRANSITIONS" do
    it "is frozen and contains the canonical map" do
      expect(described_class::ALLOWED_TRANSITIONS).to be_frozen
      expect(described_class::ALLOWED_TRANSITIONS).to eq(
        accepted:        [ :pending_payment, :cancelled ],
        pending_payment: [ :in_transit, :cancelled ],
        in_transit:      [ :delivered, :cancelled ],
        delivered:       [],
        cancelled:       []
      )
    end
  end

  describe "#transition_to! — permitted transitions" do
    permitted = [
      [ :accepted,        :pending_payment ],
      [ :accepted,        :cancelled       ],
      [ :pending_payment, :in_transit      ],
      [ :pending_payment, :cancelled       ],
      [ :in_transit,      :delivered       ],
      [ :in_transit,      :cancelled       ]
    ]

    permitted.each do |from, to|
      it "transitions #{from} -> #{to}" do
        s = create(:shipment, from)
        create(:payment, :escrowed, shipment: s) if from == :accepted
        expect { s.transition_to!(to) }.to change { s.reload.status.to_sym }.from(from).to(to)
      end

      it "stamps the matching timestamp column for #{to}" do
        s = create(:shipment, from)
        create(:payment, :escrowed, shipment: s) if from == :accepted
        col = Shipment::STATUS_TIMESTAMP_COLUMNS[to]
        expect { s.transition_to!(to) }.to change { s.reload.public_send(col) }.from(nil)
      end

      it "emits a status_change tracking event for #{from} -> #{to}" do
        s = create(:shipment, from)
        create(:payment, :escrowed, shipment: s) if from == :accepted
        expect { s.transition_to!(to) }.to change { s.tracking_events.count }.by(1)
        ev = s.tracking_events.order(:recorded_at).last
        expect(ev.kind).to eq("status_change")
        expect(ev.from_status).to eq(from.to_s)
        expect(ev.to_status).to eq(to.to_s)
      end
    end
  end

  describe "#transition_to! — rejected transitions" do
    rejected = [
      [ :accepted,        :in_transit      ],
      [ :accepted,        :delivered       ],
      [ :pending_payment, :accepted        ],
      [ :pending_payment, :delivered       ],
      [ :in_transit,      :accepted        ],
      [ :in_transit,      :pending_payment ],
      [ :delivered,       :in_transit      ],
      [ :delivered,       :cancelled       ],
      [ :cancelled,       :in_transit      ]
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
      s = create(:shipment, :accepted)
      create(:payment, :escrowed, shipment: s)
      expect(s).to receive(:with_lock).and_call_original
      s.transition_to!(:pending_payment)
    end
  end

  describe "#transition_to! — payment interlock" do
    it "rejects accepted -> pending_payment when no escrowed payment exists" do
      s = create(:shipment, :accepted)

      expect {
        s.transition_to!(:pending_payment)
      }.to raise_error(Shipment::IllegalTransition, /without escrowed payment/)
      expect(s.reload.status).to eq("accepted")
    end
  end

  describe "scopes" do
    let!(:accepted)        { create(:shipment, :accepted) }
    let!(:pending_payment) { create(:shipment, :pending_payment) }
    let!(:in_transit)      { create(:shipment, :in_transit) }
    let!(:delivered)       { create(:shipment, :delivered) }
    let!(:cancelled)       { create(:shipment, :cancelled) }

    it ".active includes accepted + pending_payment + in_transit" do
      expect(Shipment.active).to match_array([ accepted, pending_payment, in_transit ])
    end

    it ".completed includes delivered shipments" do
      expect(Shipment.completed).to match_array([ delivered ])
    end

    it ".in_progress matches .active" do
      expect(Shipment.in_progress).to match_array([ accepted, pending_payment, in_transit ])
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
