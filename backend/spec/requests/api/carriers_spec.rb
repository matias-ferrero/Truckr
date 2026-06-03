# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Carriers (public)", type: :request do
  let(:carrier) { create(:user, :with_carrier).carrier }

  path "/api/carriers/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get("show a carrier's public profile (US6)") do
      tags "Carriers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/CarrierDetail"

        let(:id) { carrier.id }

        before do
          carrier.update!(
            legal_name:  "Transportes Andinos SRL",
            base_city:   "Mendoza",
            province:    "Mendoza",
            description: "Flota especializada en cargas frágiles."
          )
          12.times { create(:review, :shipper_authored, carrier: carrier, rating: 5) }
          vehicle = create(:vehicle, carrier: carrier)
          create(:transport_window, vehicle: vehicle, active: true,
                                    available_from: 1.day.from_now,
                                    available_to:   10.days.from_now)
          create(:transport_window, vehicle: vehicle, active: false,
                                    available_from: 30.days.from_now,
                                    available_to:   45.days.from_now)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["id"]).to eq(carrier.id)
          expect(body["legal_name"]).to eq("Transportes Andinos SRL")
          expect(body["description"]).to eq("Flota especializada en cargas frágiles.")
          expect(body["rating_avg"]).to eq("5.0")
          expect(body["reviews_count"]).to eq(12)
          expect(body["vehicles"].size).to eq(1)
          expect(body["vehicles"].first.keys).to include("plate", "photos", "description")
          # Only the active window is exposed.
          expect(body["transport_windows"].size).to eq(1)
          expect(body["transport_windows"].first["active"]).to be true
        end
      end

      response(200, "without vehicles or windows still serialises") do
        let(:id) { carrier.id }
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["vehicles"]).to eq([])
          expect(body["transport_windows"]).to eq([])
        end
      end

      response(404, "carrier not found") do
        let(:id) { 999_999 }
        run_test!
      end
    end
  end
end
