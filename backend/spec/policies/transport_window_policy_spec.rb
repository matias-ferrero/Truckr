# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransportWindowPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:owner_user)  { create(:user, :with_carrier) }
  let(:other_user)  { create(:user, :with_carrier) }
  let(:vehicle)     { create(:vehicle, carrier: owner_user.carrier) }
  let(:window)      { create(:transport_window, vehicle: vehicle) }

  describe "index?" do
    it "allows a carrier" do
      expect(policy.new(owner_user, window).index?).to be true
    end

    it "denies a user without carrier role" do
      user = create(:user)
      expect(policy.new(user, window).index?).to be false
    end
  end

  describe "show? / update? / destroy?" do
    it "allows the owner carrier" do
      expect(policy.new(owner_user, window).show?).to   be true
      expect(policy.new(owner_user, window).update?).to be true
      expect(policy.new(owner_user, window).destroy?).to be true
    end

    it "denies another carrier" do
      expect(policy.new(other_user, window).show?).to   be false
      expect(policy.new(other_user, window).update?).to be false
      expect(policy.new(other_user, window).destroy?).to be false
    end

    it "denies nil user" do
      expect(policy.new(nil, window).show?).to be false
    end
  end

  describe "create?" do
    it "allows the owner carrier to create on their vehicle" do
      new_window = build(:transport_window, vehicle: vehicle)
      expect(policy.new(owner_user, new_window).create?).to be true
    end

    it "denies another carrier creating on a foreign vehicle" do
      new_window = build(:transport_window, vehicle: vehicle)
      expect(policy.new(other_user, new_window).create?).to be false
    end
  end

  describe "Scope" do
    it "returns only the carrier's own windows" do
      mine   = create(:transport_window, vehicle: vehicle)
      _other = create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier))

      scope = described_class::Scope.new(owner_user, TransportWindow).resolve
      expect(scope).to contain_exactly(mine)
    end

    it "returns empty for a user without a carrier" do
      user = create(:user)
      scope = described_class::Scope.new(user, TransportWindow).resolve
      expect(scope).to be_empty
    end
  end
end
