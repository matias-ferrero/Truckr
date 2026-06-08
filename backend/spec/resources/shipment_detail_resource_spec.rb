# frozen_string_literal: true

require "rails_helper"

# US15 / REQ-BE-00046 — payout field visibility in ShipmentDetailResource.
#
# The `payout` attribute must be present and populated when the viewer is the
# Carrier and a payout exists, and nil in every other situation (no payout yet,
# Shipper viewer).
RSpec.describe ShipmentDetailResource, type: :resource do
  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier) }
  let(:shipment)     { create(:shipment, :delivered, cargo_offer: offer) }
  let(:payment)      { shipment.payments.find_by(state: "escrowed") }
  let!(:payout)      { create(:payout, :paid, shipment: shipment, payment: payment) }

  def serialize(viewer)
    json = described_class.new(shipment, params: { current_user: viewer }).serialize
    JSON.parse(json)
  end

  describe "payout field — Carrier viewer" do
    subject(:data) { serialize(carrier_user) }

    it "includes the payout key" do
      expect(data).to have_key("payout")
    end

    it "returns a non-null payout object" do
      expect(data["payout"]).not_to be_nil
    end

    it "includes all required breakdown fields" do
      p = data["payout"]
      expect(p).to include(
        "id"                 => payout.id,
        "state"              => "paid",
        "gross_amount_cents" => payout.gross_amount_cents,
        "commission_cents"   => payout.commission_cents,
        "amount_cents"       => payout.amount_cents,
        "currency"           => "ARS"
      )
      expect(p["commission_rate"]).to eq(payout.commission_rate.to_s)
      expect(p["paid_at"]).not_to be_nil
    end
  end

  describe "payout field — Shipper viewer" do
    subject(:data) { serialize(shipper_user) }

    it "returns null for payout (Shipper must not see breakdown)" do
      expect(data["payout"]).to be_nil
    end
  end

  describe "payout field — Carrier viewer, no payout yet" do
    before do
      payout.discard!
      shipment.reload
    end

    subject(:data) { serialize(carrier_user) }

    it "returns null when no payout exists" do
      expect(data["payout"]).to be_nil
    end
  end
end
