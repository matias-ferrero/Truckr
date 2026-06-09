# frozen_string_literal: true

require "swagger_helper"

# Shipper Dashboard activity feed — recent TrackingEvents across the
# authenticated Shipper's own shipments.
RSpec.describe "Api::Shippers::Me::Activity", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:shipper_user) { create(:user, :with_shipper) }
  let(:shipper)      { shipper_user.shipper }

  # A delivered shipment owned by `shipper_record`.
  def shipper_shipment(shipper_record)
    cargo = create(:cargo, shipper: shipper_record)
    offer = create(:cargo_offer, :accepted, cargo: cargo)
    create(:shipment, :accepted, cargo_offer: offer)
  end

  describe "GET /api/shippers/me/activity" do
    context "without JWT" do
      it "returns 401" do
        get "/api/shippers/me/activity"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a non-shipper user" do
      it "returns 403" do
        carrier_user = create(:user, :with_carrier)
        sign_in carrier_user

        get "/api/shippers/me/activity"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an authenticated Shipper" do
      before { sign_in shipper_user }

      it "returns only events for the shipper's own shipments" do
        mine  = shipper_shipment(shipper)
        other = shipper_shipment(create(:shipper))
        mine_event  = create(:tracking_event, shipment: mine)
        create(:tracking_event, shipment: other)

        get "/api/shippers/me/activity"

        expect(response).to have_http_status(:ok)
        ids = JSON.parse(response.body).map { |e| e["id"] }
        expect(ids).to contain_exactly(mine_event.id)
      end

      it "orders events newest first and caps at 20" do
        shipment = shipper_shipment(shipper)
        events = Array.new(25) do |i|
          create(:tracking_event, shipment: shipment, recorded_at: i.minutes.ago)
        end

        get "/api/shippers/me/activity"

        body = JSON.parse(response.body)
        expect(body.size).to eq(20)
        # i=0 is the most recent (0 minutes ago); the 20 newest are events[0..19].
        expect(body.map { |e| e["id"] }).to eq(events.first(20).map(&:id))
      end

      it "exposes the activity-row shape" do
        shipment = shipper_shipment(shipper)
        event = create(:tracking_event, shipment: shipment,
                                        kind: "status_change",
                                        from_status: "accepted",
                                        to_status: "in_transit")

        get "/api/shippers/me/activity"

        row = JSON.parse(response.body).first
        expect(row).to include(
          "id"          => event.id,
          "shipment_id" => shipment.id,
          "kind"        => "status_change",
          "from_status" => "accepted",
          "to_status"   => "in_transit"
        )
        expect(row).to have_key("occurred_at")
      end

      it "nulls status fields for non-status_change events" do
        shipment = shipper_shipment(shipper)
        create(:tracking_event, :gps_update, shipment: shipment)

        get "/api/shippers/me/activity"

        row = JSON.parse(response.body).first
        expect(row["kind"]).to eq("gps_update")
        expect(row["from_status"]).to be_nil
        expect(row["to_status"]).to be_nil
      end
    end
  end
end
