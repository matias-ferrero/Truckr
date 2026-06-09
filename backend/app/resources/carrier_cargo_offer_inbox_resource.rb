# frozen_string_literal: true

# Carrier inbox view for CargoOffers with cargo + shipper + transport_window data inline.
class CarrierCargoOfferInboxResource
  include Alba::Resource

  attributes :id, :cargo_id, :carrier_id, :transport_window_id,
             :status, :expires_at, :accepted_at, :rejected_at,
             :created_at, :updated_at

  attribute :price_amount_cents do |offer|
    offer.amount_cents
  end

  one :cargo do
    attributes :id, :pickup_address, :delivery_address,
               :weight_kg, :volume_cm3, :declared_value_cents,
               :pickup_window_start, :pickup_window_end,
               :cargo_description, :status, :distance_km
  end

  attribute :shipper do |offer|
    {
      id: offer.cargo.shipper_id,
      name: offer.cargo.shipper.user.full_name
    }
  end

  one :transport_window do
    attributes :id, :origin_locality, :origin_admin_area,
               :destination_locality, :destination_admin_area,
               :available_from, :available_to, :price_per_km,
               :max_km, :status
  end
end
