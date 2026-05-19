# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Quotes", type: :request do
  path "/api/quotes" do
    get("list quotes for the authenticated shipper or carrier") do
      tags "Quotes"
      produces "application/json"
      security [ bearer_auth: [] ]

      let(:shipper_user)  { create(:user, :with_shipper) }
      let(:carrier_user)  { create(:user, :with_carrier) }
      let(:other_shipper) { create(:user, :with_shipper) }
      let(:Authorization) { "Bearer #{jwt_for(shipper_user)}" }

      let(:vehicle) { create(:vehicle, carrier: carrier_user.carrier) }
      let(:window)  do
        create(:transport_window, vehicle: vehicle,
               available_from: 2.days.from_now, available_to: 10.days.from_now)
      end

      let!(:my_quote) do
        offer = create(:cargo_offer, shipper: shipper_user.shipper)
        create(:quote, cargo_offer: offer, carrier: carrier_user.carrier, transport_window: window)
      end

      let!(:other_quote) do
        offer = create(:cargo_offer, shipper: other_shipper.shipper)
        create(:quote, cargo_offer: offer, carrier: carrier_user.carrier, transport_window: window)
      end

      response(200, "shipper sees only their own quotes with cargo_offer embedded") do
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to be_an(Array)
          expect(body.map { |q| q["id"] }).to contain_exactly(my_quote.id)
          expect(body.first["cargo_offer"]).to include(
            "pickup_address", "delivery_address", "pickup_date", "cargo_description"
          )
        end
      end

      response(200, "carrier sees only quotes directed at them") do
        let(:Authorization) { "Bearer #{jwt_for(carrier_user)}" }

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body.map { |q| q["id"] }
          expect(ids).to include(my_quote.id, other_quote.id)
        end
      end

      response(401, "unauthenticated") do
        let(:Authorization) { nil }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unauthorized")
        end
      end
    end

    post("create a cargo offer + quote (US7 — Shipper creates offer)") do
      tags "Quotes"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          quote: {
            type: :object,
            required: %w[transport_window_id pickup_address delivery_address
                         pickup_date cargo_description weight_kg volume_cm3
                         declared_value_cents estimated_km],
            properties: {
              transport_window_id:  { type: :integer },
              pickup_address:       { type: :string },
              delivery_address:     { type: :string },
              pickup_date:          { type: :string, format: "date" },
              cargo_description:    { type: :string },
              weight_kg:            { type: :string },
              volume_cm3:           { type: :string },
              declared_value_cents: { type: :string },
              estimated_km:         { type: :string }
            }
          }
        },
        required: %w[quote]
      }

      # ── helpers ──────────────────────────────────────────────────────────────

      let(:shipper_user)  { create(:user, :with_shipper) }
      let(:carrier_user)  { create(:user, :with_carrier) }
      let(:Authorization) { "Bearer #{jwt_for(shipper_user)}" }

      let(:vehicle) { create(:vehicle, max_load_kg: 5000, carrier: carrier_user.carrier) }
      let(:window) do
        create(
          :transport_window,
          vehicle:        vehicle,
          price_per_km:   1500.0,
          max_km:         1000,
          available_from: 2.days.from_now,
          available_to:   10.days.from_now
        )
      end

      let(:valid_payload) do
        {
          quote: {
            transport_window_id:  window.id,
            pickup_address:       "Av. Corrientes 1234, CABA",
            delivery_address:     "Av. Colón 500, Córdoba",
            pickup_date:          3.days.from_now.to_date.iso8601,
            cargo_description:    "Pallets de electrodomésticos",
            weight_kg:            "1500",
            volume_cm3:           "3000000",
            declared_value_cents: "500000",
            estimated_km:         "700"
          }
        }
      end

      # ── 201 happy path ────────────────────────────────────────────────────────

      response(201, "created — shipper offer accepted") do
        let(:payload) { valid_payload }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["status"]).to eq("pending")
          expect(body["currency"]).to eq("ARS")
          expect(body["amount_cents"]).to be > 0
          expect(body["carrier_id"]).to eq(carrier_user.carrier.id)
          expect(body["transport_window_id"]).to eq(window.id)
          expect(body["expires_at"]).to be_present

          # Atomically created CargoOffer
          expect(CargoOffer.count).to eq(1)
          expect(Quote.count).to eq(1)
        end
      end

      # ── 401 unauthenticated ───────────────────────────────────────────────────

      response(401, "unauthenticated") do
        let(:Authorization) { nil }
        let(:payload) { valid_payload }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unauthorized")
        end
      end

      # ── 403 carrier cannot create offers ─────────────────────────────────────

      response(403, "carrier role cannot create offers") do
        let(:Authorization) { "Bearer #{jwt_for(carrier_user)}" }
        let(:payload) { valid_payload }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("forbidden")
        end
      end

      # ── 404 inactive window ───────────────────────────────────────────────────

      response(404, "transport window not found or inactive") do
        let!(:inactive_window) do
          create(:transport_window, vehicle: vehicle, active: false,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let(:payload) do
          valid_payload.deep_merge(quote: { transport_window_id: inactive_window.id })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("not_found")
        end
      end

      # ── 422 pickup_date out of window range ───────────────────────────────────

      response(422, "pickup_date before window opens") do
        let(:payload) do
          valid_payload.deep_merge(quote: { pickup_date: 1.day.from_now.to_date.iso8601 })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "pickup_date")).to be_present
        end
      end

      # ── 422 malformed pickup_date ─────────────────────────────────────────────

      response(422, "malformed pickup_date is rejected with field-level error") do
        let(:payload) do
          valid_payload.deep_merge(quote: { pickup_date: "not-a-date" })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "pickup_date")).to be_present
        end
      end

      # ── 422 weight exceeds vehicle capacity ───────────────────────────────────

      response(422, "cargo weight exceeds vehicle max_load_kg") do
        let(:payload) do
          valid_payload.deep_merge(quote: { weight_kg: "9999" })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "weight_kg")).to be_present
        end
      end

      # ── 422 volume exceeds vehicle capacity ───────────────────────────────────

      response(422, "cargo volume exceeds vehicle volume_cm3") do
        let(:vehicle_with_dims) do
          create(:vehicle,
                 max_load_kg: 5000,
                 length_cm: 500, width_cm: 200, height_cm: 200,
                 carrier: carrier_user.carrier)
        end
        let(:window_with_dims) do
          create(:transport_window, vehicle: vehicle_with_dims,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let(:payload) do
          valid_payload.deep_merge(quote: {
            transport_window_id: window_with_dims.id,
            volume_cm3: "999999999"
          })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "volume_cm3")).to be_present
        end
      end

      # ── 201 null vehicle volume is unconstrained ──────────────────────────────

      response(201, "vehicle without registered volume accepts any cargo volume") do
        let(:vehicle_no_dims) do
          create(:vehicle, max_load_kg: 5000, length_cm: nil, width_cm: nil, height_cm: nil,
                 carrier: carrier_user.carrier)
        end
        let(:window_no_dims) do
          create(:transport_window, vehicle: vehicle_no_dims,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let(:payload) do
          valid_payload.deep_merge(quote: {
            transport_window_id: window_no_dims.id,
            volume_cm3: "999999999"
          })
        end

        run_test! do |response|
          expect(response.status).to eq(201)
          body = JSON.parse(response.body)
          expect(body["status"]).to eq("pending")
        end
      end

      # ── 422 estimated_km = 0 ──────────────────────────────────────────────────

      response(422, "estimated_km must be greater than zero") do
        let(:payload) do
          valid_payload.deep_merge(quote: { estimated_km: "0" })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "estimated_km")).to be_present
        end
      end

      # ── 422 model validation (blank pickup_address) ────────────────────────────

      response(422, "model validation failure — blank pickup_address") do
        let(:payload) do
          valid_payload.deep_merge(quote: { pickup_address: "" })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details")).to be_present
        end
      end
    end
  end
end
