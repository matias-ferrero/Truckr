# frozen_string_literal: true

require "rails_helper"

# US26 — GET /api/carriers/:carrier_id/reviews + rating aggregates on show.
RSpec.describe "Api::Carriers::Reviews", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier) { create(:user, :with_carrier).carrier }
  let(:viewer)  { create(:user, :with_shipper) }

  describe "GET /api/carriers/:carrier_id/reviews" do
    def get_reviews(carrier_id, page: 1, headers: {})
      get "/api/carriers/#{carrier_id}/reviews",
          params: { page: page },
          headers: headers
    end

    it "returns 401 when unauthenticated" do
      get_reviews(carrier.id)
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end

    it "returns 404 when the carrier does not exist" do
      sign_in viewer
      get_reviews(999_999)
      expect(response).to have_http_status(:not_found)
    end

    context "when authenticated" do
      before { sign_in viewer }

      it "returns shipper-authored reviews newest first, 10 per page" do
        older = create(:review, :shipper_authored, carrier: carrier, rating: 3,
                       created_at: 2.days.ago)
        newer = create(:review, :shipper_authored, carrier: carrier, rating: 5,
                       created_at: 1.hour.ago)
        # Carrier-authored review about the same carrier must not appear.
        create(:review, :carrier_authored, carrier: carrier)

        get_reviews(carrier.id)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body.size).to eq(2)
        expect(body.first["id"]).to eq(newer.id)
        expect(body.last["id"]).to eq(older.id)
        expect(body.first.keys).to include("rating", "body", "created_at", "authored_by")
        expect(body.first["authored_by"]).to eq("shipper")
        expect(response.headers["X-Per-Page"]).to eq("10")
        expect(response.headers["X-Total"]).to eq("2")
      end

      it "paginates beyond the first page" do
        11.times do |i|
          create(:review, :shipper_authored, carrier: carrier,
                 rating: 4, created_at: i.hours.ago)
        end

        get_reviews(carrier.id, page: 2)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)
        expect(response.headers["X-Page"]).to eq("2")
        expect(response.headers["X-Total-Pages"]).to eq("2")
      end
    end
  end

  describe "GET /api/carriers/:id — rating_avg and reviews_count (AC4)" do
    it "computes rating_avg and reviews_count from shipper-authored reviews only" do
      create(:review, :shipper_authored, carrier: carrier, rating: 4)
      create(:review, :shipper_authored, carrier: carrier, rating: 5)
      create(:review, :carrier_authored, carrier: carrier, rating: 1)

      get "/api/carriers/#{carrier.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["rating_avg"]).to eq("4.5")
      expect(body["reviews_count"]).to eq(2)
    end

    it "returns null rating_avg and zero reviews_count when there are no shipper reviews" do
      carrier.update!(rating_avg: 3.0, reviews_count: 99)

      get "/api/carriers/#{carrier.id}"

      body = response.parsed_body
      expect(body["rating_avg"]).to be_nil
      expect(body["reviews_count"]).to eq(0)
    end
  end
end
