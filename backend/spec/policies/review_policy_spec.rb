# frozen_string_literal: true

require "rails_helper"

# US30 / [[REQ-BE-00044]] — only the assigned Carrier may author a review
# about the Shipper of a Shipment.
RSpec.describe ReviewPolicy, type: :policy do
  subject(:policy) { described_class.new(user, shipment) }

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, carrier: carrier, cargo: cargo) }
  let(:shipment)     { create(:shipment, :delivered, cargo_offer: offer) }

  describe "#create_carrier_review?" do
    context "when the user is the assigned carrier" do
      let(:user) { carrier_user }
      it { is_expected.to be_create_carrier_review }
    end

    context "when the user is a foreign carrier" do
      let(:user) { create(:user, :with_carrier) }
      it { is_expected.not_to be_create_carrier_review }
    end

    context "when the user is the shipper" do
      let(:user) { shipper_user }
      it { is_expected.not_to be_create_carrier_review }
    end

    context "when the user has no profile" do
      let(:user) { create(:user) }
      it { is_expected.not_to be_create_carrier_review }
    end

    context "when there is no user" do
      let(:user) { nil }
      it { is_expected.not_to be_create_carrier_review }
    end
  end
end
