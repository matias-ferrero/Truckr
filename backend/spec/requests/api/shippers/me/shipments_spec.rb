# frozen_string_literal: true

require "swagger_helper"

# REQ-BE-00035 §3.2 — Shipper shipment index (mirror of the Carrier endpoint).
RSpec.describe "Api::Shippers::Me::Shipments", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }

  def shipper_shipment(shipper_record, **overrides)
    cargo = create(:cargo, shipper: shipper_record)
    offer = create(:cargo_offer, :accepted, cargo: cargo)
    create(:shipment, :accepted, cargo_offer: offer, **overrides)
  end

  describe "GET /api/shippers/me/shipments" do
    context "without JWT" do
      it "returns 401" do
        get "/api/shippers/me/shipments"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a non-shipper user" do
      it "returns 403" do
        carrier_user = create(:user, :with_carrier)
        sign_in carrier_user

        get "/api/shippers/me/shipments"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an authenticated Shipper" do
      before { sign_in shipper_user }

      it "returns only the shipper's shipments" do
        mine_a = shipper_shipment(shipper)
        mine_b = shipper_shipment(shipper)
        shipper_shipment(create(:shipper))

        get "/api/shippers/me/shipments"

        expect(response).to have_http_status(:ok)
        ids = JSON.parse(response.body).map { |s| s["id"] }
        expect(ids).to contain_exactly(mine_a.id, mine_b.id)
      end

      it "omits discarded shipments" do
        kept = shipper_shipment(shipper)
        gone = shipper_shipment(shipper)
        gone.discard!

        get "/api/shippers/me/shipments"

        ids = JSON.parse(response.body).map { |s| s["id"] }
        expect(ids).to contain_exactly(kept.id)
      end

      it "sorts by latest_activity_at DESC" do
        old_ship = shipper_shipment(shipper)
        old_ship.update_columns(updated_at: 7.days.ago)

        recent_ship = shipper_shipment(shipper)
        recent_ship.update_columns(updated_at: 1.day.ago)

        get "/api/shippers/me/shipments"

        ids = JSON.parse(response.body).map { |s| s["id"] }
        expect(ids).to eq([ recent_ship.id, old_ship.id ])
      end

      it "does not include payment_state in response" do
        cargo = create(:cargo, shipper: shipper)
        offer = create(:cargo_offer, :accepted, cargo: cargo)
        create(:shipment, :accepted, cargo_offer: offer)

        get "/api/shippers/me/shipments"

        row = JSON.parse(response.body).first
        expect(row).not_to have_key("payment_state")
      end
    end
  end
end
