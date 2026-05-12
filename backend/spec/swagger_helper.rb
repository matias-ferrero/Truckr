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
          }
        }
      }
    }
  }
end
