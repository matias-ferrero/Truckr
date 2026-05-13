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
  end

  # ---------------------------------------------------------------------------
  # POST /api/carriers/me/transport_windows
  # ---------------------------------------------------------------------------
  describe "POST /api/carriers/me/transport_windows" do
    let(:valid_params) do
      {
        transport_window: {
          vehicle_id:       vehicle.id,
          origin_zone:      "Buenos Aires",
          destination_zone: "Córdoba",
          price_per_km:     1500.0,
          max_km:           1200,
          available_from:   2.days.from_now.iso8601,
          available_to:     10.days.from_now.iso8601
        }
      }
    end

    it "creates a window and returns 201" do
      post "/api/carriers/me/transport_windows", params: valid_params
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include(
        "origin_zone"      => "Buenos Aires",
        "destination_zone" => "Córdoba",
        "active"           => true
      )
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
  end

  # ---------------------------------------------------------------------------
  # PATCH /api/carriers/me/transport_windows/:id
  # ---------------------------------------------------------------------------
  describe "PATCH /api/carriers/me/transport_windows/:id" do
    let(:window) { create(:transport_window, vehicle: vehicle) }

    it "updates an owned window" do
      patch "/api/carriers/me/transport_windows/#{window.id}",
            params: { transport_window: { origin_zone: "Rosario" } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["origin_zone"]).to eq("Rosario")
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
            params: { transport_window: { origin_zone: "hijack" } }
      expect(response).to have_http_status(:not_found)
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
          vehicle_id:       vehicle.id,
          origin_zone:      "Buenos Aires",
          destination_zone: "Córdoba",
          price_per_km:     1500.0,
          max_km:           1200,
          available_from:   4.days.from_now.iso8601,
          available_to:     8.days.from_now.iso8601
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
          expect(body.first).to include("id", "origin_zone", "destination_zone", "vehicle")
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
            required: %w[vehicle_id origin_zone destination_zone price_per_km max_km available_from available_to],
            properties: {
              vehicle_id:       { type: :integer },
              origin_zone:      { type: :string },
              destination_zone: { type: :string },
              price_per_km:     { type: :number },
              max_km:           { type: :integer },
              available_from:   { type: :string, format: "date-time" },
              available_to:     { type: :string, format: "date-time" }
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
              vehicle_id:       vehicle.id,
              origin_zone:      "Buenos Aires",
              destination_zone: "Córdoba",
              price_per_km:     1500.0,
              max_km:           1200,
              available_from:   2.days.from_now.iso8601,
              available_to:     10.days.from_now.iso8601
            }
          }
        end
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include("origin_zone" => "Buenos Aires", "active" => true)
        end
      end

      response(422, "validation error — e.g. available_to before available_from") do
        schema "$ref" => "#/components/schemas/ErrorEnvelope"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:payload) do
          {
            transport_window: {
              vehicle_id:       vehicle.id,
              origin_zone:      "Buenos Aires",
              destination_zone: "Córdoba",
              price_per_km:     1500.0,
              max_km:           1200,
              available_from:   10.days.from_now.iso8601,
              available_to:     2.days.from_now.iso8601
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
              origin_zone:      { type: :string },
              destination_zone: { type: :string },
              price_per_km:     { type: :number },
              max_km:           { type: :integer },
              available_from:   { type: :string, format: "date-time" },
              available_to:     { type: :string, format: "date-time" },
              active:           { type: :boolean }
            }
          }
        }
      }

      response(200, "ok — returns updated window") do
        schema "$ref" => "#/components/schemas/TransportWindow"
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let(:tw) { create(:transport_window, vehicle: vehicle) }
        let(:id) { tw.id }
        let(:payload) { { transport_window: { origin_zone: "Rosario" } } }
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["origin_zone"]).to eq("Rosario")
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
        let(:payload) { { transport_window: { origin_zone: "hijack" } } }
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
