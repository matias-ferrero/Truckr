# frozen_string_literal: true

class ShipmentResource
  include Alba::Resource

  attributes :id, :cargo_offer_id, :status,
             :accepted_at, :picked_up_at, :delivered_at,
             :created_at, :updated_at
end
