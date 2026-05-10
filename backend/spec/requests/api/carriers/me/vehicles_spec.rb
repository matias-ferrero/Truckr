# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Carriers::Me::Vehicles", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user)    { create(:user, :with_carrier) }
  let(:carrier) { user.carrier }
  let(:other_user) { create(:user, :with_carrier) }

  before { sign_in user }

  describe "GET /api/carriers/me/vehicles" do
    it "lists only my vehicles with pagination headers" do
      mine_a = create(:vehicle, carrier: carrier)
      mine_b = create(:vehicle, carrier: carrier)
      _other = create(:vehicle, carrier: other_user.carrier)

      get "/api/carriers/me/vehicles"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |v| v["id"] }).to contain_exactly(mine_a.id, mine_b.id)
      expect(response.headers["X-Total"]).to eq("2")
      expect(response.headers["X-Page"]).to eq("1")
    end

    it "rejects unauthenticated requests" do
      sign_out user
      get "/api/carriers/me/vehicles"
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq(
        "error" => { "code" => "unauthorized", "message" => "Autenticación requerida" }
      )
    end
  end

  describe "POST /api/carriers/me/vehicles" do
    let(:valid_params) do
      {
        vehicle: {
          make: "Mercedes-Benz", model: "Sprinter", year: 2021,
          plate: "AB123CD", vehicle_type: "truck_small",
          max_load_kg: "3500.50", length_cm: 500, width_cm: 180, height_cm: 220,
          gps_enabled: false, description: "vehículo principal"
        }
      }
    end

    it "creates a vehicle and returns full payload" do
      post "/api/carriers/me/vehicles", params: valid_params
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include(
        "make" => "Mercedes-Benz",
        "plate" => "AB123CD",
        "vehicle_type" => "truck_small"
      )
      expect(body["volume_cm3"]).to eq(500 * 180 * 220)
    end

    it "returns 422 with validation envelope on bad input" do
      post "/api/carriers/me/vehicles",
           params: { vehicle: valid_params[:vehicle].merge(plate: "x", make: "") }
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("unprocessable")
      expect(body["error"]["details"]).to be_a(Hash)
    end

    it "supports multipart photo uploads" do
      file = Rack::Test::UploadedFile.new(
        StringIO.new("\x89PNG\r\n\x1a\n" + ("0" * 64)),
        "image/png",
        original_filename: "front.png"
      )
      params = valid_params.deep_dup
      params[:vehicle][:photos] = [ file ]

      post "/api/carriers/me/vehicles", params: params
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["photos"].size).to eq(1)
    end
  end

  describe "PATCH /api/carriers/me/vehicles/:id" do
    let(:vehicle) { create(:vehicle, carrier: carrier) }

    it "updates an owned vehicle" do
      patch "/api/carriers/me/vehicles/#{vehicle.id}",
            params: { vehicle: { description: "renovado" } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["description"]).to eq("renovado")
    end

    it "rejects updates to a vehicle owned by another carrier" do
      foreign = create(:vehicle, carrier: other_user.carrier)
      patch "/api/carriers/me/vehicles/#{foreign.id}",
            params: { vehicle: { description: "hijack" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/carriers/me/vehicles/:id" do
    it "destroys a vehicle and leaves siblings intact (multi-vehicle support)" do
      a = create(:vehicle, carrier: carrier)
      b = create(:vehicle, carrier: carrier)
      delete "/api/carriers/me/vehicles/#{a.id}"
      expect(response).to have_http_status(:no_content)
      expect(carrier.vehicles.reload).to contain_exactly(b)
    end
  end

  describe "multi-vehicle scenario (REQ-BE-00010)" do
    it "supports a second vehicle and lists both" do
      params = {
        vehicle: { make: "M", model: "A", plate: "AAA111", vehicle_type: "van",
                   max_load_kg: 1000, gps_enabled: false }
      }
      post "/api/carriers/me/vehicles", params: params
      expect(response).to have_http_status(:created)

      params2 = params.deep_dup
      params2[:vehicle][:plate] = "BBB222"
      post "/api/carriers/me/vehicles", params: params2
      expect(response).to have_http_status(:created)

      get "/api/carriers/me/vehicles"
      expect(JSON.parse(response.body).size).to eq(2)
    end
  end
end
