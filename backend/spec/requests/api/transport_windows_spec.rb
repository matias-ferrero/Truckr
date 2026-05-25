# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::TransportWindows", type: :request do
  path "/api/transport_windows" do
    parameter name: :origin_province, in: :query, type: :string, required: true
    parameter name: :destination_province, in: :query, type: :string, required: true
    parameter name: :date_from, in: :query, type: :string, required: true
    parameter name: :date_to, in: :query, type: :string, required: true

    get("search carriers by province and date range") do
      tags "Transport Windows"
      produces "application/json"

      response(200, "successful") do
        let(:origin_province) { "buen" }
        let(:destination_province) { "cord" }
        let(:date_from) { "2026-05-12" }
        let(:date_to) { "2026-05-14" }

        before do
          match_carrier = create(:carrier, legal_name: "Fletes del Centro")
          outside_zone_carrier = create(:carrier, legal_name: "Costa Express")

          create(
            :transport_window,
            vehicle: create(:vehicle, carrier: match_carrier),
            origin_province: "Buenos Aires",
            destination_province: "Córdoba",
            available_from: Time.zone.parse("2026-05-11 09:00:00"),
            available_to: Time.zone.parse("2026-05-15 18:00:00"),
            price_per_km: 1999.5
          )

          create(
            :transport_window,
            vehicle: create(:vehicle, carrier: outside_zone_carrier),
            origin_province: "Mar del Plata",
            destination_province: "Bahía Blanca",
            available_from: Time.zone.parse("2026-05-11 09:00:00"),
            available_to: Time.zone.parse("2026-05-15 18:00:00")
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body.size).to eq(1)
          expect(body.first["legal_name"]).to eq("Fletes del Centro")
          expect(body.first.keys).to include("display_name", "transport_windows")
          expect(body.first["transport_windows"].size).to eq(1)
          expect(body.first["transport_windows"].first).to include(
            "origin_province" => "Buenos Aires",
            "destination_province" => "Córdoba"
          )
        end
      end

      response(200, "includes open-destination windows when filtering by destination") do
        let(:origin_province) { "buen" }
        let(:destination_province) { "cord" }
        let(:date_from) { "2026-05-12" }
        let(:date_to) { "2026-05-14" }

        before do
          carrier = create(:carrier, legal_name: "Fletes Abiertos")

          create(
            :transport_window,
            vehicle: create(:vehicle, carrier: carrier),
            origin_province: "Buenos Aires",
            destination_province: "Córdoba",
            available_from: Time.zone.parse("2026-05-11 09:00:00"),
            available_to: Time.zone.parse("2026-05-15 18:00:00")
          )

          create(
            :transport_window,
            :open_destination,
            vehicle: create(:vehicle, carrier: carrier),
            origin_province: "Buenos Aires",
            available_from: Time.zone.parse("2026-05-11 09:00:00"),
            available_to: Time.zone.parse("2026-05-15 18:00:00")
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          windows = body.flat_map { |c| c["transport_windows"] }
          expect(windows.size).to eq(2)
          destinations = windows.map { |w| w["destination_province"] }
          expect(destinations).to include("Córdoba")
          expect(destinations).to include(nil)
        end
      end

      response(422, "missing query params") do
        let(:origin_province) { "Buenos Aires" }
        let(:destination_province) { nil }
        let(:date_from) { "2026-05-12" }
        let(:date_to) { "2026-05-14" }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "destination_province")).to include("is required")
        end
      end

      response(422, "invalid date range") do
        let(:origin_province) { "Buenos Aires" }
        let(:destination_province) { "Córdoba" }
        let(:date_from) { "2026-05-20" }
        let(:date_to) { "2026-05-10" }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details", "date_range")).to include("date_from must be <= date_to")
        end
      end

      response(422, "invalid date format") do
        let(:origin_province) { "Buenos Aires" }
        let(:destination_province) { "Córdoba" }
        let(:date_from) { "not-a-date" }
        let(:date_to) { "2026-05-14" }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.dig("error", "code")).to eq("unprocessable")
          expect(body.dig("error", "details")).to be_present
        end
      end
    end
  end
end
