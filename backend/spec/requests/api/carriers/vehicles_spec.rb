# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::Carriers::Vehicles (public)", type: :request do
  let(:carrier) { create(:user, :with_carrier).carrier }

  path "/api/carriers/{carrier_id}/vehicles" do
    parameter name: :carrier_id, in: :path, type: :integer, required: true

    get("list a carrier's fleet (public)") do
      tags "Vehicles"
      produces "application/json"
      parameter name: :page, in: :query, type: :integer, required: false

      response(200, "successful") do
        let(:carrier_id) { carrier.id }
        let(:page) { 1 }

        before do
          create_list(:vehicle, 2, carrier: carrier)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body.size).to eq(2)
          expect(response.headers["X-Total"]).to eq("2")
          expect(body.first.keys).to include("id", "make", "model", "plate")
          # slim variant excludes detail-only fields
          expect(body.first.keys).not_to include("description")
        end
      end

      response(404, "carrier not found") do
        let(:carrier_id) { 999_999 }
        let(:page)       { 1 }
        run_test!
      end
    end
  end

  path "/api/carriers/{carrier_id}/vehicles/{id}" do
    parameter name: :carrier_id, in: :path, type: :integer, required: true
    parameter name: :id,         in: :path, type: :integer, required: true

    get("show a vehicle (public)") do
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        let(:vehicle)    { create(:vehicle, carrier: carrier) }
        let(:carrier_id) { carrier.id }
        let(:id)         { vehicle.id }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["plate"]).to eq(vehicle.plate)
          expect(body.keys).to include("description", "length_cm")
        end
      end
    end
  end
end
