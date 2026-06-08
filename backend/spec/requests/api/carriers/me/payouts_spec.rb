# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Carriers::Me::Payouts", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier) }
  let(:shipment)     { create(:shipment, :delivered, cargo_offer: offer) }
  let!(:payout)      { create(:payout, :paid, shipment: shipment) }

  describe "GET /api/carriers/me/payouts" do
    context "without JWT" do
      it "returns 401" do
        get "/api/carriers/me/payouts"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a shipper user" do
      it "returns 403" do
        sign_in shipper_user
        get "/api/carriers/me/payouts"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with the owning carrier" do
      before { sign_in carrier_user }

      it "returns 200" do
        get "/api/carriers/me/payouts"
        expect(response).to have_http_status(:ok)
      end

      it "returns only payouts belonging to this carrier" do
        other_carrier_user = create(:user, :with_carrier)
        other_cargo        = create(:cargo, shipper: shipper)
        other_offer        = create(:cargo_offer, :accepted, cargo: other_cargo, carrier: other_carrier_user.carrier)
        other_shipment     = create(:shipment, :delivered, cargo_offer: other_offer)
        create(:payout, :paid, shipment: other_shipment)

        get "/api/carriers/me/payouts"

        ids = parsed_response.pluck("id")
        expect(ids).to include(payout.id)
        expect(ids).not_to include(Payout.last.id) unless Payout.last.id == payout.id
      end

      it "includes the full financial breakdown" do
        get "/api/carriers/me/payouts"

        row = parsed_response.find { |p| p["id"] == payout.id }
        expect(row).to include(
          "gross_amount_cents" => payout.gross_amount_cents,
          "commission_rate"    => payout.commission_rate.to_s,
          "commission_cents"   => payout.commission_cents,
          "amount_cents"       => payout.amount_cents,
          "currency"           => "ARS",
          "state"              => "paid"
        )
      end

      it "includes origin, destination, and shipper_name" do
        get "/api/carriers/me/payouts"

        row = parsed_response.find { |p| p["id"] == payout.id }
        expect(row).to include(
          "origin"       => cargo.pickup_address,
          "destination"  => cargo.delivery_address,
          "shipper_name" => shipper.company_name
        )
      end

      it "returns payouts newest first" do
        older_payout = create(:payout, :paid, shipment: create(:shipment, :delivered, cargo_offer: create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier)))
        older_payout.update_columns(created_at: 2.days.ago)

        get "/api/carriers/me/payouts"

        ids = parsed_response.pluck("id")
        expect(ids.first).to eq(payout.id)
      end
    end
  end

  private

  def parsed_response
    JSON.parse(response.body)
  end
end
