# frozen_string_literal: true

require "swagger_helper"

# Carrier Dashboard activity feed — payouts settled, reviews received from
# Shippers, and inbound offer events, merged newest-first (carrier-dashboard-v2).
RSpec.describe "Api::Carriers::Me::Activity", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }

  def carrier_offer(carrier_record, *traits, **overrides)
    create(:cargo_offer, *traits, carrier: carrier_record, **overrides)
  end

  describe "GET /api/carriers/me/activity" do
    context "without JWT" do
      it "returns 401" do
        get "/api/carriers/me/activity"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a non-carrier user" do
      it "returns 403" do
        sign_in create(:user, :with_shipper)

        get "/api/carriers/me/activity"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an authenticated Carrier" do
      before { sign_in carrier_user }

      it "merges payout, review and offer events scoped to the carrier" do
        offer    = carrier_offer(carrier, :accepted)
        shipment = create(:shipment, :delivered, cargo_offer: offer)
        payout   = create(:payout, :paid, shipment: shipment)
        review   = create(:review, :shipper_authored, shipment: shipment)
        # Foreign noise — must never leak into this carrier's feed.
        foreign_offer = create(:cargo_offer, :accepted)
        foreign_ship  = create(:shipment, :delivered, cargo_offer: foreign_offer)
        create(:payout, :paid, shipment: foreign_ship)
        create(:review, :shipper_authored, shipment: foreign_ship)

        get "/api/carriers/me/activity"

        expect(response).to have_http_status(:ok)
        rows = JSON.parse(response.body)
        ids = rows.map { |r| r["id"] }
        expect(ids).to contain_exactly(
          "payout-#{payout.id}",
          "review-#{review.id}",
          "offer-#{offer.id}-received",
          "offer-#{offer.id}-accepted"
        )
      end

      it "exposes the heterogeneous row shape with route context" do
        offer    = carrier_offer(carrier, :accepted)
        shipment = create(:shipment, :delivered, cargo_offer: offer)
        payout   = create(:payout, :paid, shipment: shipment)
        review   = create(:review, :shipper_authored, shipment: shipment, rating: 4)

        get "/api/carriers/me/activity"

        rows = JSON.parse(response.body).index_by { |r| r["id"] }

        payout_row = rows.fetch("payout-#{payout.id}")
        expect(payout_row).to include(
          "kind"         => "payout_paid",
          "shipment_id"  => shipment.id,
          "amount_cents" => payout.amount_cents,
          "currency"     => "ARS"
        )
        expect(payout_row["origin"]).to eq(offer.cargo.pickup_locality)
        expect(payout_row["destination"]).to eq(offer.cargo.delivery_locality)
        expect(payout_row).to have_key("occurred_at")

        review_row = rows.fetch("review-#{review.id}")
        expect(review_row).to include(
          "kind"        => "review_received",
          "shipment_id" => shipment.id,
          "rating"      => 4
        )

        offer_row = rows.fetch("offer-#{offer.id}-received")
        expect(offer_row).to include(
          "kind"           => "offer_received",
          "cargo_offer_id" => offer.id,
          "amount_cents"   => offer.amount_cents
        )
      end

      it "emits a rejected event for rejected offers" do
        offer = carrier_offer(carrier, :rejected)

        get "/api/carriers/me/activity"

        ids = JSON.parse(response.body).map { |r| r["id"] }
        expect(ids).to include("offer-#{offer.id}-received", "offer-#{offer.id}-rejected")
        expect(ids).not_to include("offer-#{offer.id}-accepted")
      end

      it "orders newest first and caps the feed" do
        stub_const("Carriers::ActivityFeed::RECENT_LIMIT", 5)
        offers = Array.new(6) do |i|
          offer = carrier_offer(carrier)
          offer.update_columns(created_at: (i + 1).hours.ago)
          offer
        end

        get "/api/carriers/me/activity"

        rows = JSON.parse(response.body)
        expect(rows.size).to eq(5)
        # offers[0] is the newest (1 hour ago); the oldest one falls off.
        expect(rows.map { |r| r["id"] }).to eq(
          offers.first(5).map { |o| "offer-#{o.id}-received" }
        )
      end

      it "returns an empty array for a carrier with no history" do
        get "/api/carriers/me/activity"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end
end
