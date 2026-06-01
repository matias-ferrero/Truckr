# frozen_string_literal: true

require "rails_helper"

# US54 / REQ-BE-00045 — Shipper public profile + paginated reviews.
RSpec.describe "Api::Shippers", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:viewer) { create(:user, :with_carrier) }
  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper) { shipper_user.shipper }

  # Build a delivered shipment owned by `shipper` and carried by `carrier`,
  # then a carrier-authored review of the given rating on it. Each call wires a
  # fresh shipment so the per-shipment uniqueness guard is never tripped.
  def review_for(shipper, rating:, carrier: create(:user, :with_carrier).carrier)
    cargo = create(:cargo, shipper: shipper)
    offer = create(:cargo_offer, :accepted, carrier: carrier, cargo: cargo)
    shipment = create(:shipment, :delivered, cargo_offer: offer)
    create(:review, :carrier_authored, shipment: shipment,
                                        shipper: shipper, carrier: carrier, rating: rating)
  end

  describe "GET /api/shippers/:id" do
    context "without JWT" do
      it "returns 401" do
        get "/api/shippers/#{shipper.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before { sign_in viewer }

      it "returns the profile with null rating_avg and zero count when no reviews" do
        get "/api/shippers/#{shipper.id}"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["id"]).to eq(shipper.id)
        expect(body["company_name"]).to eq(shipper.company_name)
        expect(body["rating_avg"]).to be_nil
        expect(body["reviews_count"]).to eq(0)
      end

      it "computes rating_avg (rounded to 1 dp) and reviews_count (AC4)" do
        review_for(shipper, rating: 5)
        review_for(shipper, rating: 4)
        review_for(shipper, rating: 4) # avg = 13/3 = 4.33 → 4.3

        get "/api/shippers/#{shipper.id}"

        body = JSON.parse(response.body)
        expect(body["rating_avg"]).to eq("4.3")
        expect(body["reviews_count"]).to eq(3)
      end

      it "returns 404 for an unknown shipper" do
        get "/api/shippers/0"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/shippers/:id/reviews" do
    context "without JWT" do
      it "returns 401 (AC6)" do
        get "/api/shippers/#{shipper.id}/reviews"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before { sign_in viewer }

      it "returns the reviews newest-first as ReviewResource" do
        old = review_for(shipper, rating: 3)
        recent = review_for(shipper, rating: 5)
        old.update!(created_at: 2.days.ago)
        recent.update!(created_at: 1.hour.ago)

        get "/api/shippers/#{shipper.id}/reviews"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body.map { |r| r["id"] }).to eq([ recent.id, old.id ])
        expect(body.first.keys).to include("id", "rating", "body", "authored_by", "created_at")
        expect(body.first["authored_by"]).to eq("carrier")
      end

      it "paginates 10 per page (AC3)" do
        12.times { review_for(shipper, rating: 4) }

        get "/api/shippers/#{shipper.id}/reviews"

        expect(JSON.parse(response.body).size).to eq(10)
        expect(response.headers["X-Total"]).to eq("12")
        expect(response.headers["X-Per-Page"]).to eq("10")
        expect(response.headers["X-Total-Pages"]).to eq("2")

        get "/api/shippers/#{shipper.id}/reviews", params: { page: 2 }
        expect(JSON.parse(response.body).size).to eq(2)
      end

      it "scopes to the shipper — excludes reviews about other shippers" do
        review_for(shipper, rating: 5)
        other = create(:user, :with_shipper).shipper
        review_for(other, rating: 1)

        get "/api/shippers/#{shipper.id}/reviews"

        body = JSON.parse(response.body)
        expect(body.size).to eq(1)
        expect(body.first["rating"]).to eq(5)
      end

      it "returns 404 for an unknown shipper" do
        get "/api/shippers/0/reviews"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
