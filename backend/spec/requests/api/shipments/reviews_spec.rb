# frozen_string_literal: true

require "rails_helper"

# US20 / US30 — POST /api/shipments/:id/reviews (direction from poster's role).
RSpec.describe "Api::Shipments::Reviews", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }
  let(:cargo)        { create(:cargo, shipper: shipper) }
  let(:offer)        { create(:cargo_offer, :accepted, cargo: cargo, carrier: carrier, amount_cents: 7_500_000) }
  let(:shipment)     { create(:shipment, :delivered, cargo_offer: offer) }

  describe "POST /api/shipments/:shipment_id/reviews" do
    let(:valid_body) { { rating: 5, body: "Entrega puntual y buena comunicación." } }

    context "without JWT" do
      it "returns 401" do
        post "/api/shipments/#{shipment.id}/reviews", params: valid_body, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the requester is the owning Shipper" do
      before { sign_in shipper_user }

      it "returns 201 and persists a shipper-authored Review (happy path — AC1/AC2)" do
        expect {
          post "/api/shipments/#{shipment.id}/reviews", params: valid_body, as: :json
        }.to change(Review, :count).by(1)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["rating"]).to eq(5)
        expect(body["authored_by"]).to eq("shipper")
        expect(body["body"]).to eq(valid_body[:body])

        review = Review.find(body["id"])
        expect(review.authored_by).to eq("shipper_authored")
        expect(review.shipment_id).to eq(shipment.id)
        expect(review.shipper_id).to eq(shipper.id)
        expect(review.carrier_id).to eq(carrier.id)
      end

      it "accepts a null body (comment is optional — AC2)" do
        post "/api/shipments/#{shipment.id}/reviews", params: { rating: 4, body: nil }, as: :json

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["body"]).to be_nil
      end

      it "returns 409 when the Shipment is not delivered (state guard — AC5)" do
        pending_shipment = create(:shipment, :accepted, cargo_offer: offer)

        post "/api/shipments/#{pending_shipment.id}/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body).dig("error", "message")).to be_present
        expect(Review.count).to eq(0)
      end

      it "returns 409 when a shipper review already exists (uniqueness guard — AC3)" do
        create(:review, :shipper_authored, shipment: shipment, carrier: carrier, shipper: shipper)

        post "/api/shipments/#{shipment.id}/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:conflict)
        expect(Review.shipper_authored.where(shipment_id: shipment.id).count).to eq(1)
      end

      it "returns 422 when the rating is out of range (validation)" do
        post "/api/shipments/#{shipment.id}/reviews", params: { rating: 6 }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Review.count).to eq(0)
      end
    end

    context "when the requester is a different Shipper" do
      it "returns 403 (authorization guard — AC4)" do
        other_shipper_user = create(:user, :with_shipper)
        sign_in other_shipper_user

        post "/api/shipments/#{shipment.id}/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(Review.count).to eq(0)
      end
    end

    context "when the Shipment does not exist (shipper poster)" do
      it "returns 404" do
        sign_in shipper_user

        post "/api/shipments/0/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the requester is the assigned Carrier" do
      let(:valid_body) { { rating: 5, body: "Carga lista a horario, comunicación impecable." } }

      before { sign_in carrier_user }

      it "returns 201 and persists a carrier-authored Review (happy path — AC1/AC2)" do
        expect {
          post "/api/shipments/#{shipment.id}/reviews", params: valid_body, as: :json
        }.to change(Review, :count).by(1)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["rating"]).to eq(5)
        expect(body["authored_by"]).to eq("carrier")
        expect(body["body"]).to eq(valid_body[:body])

        review = Review.find(body["id"])
        expect(review.authored_by).to eq("carrier_authored")
        expect(review.shipment_id).to eq(shipment.id)
        expect(review.carrier_id).to eq(carrier.id)
        expect(review.shipper_id).to eq(shipper.id)
      end

      it "accepts a null body (comment is optional — AC2)" do
        post "/api/shipments/#{shipment.id}/reviews", params: { rating: 4, body: nil }, as: :json

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["body"]).to be_nil
      end

      it "returns 409 when the Shipment is not delivered (state guard — AC5)" do
        pending_shipment = create(:shipment, :accepted, cargo_offer: offer)

        post "/api/shipments/#{pending_shipment.id}/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body).dig("error", "message")).to be_present
        expect(Review.count).to eq(0)
      end

      it "returns 409 when a carrier review already exists (uniqueness guard — AC3)" do
        create(:review, :carrier_authored, shipment: shipment, carrier: carrier, shipper: shipper)

        post "/api/shipments/#{shipment.id}/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:conflict)
        expect(Review.carrier_authored.where(shipment_id: shipment.id).count).to eq(1)
      end

      it "returns 422 when the rating is out of range (validation)" do
        post "/api/shipments/#{shipment.id}/reviews", params: { rating: 6 }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Review.count).to eq(0)
      end
    end

    context "when the requester is a different Carrier" do
      let(:valid_body) { { rating: 5, body: "Carga lista a horario." } }

      it "returns 403 (authorization guard — AC4)" do
        other_carrier_user = create(:user, :with_carrier)
        sign_in other_carrier_user

        post "/api/shipments/#{shipment.id}/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(Review.count).to eq(0)
      end
    end

    context "when the Shipment does not exist (carrier poster)" do
      let(:valid_body) { { rating: 5, body: nil } }

      it "returns 404" do
        sign_in carrier_user

        post "/api/shipments/0/reviews", params: valid_body, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
