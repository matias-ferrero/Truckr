# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Cargos", type: :request do
  let(:shipper_user)  { create(:user, :with_shipper) }
  let(:other_shipper) { create(:user, :with_shipper) }
  let(:carrier_user)  { create(:user, :with_carrier) }
  let(:Authorization) { "Bearer #{jwt_for(shipper_user)}" }

  let(:valid_attrs) do
    {
      cargo_description:    "Pallets de electrodomésticos",
      pickup_address:       "Av. Corrientes 1234, CABA",
      pickup_locality:      "CABA",
      pickup_admin_area:    "Ciudad Autónoma de Buenos Aires",
      delivery_address:     "Av. Colón 500, Córdoba",
      delivery_locality:    "Córdoba",
      delivery_admin_area:  "Córdoba",
      pickup_lat:           "-34.603722",
      pickup_lng:           "-58.381592",
      delivery_lat:         "-31.420083",
      delivery_lng:         "-64.188776",
      pickup_window_start:  3.days.from_now.iso8601,
      pickup_window_end:    5.days.from_now.iso8601,
      weight_kg:            "1500",
      volume_cm3:           "4000000",
      declared_value_cents: "5000000"
    }
  end

  path "/api/cargos" do
    get("list the shipper's cargos") do
      tags "Cargos"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :status, in: :query, type: :string, required: false

      let(:status) { nil }
      let!(:my_open)      { create(:cargo, shipper: shipper_user.shipper) }
      let!(:my_cancelled) { create(:cargo, :cancelled, shipper: shipper_user.shipper) }
      let!(:foreign)      { create(:cargo, shipper: other_shipper.shipper) }

      response(200, "lists only the authenticated shipper's cargos") do
        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body.map { |c| c["id"] }
          expect(ids).to contain_exactly(my_open.id, my_cancelled.id)
        end
      end

      response(200, "filters by status") do
        let(:status) { "cancelled" }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.map { |c| c["id"] }).to contain_exactly(my_cancelled.id)
        end
      end

      response(401, "unauthenticated") do
        let(:Authorization) { nil }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("unauthorized")
        end
      end

      response(403, "non-shipper is forbidden") do
        let(:Authorization) { "Bearer #{jwt_for(carrier_user)}" }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("forbidden")
        end
      end
    end

    post("publish a cargo") do
      tags "Cargos"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: { cargo: { type: :object } },
        required: %w[cargo]
      }

      response(201, "created — status open, body includes matches") do
        let(:payload) { { cargo: valid_attrs } }

        # A zone- and date-compatible window so `matches` is non-empty.
        before do
          vehicle = create(:vehicle, max_load_kg: 5000, carrier: carrier_user.carrier)
          create(:transport_window, vehicle: vehicle,
                 origin_lat: -34.603722, origin_lng: -58.381592,
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["status"]).to eq("open")
          expect(body["shipper_id"]).to eq(shipper_user.shipper.id)
          expect(body["editable"]).to be(true)
          expect(body["matches"]).to be_an(Array)
          expect(body["matches"].size).to eq(1)
          expect(body["distance_km"]).to match(/\A\d+\.\d+\z/)
        end
      end

      response(422, "weight_kg must be positive") do
        let(:payload) { { cargo: valid_attrs.merge(weight_kg: "0") } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "weight_kg")).to be_present
        end
      end

      response(422, "pickup_window_end must be after start") do
        let(:payload) do
          { cargo: valid_attrs.merge(pickup_window_end: 1.day.from_now.iso8601) }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "pickup_window_end")).to be_present
        end
      end

      response(422, "missing cargo params") do
        let(:payload) { {} }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("unprocessable")
        end
      end

      response(422, "missing delivery_lng → 422 with details on the field") do
        let(:payload) { { cargo: valid_attrs.except(:delivery_lng) } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "delivery_lng")).to be_present
        end
      end

      response(422, "lat outside [-90, 90] → 422") do
        let(:payload) { { cargo: valid_attrs.merge(pickup_lat: "91.0") } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "details", "pickup_lat")).to be_present
        end
      end

      response(422, "Distance Matrix API unavailable → 422 with base error") do
        let(:payload) { { cargo: valid_attrs } }

        before do
          allow(GoogleMaps::DistanceService).to receive(:fetch_km).and_return(nil)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "base")).to be_present
        end
      end
    end
  end

  path "/api/cargos/{id}" do
    parameter name: :id, in: :path, type: :integer

    get("show a cargo with its nested offers") do
      tags "Cargos"
      produces "application/json"
      security [ bearer_auth: [] ]

      let(:cargo) { create(:cargo, shipper: shipper_user.shipper) }
      let(:id)    { cargo.id }

      response(200, "returns the cargo with nested offers including carrier summary") do
        before { create(:cargo_offer, :pending, cargo: cargo) }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["id"]).to eq(cargo.id)
          expect(body["cargo_offers"].size).to eq(1)
          expect(body["pending_offers_count"]).to eq(1)
          offer = body["cargo_offers"].first
          expect(offer["carrier"]).to include("id", "display_name")
          expect(offer["carrier"]["display_name"]).to be_present
        end
      end

      response(200, "includes pickup/delivery coordinates in the payload") do
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["pickup_lat"]).to   eq(cargo.pickup_lat.to_s)
          expect(body["pickup_lng"]).to   eq(cargo.pickup_lng.to_s)
          expect(body["delivery_lat"]).to eq(cargo.delivery_lat.to_s)
          expect(body["delivery_lng"]).to eq(cargo.delivery_lng.to_s)
        end
      end

      response(403, "another shipper's cargo is forbidden") do
        let(:id) { create(:cargo, shipper: other_shipper.shipper).id }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("forbidden")
        end
      end

      response(404, "unknown cargo") do
        let(:id) { 0 }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("not_found")
        end
      end
    end

    patch("update a cargo") do
      tags "Cargos"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object, properties: { cargo: { type: :object } }, required: %w[cargo]
      }

      let(:cargo) { create(:cargo, shipper: shipper_user.shipper) }
      let(:id)    { cargo.id }

      response(200, "updates an editable cargo") do
        let(:payload) { { cargo: { cargo_description: "Carga actualizada" } } }

        run_test! do |response|
          expect(JSON.parse(response.body)["cargo_description"]).to eq("Carga actualizada")
        end
      end

      response(422, "blocked when an accepted offer exists") do
        let(:payload) { { cargo: { cargo_description: "Carga actualizada" } } }

        before { create(:cargo_offer, :accepted, cargo: cargo) }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("cargo_locked")
        end
      end
    end

    delete("soft-cancel a cargo and expire its pending offers") do
      tags "Cargos"
      produces "application/json"
      security [ bearer_auth: [] ]

      let(:cargo) { create(:cargo, shipper: shipper_user.shipper) }
      let(:id)    { cargo.id }

      response(204, "soft-cancels the cargo and expires pending sibling offers") do
        let!(:pending_offer) { create(:cargo_offer, :pending, cargo: cargo) }

        run_test! do
          expect(cargo.reload.status).to eq("cancelled")
          expect(pending_offer.reload.status).to eq("expired")
        end
      end

      response(422, "blocked when an accepted offer exists") do
        before { create(:cargo_offer, :accepted, cargo: cargo) }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("cargo_locked")
        end
      end
    end
  end

  path "/api/cargos/{id}/matches" do
    parameter name: :id, in: :path, type: :integer

    get("list address-driven matching transport windows for a cargo") do
      tags "Cargos"
      produces "application/json"
      security [ bearer_auth: [] ]

      let(:cargo) do
        create(:cargo, shipper: shipper_user.shipper,
               pickup_lat: -34.603722, pickup_lng: -58.381592,
               delivery_lat: -31.420083, delivery_lng: -64.188776,
               weight_kg: 1500,
               pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now)
      end
      let(:id) { cargo.id }

      # A fresh vehicle per window — TransportWindow#no_vehicle_overlap rejects
      # two overlapping active windows on the same vehicle.
      def big_vehicle
        create(:vehicle, max_load_kg: 5000, carrier: carrier_user.carrier)
      end

      response(200, "returns matching windows; excludes inactive, contended and incompatible ones") do
        let!(:match) do
          create(:transport_window, vehicle: big_vehicle,
                 origin_lat: -34.603722, origin_lng: -58.381592,
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let!(:inactive) do
          create(:transport_window, vehicle: big_vehicle, active: false,
                 origin_lat: -34.603722, origin_lng: -58.381592,
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let!(:wrong_zone) do
          create(:transport_window, vehicle: big_vehicle,
                 origin_lat: -32.889458, origin_lng: -68.844734, # Mendoza
                 destination_lat: -24.7821, destination_lng: -65.4232, # Salta
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let!(:too_small) do
          tiny = create(:vehicle, max_load_kg: 100, carrier: carrier_user.carrier)
          create(:transport_window, vehicle: tiny,
                 origin_lat: -34.603722, origin_lng: -58.381592,
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let!(:contended) do
          win = create(:transport_window, vehicle: big_vehicle,
                       origin_lat: -34.603722, origin_lng: -58.381592,
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                       available_from: 2.days.from_now, available_to: 10.days.from_now)
          create(:cargo_offer, :pending, transport_window: win,
                 cargo: create(:cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now))
          win
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.map { |w| w["id"] }).to contain_exactly(match.id)
          # No server-side distance_km — Haversine runs on the client against
          # origin_lat / origin_lng, which the frontend needs in the payload.
          expect(body.first).not_to have_key("distance_km")
          expect(body.first).to include("origin_lat", "origin_lng")
          expect(body.first["carrier"]).to include("legal_name", "rating_avg")
        end
      end

      # Cargo Matches v2: the endpoint returns the FULL compatible set in one
      # response — no Pagy page — because the client computes the global
      # "Recomendados" picks (cheapest / best-rated / soonest) over the whole
      # set. 25 windows > the old default page of 20 proves no truncation.
      response(200, "returns the full compatible set unpaginated") do
        let!(:windows) do
          Array.new(25) do
            create(:transport_window, vehicle: big_vehicle,
                   origin_lat: -34.603722, origin_lng: -58.381592,
                   destination_lat: -31.420083, destination_lng: -64.188776,
                   pickup_radius_km: 50, dropoff_radius_km: 50,
                   available_from: 2.days.from_now, available_to: 10.days.from_now)
          end
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.size).to eq(25)
          expect(response.headers).not_to have_key("X-Total-Pages")
        end
      end

      response(403, "another shipper's cargo is forbidden") do
        let(:id) { create(:cargo, shipper: other_shipper.shipper).id }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("error", "code")).to eq("forbidden")
        end
      end

      # Geographic filter — windows whose origin sits farther than their own
      # `pickup_radius_km` from the cargo pickup must be excluded.
      response(200, "excludes windows whose origin is outside their pickup_radius_km") do
        let!(:near) do
          create(:transport_window, vehicle: big_vehicle,
                 origin_lat: -34.603722, origin_lng: -58.381592,
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 origin_lat: -34.603722, origin_lng: -58.381592,
                 pickup_radius_km: 50,
                 available_from: 2.days.from_now, available_to: 10.days.from_now)
        end
        let!(:far) do
          create(:transport_window, vehicle: big_vehicle,
                 origin_lat: -34.603722, origin_lng: -58.381592,
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 origin_lat: -24.7821, origin_lng: -65.4232, # Salta — ~1300 km from CABA
                 pickup_radius_km: 50,
                 available_from: 11.days.from_now, available_to: 19.days.from_now)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.map { |w| w["id"] }).to contain_exactly(near.id)
        end
      end

      # sort=distance must reorder the matches ascending by Haversine distance
      # from the cargo pickup (US5 AC8).
      parameter name: :sort, in: :query, type: :string, required: false
      response(200, "orders matches ascending by distance when sort=distance") do
        let(:sort) { "distance" }
        # Both within their own radius of the CABA cargo, but La Plata is the
        # farther of the two — distance ordering must surface CABA first.
        let!(:la_plata) do
          create(:transport_window, vehicle: big_vehicle,
                 origin_lat: -34.921450, origin_lng: -57.954529, # ~56 km from CABA
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 100, dropoff_radius_km: 50,
                 available_from: 2.days.from_now, available_to: 6.days.from_now)
        end
        let!(:caba) do
          create(:transport_window, vehicle: big_vehicle,
                 origin_lat: -34.603722, origin_lng: -58.381592, # 0 km from CABA
                 destination_lat: -31.420083, destination_lng: -64.188776,
                 pickup_radius_km: 50, dropoff_radius_km: 50,
                 available_from: 3.days.from_now, available_to: 8.days.from_now)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.map { |w| w["id"] }).to eq([ caba.id, la_plata.id ])
        end
      end
    end
  end
end
