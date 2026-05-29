# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Carriers::Me::TransportWindows", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user)       { create(:user, :with_carrier) }
  let(:carrier)    { user.carrier }
  let(:vehicle)    { create(:vehicle, carrier: carrier) }
  let(:other_user) { create(:user, :with_carrier) }

  before { sign_in user }

  # ---------------------------------------------------------------------------
  # GET /api/carriers/me/transport_windows
  # ---------------------------------------------------------------------------
  describe "GET /api/carriers/me/transport_windows" do
    it "returns only the carrier's windows with pagination headers" do
      tw_a = create(:transport_window, vehicle: vehicle,
                    available_from: 2.days.from_now, available_to: 5.days.from_now)
      tw_b = create(:transport_window, vehicle: vehicle,
                    available_from: 10.days.from_now, available_to: 15.days.from_now)
      _other = create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier))

      get "/api/carriers/me/transport_windows"
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |w| w["id"] }
      expect(ids).to contain_exactly(tw_a.id, tw_b.id)
      expect(response.headers["X-Total"]).to eq("2")
      expect(response.headers["X-Page"]).to  eq("1")
    end

    it "includes embedded vehicle info" do
      create(:transport_window, vehicle: vehicle)
      get "/api/carriers/me/transport_windows"
      body = JSON.parse(response.body)
      expect(body.first["vehicle"]).to include("make" => vehicle.make, "plate" => vehicle.plate)
    end

    it "includes origin and destination coordinates in the payload" do
      tw = create(:transport_window, vehicle: vehicle)
      get "/api/carriers/me/transport_windows"
      body = JSON.parse(response.body).first
      expect(body["origin_lat"]).to      eq(tw.origin_lat.to_s)
      expect(body["origin_lng"]).to      eq(tw.origin_lng.to_s)
      expect(body["destination_lat"]).to eq(tw.destination_lat.to_s)
      expect(body["destination_lng"]).to eq(tw.destination_lng.to_s)
    end

    it "rejects unauthenticated requests" do
      sign_out user
      get "/api/carriers/me/transport_windows"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns both active and inactive windows" do
      active   = create(:transport_window, vehicle: vehicle, active: true,
                        available_from: 2.days.from_now, available_to: 5.days.from_now)
      inactive = create(:transport_window, vehicle: vehicle, active: false,
                        available_from: 10.days.from_now, available_to: 15.days.from_now)

      get "/api/carriers/me/transport_windows"
      ids = JSON.parse(response.body).map { |w| w["id"] }
      expect(ids).to contain_exactly(active.id, inactive.id)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /api/carriers/me/transport_windows/:id
  # ---------------------------------------------------------------------------
  describe "GET /api/carriers/me/transport_windows/:id" do
    it "returns the window with vehicle embedded" do
      tw = create(:transport_window, vehicle: vehicle)
      get "/api/carriers/me/transport_windows/#{tw.id}"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(tw.id)
      expect(body["vehicle"]["id"]).to eq(vehicle.id)
    end

    it "returns 404 for another carrier's window" do
      foreign = create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier))
      get "/api/carriers/me/transport_windows/#{foreign.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "serializes the whole destination block as null for open-destination windows" do
      tw = create(:transport_window, :open_destination, vehicle: vehicle)
      get "/api/carriers/me/transport_windows/#{tw.id}"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      %w[destination_address destination_locality destination_admin_area
         destination_lat destination_lng dropoff_radius_km].each do |key|
        expect(body).to have_key(key)
        expect(body[key]).to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------
  # POST /api/carriers/me/transport_windows
  # ---------------------------------------------------------------------------
  describe "POST /api/carriers/me/transport_windows" do
    let(:valid_params) do
      {
        transport_window: {
          vehicle_id:             vehicle.id,
          origin_address:         "Av. Corrientes 1234, CABA",
          origin_locality:        "CABA",
          origin_admin_area:      "Ciudad Autónoma de Buenos Aires",
          origin_lat:             "-34.603722",
          origin_lng:             "-58.381592",
          destination_address:    "Av. Colón 500, Córdoba",
          destination_locality:   "Córdoba",
          destination_admin_area: "Córdoba",
          destination_lat:        "-31.420083",
          destination_lng:        "-64.188776",
          pickup_radius_km:       50,
          dropoff_radius_km:      50,
          price_per_km:           1500.0,
          max_km:                 1200,
          available_from:         2.days.from_now.iso8601,
          available_to:           10.days.from_now.iso8601
        }
      }
    end

    it "creates a window and returns 201" do
      post "/api/carriers/me/transport_windows", params: valid_params
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include(
        "origin_locality"        => "CABA",
        "origin_admin_area"      => "Ciudad Autónoma de Buenos Aires",
        "destination_locality"   => "Córdoba",
        "destination_admin_area" => "Córdoba",
        "origin_lat"             => "-34.603722",
        "origin_lng"             => "-58.381592",
        "destination_lat"        => "-31.420083",
        "destination_lng"        => "-64.188776",
        "pickup_radius_km"       => 50,
        "dropoff_radius_km"      => 50,
        "active"                 => true
      )
    end

    it "rejects creation when origin_lat is missing" do
      params = valid_params.deep_dup
      params[:transport_window].delete(:origin_lat)

      post "/api/carriers/me/transport_windows", params: params
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body.dig("error", "details", "origin_lat")).to be_present
    end

    it "rejects creation with a foreign vehicle_id" do
      foreign_vehicle = create(:vehicle, carrier: other_user.carrier)
      params = valid_params.deep_dup
      params[:transport_window][:vehicle_id] = foreign_vehicle.id

      post "/api/carriers/me/transport_windows", params: params
      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when dates are incoherent" do
      params = valid_params.deep_dup
      params[:transport_window][:available_from] = 10.days.from_now.iso8601
      params[:transport_window][:available_to]   = 2.days.from_now.iso8601

      post "/api/carriers/me/transport_windows", params: params
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("unprocessable")
    end

    it "returns 422 when price_per_km is non-positive" do
      params = valid_params.deep_dup
      params[:transport_window][:price_per_km] = -1

      post "/api/carriers/me/transport_windows", params: params
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates an open-destination window (all destination fields blank) and returns 201" do
      params = valid_params.deep_dup
      %i[destination_address destination_locality destination_admin_area
         destination_lat destination_lng dropoff_radius_km].each do |k|
        params[:transport_window].delete(k)
      end

      post "/api/carriers/me/transport_windows", params: params
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["destination_lat"]).to be_nil
      expect(body["destination_locality"]).to be_nil
      expect(body["dropoff_radius_km"]).to be_nil
    end

    it "returns 422 when only some destination fields are set (open_destination_partial)" do
      params = valid_params.deep_dup
      params[:transport_window].delete(:dropoff_radius_km)

      post "/api/carriers/me/transport_windows", params: params
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body.dig("error", "code")).to eq("unprocessable")
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /api/carriers/me/transport_windows/:id
  # ---------------------------------------------------------------------------
  describe "PATCH /api/carriers/me/transport_windows/:id" do
    let(:window) { create(:transport_window, vehicle: vehicle) }

    it "updates an owned window's origin_locality" do
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { origin_locality: "Rosario" } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["origin_locality"]).to eq("Rosario")
    end

    it "can reactivate a deactivated window" do
      window.update!(active: false)
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { active: true } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["active"]).to be true
    end

    it "ignores vehicle_id change attempts" do
      other_vehicle = create(:vehicle, carrier: carrier)
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { vehicle_id: other_vehicle.id } }
      expect(response).to have_http_status(:ok)
      expect(window.reload.vehicle_id).to eq(vehicle.id)
    end

    it "returns 404 for another carrier's window" do
      foreign = create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier))
      patch "/api/carriers/me/transport_windows/#{foreign.id}",
            params: { transport_window: { origin_locality: "hijack" } }
      expect(response).to have_http_status(:not_found)
    end

    it "accepts pickup_radius_km updates" do
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { pickup_radius_km: 75 } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["pickup_radius_km"]).to eq(75)
    end

    it "rejects pickup_radius_km outside the 1..200 range" do
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { pickup_radius_km: 0 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts dropoff_radius_km updates" do
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { dropoff_radius_km: 75 } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["dropoff_radius_km"]).to eq(75)
    end

    it "rejects dropoff_radius_km outside the 1..200 range" do
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { dropoff_radius_km: 0 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    # AC17 — radius is a discoverability filter, not a retroactive constraint:
    # shrinking it must NOT mutate `pending` CargoOffers, even when offers
    # whose cargo now sits outside the radius exist.
    it "shrinking pickup_radius_km does not mutate associated pending CargoOffers" do
      window.update!(pickup_radius_km: 200,
                     origin_lat: -34.603722, origin_lng: -58.381592)
      shipper_for_cargo = create(:user, :with_shipper)
      cargo = create(:cargo, shipper: shipper_for_cargo.shipper,
                     pickup_lat: -32.946820, pickup_lng: -60.639317, # Rosario, ~280 km
                     pickup_window_start: window.available_from + 1.hour,
                     pickup_window_end:   window.available_to   - 1.hour)
      offer = create(:cargo_offer, :pending, transport_window: window, cargo: cargo)

      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { pickup_radius_km: 5 } }
      expect(response).to have_http_status(:ok)
      expect(offer.reload.status).to eq("pending")
    end

    it "shrinking dropoff_radius_km does not mutate associated pending CargoOffers" do
      window.update!(dropoff_radius_km: 200)
      shipper_for_cargo = create(:user, :with_shipper)
      cargo = create(:cargo, shipper: shipper_for_cargo.shipper,
                     pickup_window_start: window.available_from + 1.hour,
                     pickup_window_end:   window.available_to   - 1.hour)
      offer = create(:cargo_offer, :pending, transport_window: window, cargo: cargo)

      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { dropoff_radius_km: 5 } }
      expect(response).to have_http_status(:ok)
      expect(offer.reload.status).to eq("pending")
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /api/carriers/me/transport_windows/:id  (hard delete)
  # ---------------------------------------------------------------------------
  describe "DELETE /api/carriers/me/transport_windows/:id" do
    it "destroys the record and returns 204" do
      tw = create(:transport_window, vehicle: vehicle)
      delete "/api/carriers/me/transport_windows/#{tw.id}"
      expect(response).to have_http_status(:no_content)
      expect(TransportWindow.exists?(tw.id)).to be false
    end

    it "returns 404 for another carrier's window" do
      foreign = create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier))
      delete "/api/carriers/me/transport_windows/#{foreign.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when the window has associated cargo offers" do
      tw = create(:transport_window, vehicle: vehicle,
                  available_from: 1.day.from_now, available_to: 10.days.from_now)
      create(:cargo_offer, transport_window: tw)
      delete "/api/carriers/me/transport_windows/#{tw.id}"
      expect(response).to have_http_status(:unprocessable_content)
      expect(TransportWindow.exists?(tw.id)).to be true
    end
  end

  # ---------------------------------------------------------------------------
  # Overlap validation — inactive windows are ignored
  # ---------------------------------------------------------------------------
  describe "overlap validation against inactive windows" do
    it "allows creating a window whose dates overlap only with an inactive window" do
      create(:transport_window, vehicle: vehicle, active: false,
             available_from: 2.days.from_now, available_to: 10.days.from_now)

      post "/api/carriers/me/transport_windows", params: {
        transport_window: {
          vehicle_id:             vehicle.id,
          origin_address:         "Av. Corrientes 1234, CABA",
          origin_locality:        "CABA",
          origin_admin_area:      "Ciudad Autónoma de Buenos Aires",
          destination_address:    "Av. Colón 500, Córdoba",
          destination_locality:   "Córdoba",
          destination_admin_area: "Córdoba",
          origin_lat:             "-34.603722",
          origin_lng:             "-58.381592",
          destination_lat:        "-31.420083",
          destination_lng:        "-64.188776",
          pickup_radius_km:       50,
          dropoff_radius_km:      50,
          price_per_km:           1500.0,
          max_km:                 1200,
          available_from:         4.days.from_now.iso8601,
          available_to:           8.days.from_now.iso8601
        }
      }
      expect(response).to have_http_status(:created)
    end

    it "blocks reactivating a window that overlaps with an active window" do
      inactive = create(:transport_window, vehicle: vehicle, active: false,
                        available_from: 2.days.from_now, available_to: 8.days.from_now)
      create(:transport_window, vehicle: vehicle, active: true,
             available_from: 5.days.from_now, available_to: 12.days.from_now)

      patch "/api/carriers/me/transport_windows/#{inactive.id}",
            params: { transport_window: { active: true } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ===========================================================================
  # Swagger / OpenAPI documentation (rswag path blocks)
  # ===========================================================================

  path "/api/carriers/me/transport_windows" do
    get("list my transport windows") do
      tags "Transport Windows"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response(200, "ok — paginated array of TransportWindow") do
        schema type: :array, items: { "$ref" => "#/components/schemas/TransportWindow" }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

        before do
          create(:transport_window, vehicle: vehicle,
                 available_from: 2.days.from_now, available_to: 5.days.from_now)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to be_an(Array)
          expect(body.first).to include("id", "origin_locality", "origin_admin_area", "vehicle")
        end
      end

      response(401, "missing or invalid token") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "" }
        before { sign_out user }
        run_test!
      end
    end

    post("create a transport window") do
      tags "Transport Windows"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :payload, in: :body, schema: {
        type: :object,
        required: %w[transport_window],
        properties: {
          transport_window: {
            type: :object,
            required: %w[vehicle_id origin_address origin_locality origin_admin_area
                         origin_lat origin_lng pickup_radius_km
                         price_per_km max_km available_from available_to],
            properties: {
              vehicle_id:             { type: :integer },
              origin_address:         { type: :string },
              origin_locality:        { type: :string },
              origin_admin_area:      { type: :string },
              origin_lat:             { type: :number },
              origin_lng:             { type: :number },
              destination_address:    { type: :string, nullable: true },
              destination_locality:   { type: :string, nullable: true },
              destination_admin_area: { type: :string, nullable: true },
              destination_lat:        { type: :number, nullable: true },
              destination_lng:        { type: :number, nullable: true },
              pickup_radius_km:       { type: :integer },
              dropoff_radius_km:      { type: :integer, nullable: true },
              price_per_km:           { type: :number },
              max_km:                 { type: :integer },
              available_from:         { type: :string, format: "date-time" },
              available_to:           { type: :string, format: "date-time" }
            }
          }
        }
      }

      response(201, "created") do
        schema "$ref" => "#/components/schemas/TransportWindow"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:payload) do
          {
            transport_window: {
              vehicle_id:             vehicle.id,
              origin_address:         "Av. Corrientes 1234, CABA",
              origin_locality:        "CABA",
              origin_admin_area:      "Ciudad Autónoma de Buenos Aires",
              destination_address:    "Av. Colón 500, Córdoba",
              destination_locality:   "Córdoba",
              destination_admin_area: "Córdoba",
              origin_lat:             "-34.603722",
              origin_lng:             "-58.381592",
              destination_lat:        "-31.420083",
              destination_lng:        "-64.188776",
              pickup_radius_km:       50,
              dropoff_radius_km:      50,
              price_per_km:           1500.0,
              max_km:                 1200,
              available_from:         2.days.from_now.iso8601,
              available_to:           10.days.from_now.iso8601
            }
          }
        end
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include("origin_locality" => "CABA", "active" => true)
        end
      end

      response(422, "validation error — e.g. available_to before available_from") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:payload) do
          {
            transport_window: {
              vehicle_id:             vehicle.id,
              origin_address:         "Av. Corrientes 1234, CABA",
              origin_locality:        "CABA",
              origin_admin_area:      "Ciudad Autónoma de Buenos Aires",
              destination_address:    "Av. Colón 500, Córdoba",
              destination_locality:   "Córdoba",
              destination_admin_area: "Córdoba",
              origin_lat:             "-34.603722",
              origin_lng:             "-58.381592",
              destination_lat:        "-31.420083",
              destination_lng:        "-64.188776",
              pickup_radius_km:       50,
              dropoff_radius_km:      50,
              price_per_km:           1500.0,
              max_km:                 1200,
              available_from:         10.days.from_now.iso8601,
              available_to:           2.days.from_now.iso8601
            }
          }
        end
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
        end
      end

      response(401, "missing or invalid token") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "" }
        let(:payload) { {} }
        before { sign_out user }
        run_test!
      end
    end
  end

  path "/api/carriers/me/transport_windows/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get("fetch a single transport window") do
      tags "Transport Windows"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response(200, "ok") do
        schema "$ref" => "#/components/schemas/TransportWindow"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:tw) { create(:transport_window, vehicle: vehicle) }
        let(:id) { tw.id }
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["id"]).to eq(tw.id)
          expect(body["vehicle"]).to include("id" => vehicle.id)
        end
      end

      response(404, "not found — window belongs to another carrier") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:foreign) { create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier)) }
        let(:id) { foreign.id }
        run_test!
      end

      response(401, "missing or invalid token") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "" }
        let(:id) { 0 }
        before { sign_out user }
        run_test!
      end
    end

    patch("update a transport window") do
      tags "Transport Windows"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          transport_window: {
            type: :object,
            properties: {
              origin_address:         { type: :string },
              origin_locality:        { type: :string },
              origin_admin_area:      { type: :string },
              destination_address:    { type: :string, nullable: true },
              destination_locality:   { type: :string, nullable: true },
              destination_admin_area: { type: :string, nullable: true },
              pickup_radius_km:       { type: :integer },
              dropoff_radius_km:      { type: :integer, nullable: true },
              price_per_km:           { type: :number },
              max_km:                 { type: :integer },
              available_from:         { type: :string, format: "date-time" },
              available_to:           { type: :string, format: "date-time" },
              active:                 { type: :boolean }
            }
          }
        }
      }

      response(200, "ok — returns updated window") do
        schema "$ref" => "#/components/schemas/TransportWindow"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:tw) { create(:transport_window, vehicle: vehicle) }
        let(:id) { tw.id }
        let(:payload) { { transport_window: { origin_locality: "Rosario" } } }
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["origin_locality"]).to eq("Rosario")
        end
      end

      response(422, "validation error — e.g. reactivating an overlapping window") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let!(:inactive) do
          create(:transport_window, vehicle: vehicle, active: false,
                 available_from: 2.days.from_now, available_to: 8.days.from_now)
        end
        let!(:_blocker) do
          create(:transport_window, vehicle: vehicle, active: true,
                 available_from: 5.days.from_now, available_to: 12.days.from_now)
        end
        let(:id) { inactive.id }
        let(:payload) { { transport_window: { active: true } } }
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
        end
      end

      response(404, "not found — window belongs to another carrier") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:foreign) { create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier)) }
        let(:id) { foreign.id }
        let(:payload) { { transport_window: { origin_locality: "hijack" } } }
        run_test!
      end

      response(401, "missing or invalid token") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "" }
        let(:id) { 0 }
        let(:payload) { {} }
        before { sign_out user }
        run_test!
      end
    end

    delete("delete a transport window") do
      tags "Transport Windows"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response(204, "no content") do
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:tw) { create(:transport_window, vehicle: vehicle) }
        let(:id) { tw.id }
        run_test!
      end

      response(404, "not found — window belongs to another carrier") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:foreign) { create(:transport_window, vehicle: create(:vehicle, carrier: other_user.carrier)) }
        let(:id) { foreign.id }
        run_test!
      end

      response(401, "missing or invalid token") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "" }
        let(:id) { 0 }
        before { sign_out user }
        run_test!
      end
    end
  end
end
