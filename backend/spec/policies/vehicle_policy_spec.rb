# frozen_string_literal: true

require "rails_helper"

RSpec.describe VehiclePolicy, type: :policy do
  let(:owner_user) { create(:user, :with_carrier) }
  let(:other_user) { create(:user, :with_carrier) }
  let(:anonymous)  { nil }
  let(:vehicle)    { create(:vehicle, carrier: owner_user.carrier) }

  describe "#create? / #update? / #destroy?" do
    it "allows the owner carrier" do
      policy = described_class.new(owner_user, vehicle)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end

    it "denies other carriers" do
      policy = described_class.new(other_user, vehicle)
      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end

    it "denies anonymous" do
      policy = described_class.new(anonymous, vehicle)
      expect(policy.create?).to be(false)
    end
  end

  describe "Scope" do
    it "returns only the owner's vehicles" do
      mine    = create(:vehicle, carrier: owner_user.carrier)
      _theirs = create(:vehicle, carrier: other_user.carrier)
      scope   = described_class::Scope.new(owner_user, Vehicle).resolve
      expect(scope).to contain_exactly(mine)
    end

    it "returns none for anonymous users" do
      create(:vehicle)
      scope = described_class::Scope.new(anonymous, Vehicle).resolve
      expect(scope).to be_empty
    end
  end

  describe "#index? / #show?" do
    it "is open to everyone (controller picks)" do
      expect(described_class.new(anonymous, vehicle).index?).to be(true)
      expect(described_class.new(anonymous, vehicle).show?).to be(true)
    end
  end
end
