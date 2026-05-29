# frozen_string_literal: true

# Alba serializer for Carrier — full variant powering the public profile page
# (US6 — GET /api/carriers/:id). Inherits the slim attributes from
# `CarrierResource` and layers on description, vehicles (with photos) and the
# active transport_windows.
class CarrierDetailResource < CarrierResource
  attributes :description, :created_at, :updated_at

  many :vehicles, resource: VehicleResource

  attribute :transport_windows do |carrier|
    carrier.active_transport_windows.map do |w|
      {
        id:                     w.id,
        vehicle_id:             w.vehicle_id,
        origin_address:         w.origin_address,
        origin_locality:        w.origin_locality,
        origin_admin_area:      w.origin_admin_area,
        destination_address:    w.destination_address,
        destination_locality:   w.destination_locality,
        destination_admin_area: w.destination_admin_area,
        origin_lat:             w.origin_lat,
        origin_lng:             w.origin_lng,
        destination_lat:        w.destination_lat,
        destination_lng:        w.destination_lng,
        pickup_radius_km:       w.pickup_radius_km,
        dropoff_radius_km:      w.dropoff_radius_km,
        price_per_km:           w.price_per_km.to_s,
        max_km:                 w.max_km,
        available_from:         w.available_from&.iso8601,
        available_to:           w.available_to&.iso8601,
        active:                 w.active
      }
    end
  end
end
