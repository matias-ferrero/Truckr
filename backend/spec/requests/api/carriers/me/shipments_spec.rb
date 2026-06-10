# frozen_string_literal: true

require "swagger_helper"

# REQ-BE-00035 §3.1 — Carrier shipment index.
RSpec.describe "Api::Carriers::Me::Shipments", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }

  def carrier_shipment(carrier_record, **overrides)
    offer = create(:cargo_offer, :accepted, carrier: carrier_record)
    create(:shipment, :accepted, cargo_offer: offer, **overrides)
  end

  describe "GET /api/carriers/me/shipments" do
    context "without JWT" do
      it "returns 401" do
        get "/api/carriers/me/shipments"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a non-carrier user" do
      it "returns 403" do
        shipper_user = create(:user, :with_shipper)
        sign_in shipper_user

        get "/api/carriers/me/shipments"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an authenticated Carrier" do
      before { sign_in carrier_user }

      it "returns the carrier's shipments in every status (no filter)" do
        mine = [
          carrier_shipment(carrier),
          create(:shipment, :in_transit,    cargo_offer: create(:cargo_offer, :accepted, carrier: carrier)),
          create(:shipment, :delivered,     cargo_offer: create(:cargo_offer, :accepted, carrier: carrier)),
          create(:shipment, :cancelled,     cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
        ]
        other = create(:carrier)
        carrier_shipment(other)

        get "/api/carriers/me/shipments"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        ids = body.map { |s| s["id"] }
        expect(ids).to match_array(mine.map(&:id))
      end

      it "omits discarded shipments (soft-delete, ADR-009)" do
        kept     = carrier_shipment(carrier)
        gone     = carrier_shipment(carrier)
        gone.discard!

        get "/api/carriers/me/shipments"

        ids = JSON.parse(response.body).map { |s| s["id"] }
        expect(ids).to contain_exactly(kept.id)
      end

      it "sorts by latest_activity_at DESC" do
        old_ship = carrier_shipment(carrier)
        old_ship.update_columns(updated_at: 5.days.ago)

        recent_ship = carrier_shipment(carrier)
        recent_ship.update_columns(updated_at: 2.days.ago)

        bumped_ship = carrier_shipment(carrier)
        bumped_ship.update_columns(updated_at: 10.days.ago)
        create(:tracking_event, shipment: bumped_ship, recorded_at: 1.minute.ago)

        get "/api/carriers/me/shipments"

        ids = JSON.parse(response.body).map { |s| s["id"] }
        expect(ids).to eq([ bumped_ship.id, recent_ship.id, old_ship.id ])
      end

      it "exposes the shape required by US17 (REQ-BE-00035 §4.1)" do
        carrier_shipment(carrier)

        get "/api/carriers/me/shipments"

        row = JSON.parse(response.body).first
        expect(row.keys).to include(
          "id", "state", "origin", "destination",
          "created_at", "amount_cents", "currency", "latest_activity_at", "payment_escrowed",
          "settled_at", "carrier_reviewed"
        )
        expect(row.keys).not_to include("payment_state")
      end

      it "flags carrier_reviewed once the Carrier has authored their review (carrier-dashboard-v2)" do
        reviewed   = create(:shipment, :delivered, cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
        unreviewed = create(:shipment, :delivered, cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
        create(:review, :carrier_authored, shipment: reviewed)
        # A shipper-authored review must NOT count as the carrier's.
        create(:review, :shipper_authored, shipment: unreviewed)

        get "/api/carriers/me/shipments"

        rows = JSON.parse(response.body).index_by { |s| s["id"] }
        expect(rows.fetch(reviewed.id)["carrier_reviewed"]).to be(true)
        expect(rows.fetch(unreviewed.id)["carrier_reviewed"]).to be(false)
      end

      it "exposes settled_at so the dashboard can split Entregadas / Pagadas" do
        unsettled = create(:shipment, :delivered, cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
        settled   = create(:shipment, :delivered, cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
        settled.update_columns(settled_at: 1.hour.ago)

        get "/api/carriers/me/shipments"

        rows = JSON.parse(response.body).index_by { |s| s["id"] }
        expect(rows.fetch(unsettled.id)["settled_at"]).to be_nil
        expect(rows.fetch(settled.id)["settled_at"]).to be_present
      end
    end
  end
end
