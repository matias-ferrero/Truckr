# frozen_string_literal: true

# Alba serializer for Shipper — full variant powering the public profile page
# (US54 — GET /api/shippers/:id). Inherits identity + review headline numbers
# (rating_avg, reviews_count) from ShipperResource and layers on timestamps.
#
# Symmetric to CarrierDetailResource. The individual reviews are NOT embedded
# here — they come from the paginated GET /api/shippers/:id/reviews endpoint
# (AC3) so the profile payload stays small and the list can page independently.
class ShipperDetailResource < ShipperResource
  attributes :created_at, :updated_at
end
