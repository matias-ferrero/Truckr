# frozen_string_literal: true

# Alba serializer for a Cargo match — a TransportWindow that is zone- and
# date-compatible with a Cargo (REQ-BE-00032 §2.3).
#
# Embeds the window's vehicle and that vehicle's carrier (identity + headline
# numbers) so the frontend can render a match card without extra requests.
# There is NO `distance_km` — Haversine matching is deferred with the Google
# Maps integration (see plan §2.3).
class CargoMatchResource
  include Alba::Resource

  attributes :id, :origin_zone, :destination_zone,
             :price_per_km, :max_km, :available_from, :available_to, :active

  attribute :vehicle do |window|
    v = window.vehicle
    { id: v.id, make: v.make, model: v.model, plate: v.plate,
      vehicle_type: v.vehicle_type, max_load_kg: v.max_load_kg }
  end

  # `display_name` mirrors CarrierSearchResource's computed fallback chain so
  # the frontend renders a name even when `legal_name` is blank.
  attribute :carrier do |window|
    c = window.vehicle.carrier
    { id: c.id, legal_name: c.legal_name,
      display_name: c.legal_name.presence || c.user&.full_name || c.user&.email,
      rating_avg: c.rating_avg, reviews_count: c.reviews_count,
      completed_shipments: c.completed_shipments }
  end
end
