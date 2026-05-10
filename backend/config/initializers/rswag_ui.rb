# frozen_string_literal: true

# rswag-ui: mounts Swagger UI at /api-docs and points at the generated spec.
Rswag::Ui.configure do |c|
  c.openapi_endpoint "/api-docs/v1/swagger.yaml", "Truckr API V1"
end
