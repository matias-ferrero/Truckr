# frozen_string_literal: true

require "swagger_helper"

# REQ-BE-00035 §3.3 — Multi-role shipment detail endpoint.
RSpec.describe "Api::Shipments", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, carrier: carrier, cargo: cargo) }
  let(:shipment)     { create(:shipment, :accepted, cargo_offer: offer) }

  describe "GET /api/shipments/:id" do
    context "without JWT" do
      it "returns 401" do
        get "/api/shipments/#{shipment.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an authenticated non-counterparty" do
      it "returns 404 (not 403) — does not leak existence" do
        intruder = create(:user, :with_carrier)
        sign_in intruder

        get "/api/shipments/#{shipment.id}"

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for a user with no profiles" do
        bystander = create(:user)
        sign_in bystander

        get "/api/shipments/#{shipment.id}"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an unknown id" do
      it "returns 404" do
        sign_in carrier_user

        get "/api/shipments/999999"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the shipment is discarded" do
      it "returns 404 to the owning carrier" do
        shipment.discard!
        sign_in carrier_user

        get "/api/shipments/#{shipment.id}"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the requester is the owning Carrier" do
      before { sign_in carrier_user }

      it "returns 200 with the detail payload (counterparty = shipper)" do
        get "/api/shipments/#{shipment.id}"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["id"]).to eq(shipment.id)
        expect(body["counterparty"]["kind"]).to eq("shipper")
        expect(body["counterparty"]["id"]).to eq(shipper.id)
      end

      it "exposes cargo, vehicle, counterparty, payment, tracking_events, available_actions" do
        create(:tracking_event, shipment: shipment, recorded_at: 30.minutes.ago)

        get "/api/shipments/#{shipment.id}"

        body = JSON.parse(response.body)
        expect(body.keys).to include(
          "id", "state", "amount_cents", "currency",
          "cargo", "vehicle", "counterparty", "payment", "tracking_events",
          "available_actions"
        )
        expect(body.keys).not_to include("payment_state")
        expect(body["cargo"]).to include("id" => cargo.id, "origin" => cargo.pickup_address)
        expect(body["cargo"]).to have_key("pickup_lat")
        expect(body["cargo"]).to have_key("delivery_lng")
      end

      it "exposes payment block when Payment exists" do
        payment = create(:payment, :escrowed, shipment: shipment)

        get "/api/shipments/#{shipment.id}"

        body = JSON.parse(response.body)
        expect(body["payment"]).to include("id" => payment.id, "state" => "escrowed")
      end

      it "exposes null payment when none exists" do
        get "/api/shipments/#{shipment.id}"

        body = JSON.parse(response.body)
        expect(body["payment"]).to be_nil
      end

      it "sorts tracking_events ascending by occurred_at" do
        create(:tracking_event, shipment: shipment, recorded_at: 1.day.ago)
        create(:tracking_event, shipment: shipment, recorded_at: 3.days.ago)
        create(:tracking_event, shipment: shipment, recorded_at: 2.days.ago)

        get "/api/shipments/#{shipment.id}"

        timestamps = JSON.parse(response.body)["tracking_events"].map { |e| e["occurred_at"] }
        expect(timestamps).to eq(timestamps.sort)
      end
    end

    context "when the requester is the owning Shipper" do
      before { sign_in shipper_user }

      it "returns 200 with counterparty = carrier" do
        get "/api/shipments/#{shipment.id}"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["counterparty"]["kind"]).to eq("carrier")
        expect(body["counterparty"]["id"]).to eq(carrier.id)
      end
    end

    # US30 / REQ-BE-00044 — carrier_review hydration for AC7.
    describe "carrier_review (US30 / AC7)" do
      it "is nil for the Carrier viewer when no review exists yet" do
        sign_in carrier_user

        get "/api/shipments/#{shipment.id}"

        body = JSON.parse(response.body)
        expect(body).to have_key("carrier_review")
        expect(body["carrier_review"]).to be_nil
      end

      it "exposes the carrier-authored review to the owning Carrier" do
        review = create(:review, :carrier_authored, shipment: shipment)
        sign_in carrier_user

        get "/api/shipments/#{shipment.id}"

        body = JSON.parse(response.body)
        expect(body["carrier_review"]).to include(
          "id"          => review.id,
          "rating"      => review.rating,
          "authored_by" => "carrier"
        )
      end

      it "is nil for the Shipper viewer even when a carrier review exists" do
        create(:review, :carrier_authored, shipment: shipment)
        sign_in shipper_user

        get "/api/shipments/#{shipment.id}"

        body = JSON.parse(response.body)
        expect(body["carrier_review"]).to be_nil
      end
    end

    describe "counterparty_contact reveal (REQ-BE-00033 / AC9)" do
      it "is null before any Payment is escrowed (carrier viewer)" do
        sign_in carrier_user
        get "/api/shipments/#{shipment.id}"

        expect(JSON.parse(response.body)["counterparty_contact"]).to be_nil
      end

      it "is null before any Payment is escrowed (shipper viewer)" do
        sign_in shipper_user
        get "/api/shipments/#{shipment.id}"

        expect(JSON.parse(response.body)["counterparty_contact"]).to be_nil
      end

      it "exposes the Carrier user's contact triple once the Payment is escrowed (shipper viewer)" do
        carrier_user.update!(full_name: "Carrier Person", phone: "+54 11 5555-3333")
        create(:payment, :escrowed, shipment: shipment)
        sign_in shipper_user

        get "/api/shipments/#{shipment.id}"

        contact = JSON.parse(response.body)["counterparty_contact"]
        expect(contact).to include(
          "full_name" => "Carrier Person",
          "email"     => carrier_user.email,
          "phone"     => "+54 11 5555-3333"
        )
      end

      it "exposes the Shipper user's contact triple once the Payment is escrowed (carrier viewer)" do
        shipper_user.update!(full_name: "Shipper Person", phone: "+54 11 5555-4444")
        create(:payment, :escrowed, shipment: shipment)
        sign_in carrier_user

        get "/api/shipments/#{shipment.id}"

        contact = JSON.parse(response.body)["counterparty_contact"]
        expect(contact).to include(
          "full_name" => "Shipper Person",
          "email"     => shipper_user.email,
          "phone"     => "+54 11 5555-4444"
        )
      end
    end

    describe "available_actions matrix (REQ-BE-00035 §4.4)" do
      def detail_for(user)
        sign_in user
        get "/api/shipments/#{shipment.id}"
        JSON.parse(response.body)["available_actions"]
      end

      context "carrier viewer" do
        it "accepted + pending payment → []" do
          expect(detail_for(carrier_user)).to eq([])
        end

        it "accepted + paid → [start_transit]" do
          create(:payment, :escrowed, shipment: shipment)

          expect(detail_for(carrier_user)).to eq([ "start_transit" ])
        end

        it "in_transit → [deliver]" do
          create(:payment, :escrowed, shipment: shipment)
          shipment.update!(status: "in_transit", picked_up_at: 1.hour.ago)

          expect(detail_for(carrier_user)).to eq([ "deliver" ])
        end

        it "delivered → []" do
          create(:payment, :escrowed, shipment: shipment)
          shipment.update!(status: "delivered", picked_up_at: 2.hours.ago, delivered_at: 1.hour.ago)

          expect(detail_for(carrier_user)).to eq([])
        end
      end

      context "shipper viewer" do
        it "accepted + pending → [pay]" do
          expect(detail_for(shipper_user)).to eq([ "pay" ])
        end

        it "accepted + paid → [] (post-pay interlock, ADR-012)" do
          create(:payment, :escrowed, shipment: shipment)

          expect(detail_for(shipper_user)).to eq([])
        end
      end
    end
  end
end
