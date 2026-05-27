# frozen_string_literal: true

require "rails_helper"

# REQ-BE-00033 / US8 — Shipper payment endpoint.
RSpec.describe "Api::Shipments::Payments", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier, amount_cents: 7_500_000) }
  let(:shipment)     { create(:shipment, :accepted, cargo_offer: offer) }

  describe "POST /api/shipments/:shipment_id/payments" do
    context "without JWT" do
      it "returns 401" do
        post "/api/shipments/#{shipment.id}/payments"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the requester is the owning Shipper" do
      before { sign_in shipper_user }

      it "returns 201 with the persisted Payment id + state" do
        post "/api/shipments/#{shipment.id}/payments"

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["state"]).to eq("escrowed")
        expect(body["payment_id"]).to be_a(Integer)
        expect(Payment.find(body["payment_id"]).shipment_id).to eq(shipment.id)
      end

      it "returns 409 when the Shipment is already escrowed" do
        create(:payment, :escrowed, shipment: shipment)

        post "/api/shipments/#{shipment.id}/payments"

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body).dig("error", "message")).to be_present
      end

      it "returns 409 when the Shipment is not accepted" do
        create(:payment, :escrowed, shipment: shipment)
        shipment.transition_to!(:pending_payment)

        post "/api/shipments/#{shipment.id}/payments"

        expect(response).to have_http_status(:conflict)
      end
    end

    context "when the requester is a different Shipper" do
      it "returns 403" do
        other_shipper_user = create(:user, :with_shipper)
        sign_in other_shipper_user

        post "/api/shipments/#{shipment.id}/payments"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the requester is the owning Carrier" do
      it "returns 403" do
        sign_in carrier_user

        post "/api/shipments/#{shipment.id}/payments"

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
