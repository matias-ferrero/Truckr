# frozen_string_literal: true

# rswag-api: serves the generated swagger.yaml under /api-docs/v1/swagger.yaml.
Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.join("swagger").to_s
end
