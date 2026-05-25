# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShipmentPolicy, type: :policy do
  subject(:policy) { described_class.new(user, shipment) }

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, carrier: carrier, cargo: cargo) }
  let(:shipment)     { create(:shipment, :accepted, cargo_offer: offer) }

  describe "#show?" do
    context "when the user is the owning carrier" do
      let(:user) { carrier_user }
      it { is_expected.to be_show }
    end

    context "when the user is the owning shipper" do
      let(:user) { shipper_user }
      it { is_expected.to be_show }
    end

    context "when the user is a foreign carrier" do
      let(:user) { create(:user, :with_carrier) }
      it { is_expected.not_to be_show }
    end

    context "when the user has no profile" do
      let(:user) { create(:user) }
      it { is_expected.not_to be_show }
    end

    context "when there is no user" do
      let(:user) { nil }
      it { is_expected.not_to be_show }
    end
  end

  describe "Scope" do
    let!(:carrier_shipment) { shipment } # carrier+shipper above own it
    let!(:other_shipment) do
      foreign_carrier = create(:carrier)
      create(
        :shipment, :accepted,
        cargo_offer: create(:cargo_offer, :accepted, carrier: foreign_carrier)
      )
    end

    it "returns only the carrier's own shipments" do
      ids = described_class::Scope.new(carrier_user, Shipment).resolve.pluck(:id)
      expect(ids).to contain_exactly(carrier_shipment.id)
    end

    it "returns only the shipper's own shipments" do
      ids = described_class::Scope.new(shipper_user, Shipment).resolve.pluck(:id)
      expect(ids).to contain_exactly(carrier_shipment.id)
    end

    it "returns none for users without a profile" do
      bystander = create(:user)
      ids = described_class::Scope.new(bystander, Shipment).resolve.pluck(:id)
      expect(ids).to be_empty
    end

    it "returns none for anonymous users" do
      expect(described_class::Scope.new(nil, Shipment).resolve.pluck(:id)).to be_empty
    end
  end
end
