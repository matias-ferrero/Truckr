# frozen_string_literal: true

# Alba serializer for TransportWindow. Embeds a slim vehicle object so the
# frontend can display make/model/plate without an extra request.
class TransportWindowResource
  include Alba::Resource

  attributes :id, :vehicle_id, :origin_zone, :destination_zone,
             :price_per_km, :max_km, :available_from, :available_to,
             :active, :status, :created_at, :updated_at

  attribute :vehicle do |tw|
    v = tw.vehicle
    { id: v.id, make: v.make, model: v.model, plate: v.plate, vehicle_type: v.vehicle_type }
  end
end
