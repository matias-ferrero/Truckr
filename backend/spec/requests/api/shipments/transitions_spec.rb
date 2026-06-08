# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Shipments::Transitions", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier) }
  let(:shipment)     { create(:shipment, :accepted, cargo_offer: offer) }

  describe "POST /api/shipments/:id/start_transit" do
    context "without JWT" do
      it "returns 401" do
        post "/api/shipments/#{shipment.id}/start_transit"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an owning shipper" do
      it "returns 403" do
        sign_in shipper_user

        post "/api/shipments/#{shipment.id}/start_transit"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a foreign carrier" do
      it "returns 403" do
        sign_in create(:user, :with_carrier)

        post "/api/shipments/#{shipment.id}/start_transit"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with owning carrier" do
      before { sign_in carrier_user }

      it "returns 404 for unknown shipment" do
        post "/api/shipments/999999/start_transit"

        expect(response).to have_http_status(:not_found)
      end

      it "returns 200 and marks shipment in_transit with pickup timestamp" do
        create(:payment, :escrowed, shipment: shipment)

        post "/api/shipments/#{shipment.id}/start_transit"

        expect(response).to have_http_status(:ok)
        expect(shipment.reload.status).to eq("in_transit")
        expect(shipment.picked_up_at).to be_present
        event = shipment.tracking_events.order(:recorded_at).last
        expect(event.kind).to eq("status_change")
        expect(event.from_status).to eq("accepted")
        expect(event.to_status).to eq("in_transit")
      end

      it "returns 409 when shipment is accepted but unpaid" do
        post "/api/shipments/#{shipment.id}/start_transit"

        expect(response).to have_http_status(:conflict)
        expect(shipment.reload.status).to eq("accepted")
      end

      it "returns 409 when shipment is already in_transit" do
        create(:payment, :escrowed, shipment: shipment)
        shipment.transition_to!(:in_transit)

        post "/api/shipments/#{shipment.id}/start_transit"

        expect(response).to have_http_status(:conflict)
        expect(shipment.reload.status).to eq("in_transit")
      end
    end
  end

  describe "POST /api/shipments/:id/deliver" do
    let(:shipment_in_transit) { create(:shipment, :in_transit, cargo_offer: offer) }

    context "without JWT" do
      it "returns 401" do
        post "/api/shipments/#{shipment_in_transit.id}/deliver"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an owning shipper" do
      it "returns 403" do
        sign_in shipper_user

        post "/api/shipments/#{shipment_in_transit.id}/deliver"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a foreign carrier" do
      it "returns 403 and does not create a Payout" do
        sign_in create(:user, :with_carrier)

        expect {
          post "/api/shipments/#{shipment_in_transit.id}/deliver"
        }.not_to change(Payout, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with owning carrier" do
      before { sign_in carrier_user }

      it "returns 200 and marks shipment delivered with delivered_at timestamp" do
        post "/api/shipments/#{shipment_in_transit.id}/deliver"

        expect(response).to have_http_status(:ok)
        expect(shipment_in_transit.reload.status).to eq("delivered")
        expect(shipment_in_transit.delivered_at).to be_present
        event = shipment_in_transit.tracking_events.order(:recorded_at).last
        expect(event.kind).to eq("status_change")
        expect(event.from_status).to eq("in_transit")
        expect(event.to_status).to eq("delivered")
      end

      it "creates a Payout for the carrier" do
        expect {
          post "/api/shipments/#{shipment_in_transit.id}/deliver"
        }.to change(Payout, :count).by(1)

        payout = Payout.last
        expect(payout.state).to eq("paid")
        expect(payout.shipment_id).to eq(shipment_in_transit.id)
      end

      it "does not create a Payout on 409 (shipment not in transit)" do
        create(:payment, :escrowed, shipment: shipment)

        expect {
          post "/api/shipments/#{shipment.id}/deliver"
        }.not_to change(Payout, :count)

        expect(response).to have_http_status(:conflict)
      end

      it "emits PAYOUT_FAILED notification and returns 500 when payout creation fails (AC4 / US15)" do
        # Pre-create a payout so Payouts::Create raises ConflictError(:already_paid).
        # The escrowed payment is still present so Shipments::Transition succeeds first.
        escrowed = shipment_in_transit.payments.find_by(state: "escrowed")
        create(:payout, shipment: shipment_in_transit, payment: escrowed)

        expect(Notifications::Publisher).to receive(:publish).with(
          user_id: carrier_user.id,
          type:    Notifications::Type::PAYOUT_FAILED,
          payload: hash_including(shipment_id: shipment_in_transit.id)
        )

        post "/api/shipments/#{shipment_in_transit.id}/deliver"

        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns 409 when shipment is not in_transit" do
        create(:payment, :escrowed, shipment: shipment)

        post "/api/shipments/#{shipment.id}/deliver"

        expect(response).to have_http_status(:conflict)
        expect(shipment.reload.status).to eq("accepted")
      end
    end
  end
end
