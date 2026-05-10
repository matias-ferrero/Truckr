# frozen_string_literal: true

# Alba serializer for Vehicle. Two variants:
#   - VehicleResource:        full — every column + photo variant URLs.
#   - VehicleSlimResource:    slim — drops description/dimensions for list
#                             responses where size matters.
class VehicleResource
  include Alba::Resource

  attributes :id, :carrier_id, :make, :model, :year, :plate, :vehicle_type,
             :max_load_kg, :length_cm, :width_cm, :height_cm,
             :volume_cm3, :gps_enabled, :description,
             :created_at, :updated_at

  attribute :photos do |v|
    next [] unless v.photos.attached?

    v.photos.map do |p|
      { id: p.id, **v.photo_variants(p) }
    end
  end

  # Returns the slim list variant — used by `index` endpoints.
  def self.list
    VehicleSlimResource
  end
end

class VehicleSlimResource
  include Alba::Resource

  attributes :id, :carrier_id, :make, :model, :year, :plate, :vehicle_type,
             :max_load_kg, :volume_cm3, :gps_enabled,
             :created_at, :updated_at

  attribute :photos do |v|
    next [] unless v.photos.attached?

    v.photos.map do |p|
      { id: p.id, **v.photo_variants(p) }
    end
  end
end
