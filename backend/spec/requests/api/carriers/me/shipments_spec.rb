# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Carriers::Me::Shipments", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:carrier_user) { create(:user, :with_carrier) }
  let(:carrier)      { carrier_user.carrier }

  before { sign_in carrier_user }

  describe "GET /api/carriers/me/shipments" do
    it "returns active shipments by default" do
      mine_accepted = create(:shipment, :accepted,
                             cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
      mine_in_transit = create(:shipment, :in_transit,
                               cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
      _mine_delivered = create(:shipment, :delivered,
                               cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))

      other_carrier = create(:carrier)
      _foreign = create(:shipment, :accepted,
                        cargo_offer: create(:cargo_offer, :accepted, carrier: other_carrier))

      get "/api/carriers/me/shipments"

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |s| s["id"] }
      expect(ids).to contain_exactly(mine_accepted.id, mine_in_transit.id)
    end

    it "supports explicit status filters" do
      delivered = create(:shipment, :delivered,
                         cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))
      _in_transit = create(:shipment, :in_transit,
                           cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))

      get "/api/carriers/me/shipments", params: { status: "delivered" }

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |s| s["id"] }
      expect(ids).to contain_exactly(delivered.id)
    end

    it "returns empty list for invalid filters" do
      create(:shipment, :accepted, cargo_offer: create(:cargo_offer, :accepted, carrier: carrier))

      get "/api/carriers/me/shipments", params: { status: "disputed" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "rejects unauthenticated requests" do
      sign_out carrier_user

      get "/api/carriers/me/shipments"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
