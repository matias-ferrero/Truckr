# frozen_string_literal: true

# Alba serializer for TransportWindow. Embeds a slim vehicle object so the
# frontend can display make/model/plate without an extra request.
#
# Location shape (REQ-BE-00039 / ADR-014): pure pin + parsed locality strings
# from the Google Places picker. No province / locality search columns.
class TransportWindowResource
  include Alba::Resource

  attributes :id, :vehicle_id,
             :origin_address, :origin_locality, :origin_admin_area,
             :origin_lat, :origin_lng,
             :destination_address, :destination_locality, :destination_admin_area,
             :destination_lat, :destination_lng,
             :price_per_km, :max_km, :pickup_radius_km, :dropoff_radius_km,
             :available_from, :available_to,
             :active, :status, :created_at, :updated_at

  attribute :cargo_offers_count do |tw|
    tw.cargo_offers.size
  end

  attribute :vehicle do |tw|
    v = tw.vehicle
    { id: v.id, make: v.make, model: v.model, plate: v.plate, vehicle_type: v.vehicle_type }
  end
end
