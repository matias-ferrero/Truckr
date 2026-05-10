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
          cookie_auth: { type: :apiKey, in: :cookie, name: "_truckr_session" }
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
          }
        }
      }
    }
  }
end
