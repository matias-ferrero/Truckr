# frozen_string_literal: true

# Alba serializer for Carrier — full variant powering the public profile page
# (US6 — GET /api/carriers/:id). Inherits the slim attributes from
# `CarrierResource` and layers on description, vehicles (with photos) and the
# active transport_windows.
class CarrierDetailResource < CarrierResource
  attributes :description, :created_at, :updated_at

  many :vehicles, resource: VehicleResource

  # TransportWindowResource doesn't exist on this branch (lands with PR #163);
  # serialise inline until it's available, then switch to `many`.
  attribute :transport_windows do |carrier|
    carrier.active_transport_windows.map do |w|
      {
        id:               w.id,
        vehicle_id:       w.vehicle_id,
        origin_zone:      w.origin_zone,
        destination_zone: w.destination_zone,
        price_per_km:     w.price_per_km.to_s,
        max_km:           w.max_km,
        available_from:   w.available_from&.iso8601,
        available_to:     w.available_to&.iso8601,
        active:           w.active
      }
    end
  end
end
