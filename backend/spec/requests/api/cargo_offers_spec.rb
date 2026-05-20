# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::CargoOffers", type: :request do
  path "/api/cargo_offers" do
    get("list cargo offers for the authenticated shipper or carrier") do
      tags "Cargo Offers"
      produces "application/json"
      security [ bearer_auth: [] ]

      let(:shipper_user)  { create(:user, :with_shipper) }
      let(:carrier_user)  { create(:user, :with_carrier) }
      let(:other_shipper) { create(:user, :with_shipper) }
      let(:Authorization) { "Bearer #{jwt_for(shipper_user)}" }

      let(:vehicle) { create(:vehicle, carrier: carrier_user.carrier) }
      let(:window_a) do
        create(:transport_window, vehicle: vehicle,
               available_from: 2.days.from_now, available_to: 10.days.from_now)
      end
      let(:window_b) do
        create(:transport_window, vehicle: vehicle,
               available_from: 12.days.from_now, available_to: 20.days.from_now)
      end

      let!(:my_offer) do
        cargo = create(:cargo, shipper: shipper_user.shipper)
        create(:cargo_offer, cargo: cargo, carrier: carrier_user.carrier, transport_window: window_a)
      end

      let!(:other_offer) do
        cargo = create(:cargo, shipper: other_shipper.shipper,
                       pickup_window_start: 13.days.from_now, pickup_window_end: 15.days.from_now)
        create(:cargo_offer, cargo: cargo, carrier: carrier_user.carrier, transport_window: window_b)
      end

      response(200, "shipper sees only their own offers with cargo embedded") do
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to be_an(Array)
          expect(body.map { |co| co["id"] }).to contain_exactly(my_offer.id)
          expect(body.first["cargo"]).to include(
            "pickup_address", "delivery_address", "pickup_window_start",
            "pickup_window_end", "cargo_description"
          )
        end
      end

      response(200, "carrier sees only offers directed at them") do
        let(:Authorization) { "Bearer #{jwt_for(carrier_user)}" }

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body.map { |co| co["id"] }
          expect(ids).to include(my_offer.id, other_offer.id)
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

    post("bid an existing cargo against a transport window (US7 — Shipper creates offer)") do
      tags "Cargo Offers"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          cargo_offer: {
            type: :object,
            required: %w[cargo_id transport_window_id estimated_km],
            properties: {
              cargo_id:            { type: :integer },
              transport_window_id: { type: :integer },
              estimated_km:        { type: :string }
            }
          }
        },
        required: %w[cargo_offer]
      }

      # ── helpers ──────────────────────────────────────────────────────────────

      let(:shipper_user)  { create(:user, :with_shipper) }
      let(:other_shipper) { create(:user, :with_shipper) }
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

      let(:cargo) do
        create(:cargo, shipper: shipper_user.shipper, weight_kg: 1500,
               pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
      end

      let(:valid_payload) do
        {
          cargo_offer: {
            cargo_id:            cargo.id,
            transport_window_id: window.id,
            estimated_km:        "700"
          }
        }
      end

      # ── 201 happy path ────────────────────────────────────────────────────────

      response(201, "created — shipper bids their cargo, no extra Cargo created") do
        let(:payload) { valid_payload }

        before { cargo } # materialise the cargo before counting

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["status"]).to eq("pending")
          expect(body["currency"]).to eq("ARS")
          expect(body["amount_cents"]).to be > 0
          expect(body["cargo_id"]).to eq(cargo.id)
          expect(body["carrier_id"]).to eq(carrier_user.carrier.id)
          expect(body["transport_window_id"]).to eq(window.id)
          expect(body["expires_at"]).to be_present
        end
      end

      response(201, "does not create an extra Cargo row") do
        let(:payload) { valid_payload }

        run_test! do
          # cargo is created by the `valid_payload` let; the action must not add another.
          expect(Cargo.count).to eq(1)
          expect(CargoOffer.count).to eq(1)
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

      # ── 403 shipper bids on a cargo they do not own ──────────────────────────

      response(403, "shipper cannot bid on another shipper's cargo") do
        let(:foreign_cargo) do
          create(:cargo, shipper: other_shipper.shipper,
                 pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
        end
        let(:payload) do
          valid_payload.deep_merge(cargo_offer: { cargo_id: foreign_cargo.id })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("forbidden")
        end
      end

      # ── 404 unknown cargo_id ──────────────────────────────────────────────────

      response(404, "cargo not found") do
        let(:payload) do
          valid_payload.deep_merge(cargo_offer: { cargo_id: 0 })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("not_found")
        end
      end

      # ── 404 inactive window ───────────────────────────────────────────────────

      response(404, "transport window not found or inactive") do
        let(:inactive_window) do
          other_vehicle = create(:vehicle, max_load_kg: 5000, carrier: carrier_user.carrier)
          create(:transport_window, vehicle: other_vehicle, active: false,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let(:payload) do
          valid_payload.deep_merge(cargo_offer: { transport_window_id: inactive_window.id })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("not_found")
        end
      end

      # ── 422 pickup window does not overlap ────────────────────────────────────

      response(422, "cargo pickup window does not overlap the transport window") do
        let(:cargo) do
          create(:cargo, shipper: shipper_user.shipper, weight_kg: 1500,
                 pickup_window_start: 30.days.from_now, pickup_window_end: 32.days.from_now)
        end
        let(:payload) { valid_payload }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "pickup_window")).to be_present
        end
      end

      # ── 422 weight exceeds vehicle capacity ───────────────────────────────────

      response(422, "cargo weight exceeds vehicle max_load_kg") do
        let(:cargo) do
          create(:cargo, shipper: shipper_user.shipper, weight_kg: 9999,
                 pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
        end
        let(:payload) { valid_payload }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "weight_kg")).to be_present
        end
      end

      # ── 201 null cargo volume is unconstrained ────────────────────────────────

      response(201, "cargo without volume accepts any vehicle") do
        let(:cargo) do
          create(:cargo, shipper: shipper_user.shipper, weight_kg: 1500, volume_cm3: nil,
                 pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
        end
        let(:payload) { valid_payload }

        run_test! do |response|
          expect(response.status).to eq(201)
          body = JSON.parse(response.body)
          expect(body["status"]).to eq("pending")
        end
      end

      # ── 422 estimated_km = 0 ──────────────────────────────────────────────────

      response(422, "estimated_km must be greater than zero") do
        let(:payload) do
          valid_payload.deep_merge(cargo_offer: { estimated_km: "0" })
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "estimated_km")).to be_present
        end
      end

      # ── 422 window already has a pending offer (window-lock) ──────────────────

      response(422, "transport window already has a pending offer") do
        let(:other_cargo) do
          create(:cargo, shipper: other_shipper.shipper,
                 pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
        end
        let!(:existing_offer) do
          create(:cargo_offer, :pending, cargo: other_cargo,
                 carrier: carrier_user.carrier, transport_window: window)
        end
        let(:payload) { valid_payload }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "transport_window")).to be_present
        end
      end
    end
  end
end
