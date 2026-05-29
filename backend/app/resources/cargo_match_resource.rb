# frozen_string_literal: true

# Alba serializer for a Cargo match — a TransportWindow that is geographically
# (Haversine) and date-compatible with a Cargo (REQ-BE-00032 §2.3,
# REQ-BE-00039 § ADR-014).
#
# Embeds the window's vehicle and that vehicle's carrier (identity + headline
# numbers) so the frontend can render a match card without extra requests.
# Both endpoints' parsed locality + admin_area travel on the wire so the FE
# can render "Locality, AdminArea → Locality, AdminArea" labels without a
# second roundtrip. Open-destination windows are signalled by
# `destination_lat == null`. No `distance_km` attribute: the FE owns Haversine
# for display purposes (SQLite-forever — distance lives in app code).
class CargoMatchResource
  include Alba::Resource

  attributes :id,
             :origin_address, :origin_locality, :origin_admin_area,
             :origin_lat, :origin_lng,
             :destination_address, :destination_locality, :destination_admin_area,
             :destination_lat, :destination_lng,
             :price_per_km, :max_km,
             :pickup_radius_km, :dropoff_radius_km,
             :available_from, :available_to, :active

  attribute :vehicle do |window|
    v = window.vehicle
    { id: v.id, make: v.make, model: v.model, plate: v.plate,
      vehicle_type: v.vehicle_type, max_load_kg: v.max_load_kg }
  end

  # `display_name` mirrors the previous carrier-search fallback chain so the
  # frontend renders a name even when `legal_name` is blank.
  attribute :carrier do |window|
    c = window.vehicle.carrier
    { id: c.id, legal_name: c.legal_name,
      display_name: c.legal_name.presence || c.user&.full_name || c.user&.email,
      rating_avg: c.rating_avg, reviews_count: c.reviews_count,
      completed_shipments: c.completed_shipments }
  end
end
