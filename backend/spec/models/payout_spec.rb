# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payout, type: :model do
  subject(:payout) { build(:payout) }

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:gross_amount_cents) }
    it { is_expected.to validate_presence_of(:commission_rate) }
    it { is_expected.to validate_presence_of(:commission_cents) }
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_numericality_of(:gross_amount_cents).only_integer.is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
    it do
      is_expected.to define_enum_for(:state)
        .with_values("paid" => "paid", "failed" => "failed")
        .backed_by_column_of_type(:string)
        .with_prefix(true)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:shipment) }
    it { is_expected.to belong_to(:payment) }
  end

  describe "immutability" do
    let!(:saved_payout) { create(:payout) }

    it "raises ReadOnlyRecord when mutating an immutable field" do
      expect { saved_payout.update!(amount_cents: 999) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "does not raise when mutating discarded_at (soft-delete)" do
      expect { saved_payout.update!(discarded_at: Time.current) }
        .not_to raise_error
    end
  end

  describe "soft-delete" do
    let!(:payout) { create(:payout) }

    it "is included in the default scope" do
      expect(Payout.all).to include(payout)
    end

    it "is excluded from the default scope after discard!" do
      payout.discard!
      expect(Payout.all).not_to include(payout)
    end

    it "is included in the discarded scope after discard!" do
      payout.discard!
      expect(Payout.discarded).to include(payout)
    end
  end
end
