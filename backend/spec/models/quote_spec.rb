require "rails_helper"

RSpec.describe Quote, type: :model do
  describe "factory" do
    it "builds a valid Quote" do
      expect(build(:quote)).to be_valid
    end

    Quote::STATES.each do |state|
      it "supports the :#{state} trait" do
        expect(build(:quote, state.to_sym).status).to eq(state)
      end
    end
  end

  describe "validations" do
    subject { build(:quote) }

    it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:currency).in_array(%w[ARS]) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Quote::STATES) }

    # `expires_at` is derived by a before_validation callback from the
    # transport_window's available_to (capped at 72h). The shoulda matcher
    # for presence can't see past the callback, so we test it directly.
    it "requires expires_at (and derives it from the transport_window)" do
      q = build(:quote, expires_at: nil)
      expect(q).to be_valid
      expect(q.expires_at).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:cargo_offer) }
    it { is_expected.to belong_to(:carrier) }
    it { is_expected.to belong_to(:transport_window) }
  end

  describe "constants" do
    it "freezes STATES" do
      expect(Quote::STATES).to be_frozen
    end

    it "freezes TERMINAL_STATES" do
      expect(Quote::TERMINAL_STATES).to be_frozen
      expect(Quote::TERMINAL_STATES).to contain_exactly("paid", "expired", "cancelled")
    end

    it "freezes ALLOWED_TRANSITIONS and matches the documented table" do
      expect(Quote::ALLOWED_TRANSITIONS).to be_frozen
      expect(Quote::ALLOWED_TRANSITIONS).to eq(
        "pending"   => %w[accepted expired cancelled],
        "accepted"  => %w[paid cancelled],
        "paid"      => [],
        "expired"   => [],
        "cancelled" => []
      )
    end
  end

  describe "scopes" do
    let!(:pending_q)   { create(:quote, :pending) }
    let!(:accepted_q)  { create(:quote, :accepted) }
    let!(:paid_q)      { create(:quote, :paid) }
    let!(:expired_q)   { create(:quote, :expired) }
    let!(:cancelled_q) { create(:quote, :cancelled) }

    it ".pending returns only status=pending" do
      expect(Quote.pending).to contain_exactly(pending_q)
    end

    it ".accepted returns only status=accepted" do
      expect(Quote.accepted).to contain_exactly(accepted_q)
    end

    it ".paid returns only status=paid" do
      expect(Quote.paid).to contain_exactly(paid_q)
    end

    it ".cancelled returns only status=cancelled" do
      expect(Quote.cancelled).to contain_exactly(cancelled_q)
    end

    it ".expired returns only status=expired" do
      expect(Quote.expired).to contain_exactly(expired_q)
    end

    it ".past_expiry returns rows whose expires_at has elapsed (regardless of status)" do
      stale = create(:quote, :pending, expires_at: 1.hour.ago)
      expect(Quote.past_expiry).to include(stale)
      expect(Quote.past_expiry).not_to include(pending_q)
    end
  end

  describe "#can_transition_to? — matrix-driven contract test" do
    Quote::STATES.product(Quote::STATES).each do |from, to|
      allowed = Quote::ALLOWED_TRANSITIONS.fetch(from).include?(to)

      it "returns #{allowed} for #{from} → #{to}" do
        quote = build(:quote, status: from)
        expect(quote.can_transition_to?(to)).to eq(allowed)
      end
    end

    it "accepts a Symbol argument" do
      quote = build(:quote, status: "pending")
      expect(quote.can_transition_to?(:accepted)).to be(true)
    end
  end

  describe "#transition_to!" do
    it "updates status on a legal transition" do
      quote = create(:quote, :pending)
      quote.transition_to!("accepted")
      expect(quote.reload.status).to eq("accepted")
    end

    it "accepts a Symbol argument" do
      quote = create(:quote, :pending)
      quote.transition_to!(:accepted)
      expect(quote.reload.status).to eq("accepted")
    end

    it "raises Quote::InvalidTransition on a disallowed transition" do
      quote = create(:quote, :paid)
      expect { quote.transition_to!("accepted") }.to raise_error(Quote::InvalidTransition)
    end

    it "Quote::InvalidTransition descends from StandardError (not RuntimeError)" do
      expect(Quote::InvalidTransition.ancestors).to include(StandardError)
    end

    Quote::TERMINAL_STATES.each do |terminal|
      it "rejects every transition out of terminal state #{terminal}" do
        quote = create(:quote, terminal.to_sym)
        Quote::STATES.each do |target|
          expect { quote.transition_to!(target) }.to raise_error(Quote::InvalidTransition)
        end
      end
    end
  end
end
