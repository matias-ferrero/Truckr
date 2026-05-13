# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s
  config.openapi_format = :yaml

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "Truckr API",
        version: "v1",
        description: "Internal HTTP API for the Truckr® marketplace."
      },
      paths: {},
      servers: [
        { url: "http://localhost:3000", description: "Local dev" }
      ],
      components: {
        securitySchemes: {
          # Stateless JWT — see ADR-011. Login/register responses inject the
          # token in the `Authorization` response header; clients echo it
          # back as `Authorization: Bearer <jwt>` on subsequent requests.
          bearer_auth: { type: :http, scheme: :bearer, bearerFormat: "JWT" }
        },
        schemas: {
          ErrorEnvelope: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code:    { type: :string },
                  message: { type: :string }
                }
              }
            },
            required: %w[error]
          },
          Me: {
            type: :object,
            properties: {
              id:          { type: :integer },
              email:       { type: :string },
              full_name:   { type: :string, nullable: true },
              phone:       { type: :string, nullable: true },
              verified_at: { type: :string, format: "date-time", nullable: true },
              roles:       { type: :array, items: { type: :string, enum: %w[carrier shipper] } },
              carrier:     { type: :object, nullable: true },
              shipper:     { type: :object, nullable: true }
            },
            required: %w[id email roles]
          },
          Photo: {
            type: :object,
            properties: {
              id: { type: :integer },
              thumbnail: { type: :string },
              card: { type: :string },
              full: { type: :string }
            }
          },
          Vehicle: {
            type: :object,
            properties: {
              id: { type: :integer },
              make: { type: :string },
              model: { type: :string },
              year: { type: :integer, nullable: true },
              plate: { type: :string },
              vehicle_type: { type: :string },
              max_load_kg: { type: :string },
              length_cm: { type: :integer, nullable: true },
              width_cm: { type: :integer, nullable: true },
              height_cm: { type: :integer, nullable: true },
              volume_cm3: { type: :integer, nullable: true },
              gps_enabled: { type: :boolean },
              description: { type: :string, nullable: true },
              photos: { type: :array, items: { "$ref" => "#/components/schemas/Photo" } }
            }
          },
          VehicleSlim: {
            type: :object,
            properties: {
              id: { type: :integer },
              make: { type: :string },
              model: { type: :string },
              year: { type: :integer, nullable: true },
              plate: { type: :string },
              vehicle_type: { type: :string },
              max_load_kg: { type: :string },
              gps_enabled: { type: :boolean },
              photos: { type: :array, items: { "$ref" => "#/components/schemas/Photo" } }
            }
          },
          VehicleListResponse: {
            type: :array,
            items: { "$ref" => "#/components/schemas/VehicleSlim" }
          },
          TransportWindowVehicle: {
            type: :object,
            properties: {
              id:           { type: :integer },
              make:         { type: :string },
              model:        { type: :string },
              plate:        { type: :string },
              vehicle_type: { type: :string }
            }
          },
          TransportWindow: {
            type: :object,
            properties: {
              id:               { type: :integer },
              vehicle_id:       { type: :integer },
              origin_zone:      { type: :string },
              destination_zone: { type: :string },
              price_per_km:     { type: :string },
              max_km:           { type: :integer },
              available_from:   { type: :string, format: "date-time" },
              available_to:     { type: :string, format: "date-time" },
              active:           { type: :boolean },
              vehicle:          { "$ref" => "#/components/schemas/TransportWindowVehicle" },
              created_at:       { type: :string, format: "date-time" },
              updated_at:       { type: :string, format: "date-time" }
            }
          },
          TransportWindowListResponse: {
            type: :array,
            items: { "$ref" => "#/components/schemas/TransportWindow" }
          },
          CarrierDetail: {
            type: :object,
            properties: {
              id:                  { type: :integer },
              legal_name:          { type: :string, nullable: true },
              tax_id:              { type: :string, nullable: true },
              base_city:           { type: :string, nullable: true },
              province:            { type: :string, nullable: true },
              description:         { type: :string, nullable: true },
              rating_avg:          { type: :string },
              reviews_count:       { type: :integer },
              completed_shipments: { type: :integer },
              vehicles:            { type: :array, items: { "$ref" => "#/components/schemas/Vehicle" } },
              transport_windows:   { type: :array, items: { "$ref" => "#/components/schemas/TransportWindow" } }
            },
            required: %w[id rating_avg reviews_count vehicles transport_windows]
          }
        }
      }
    }
  }
end
