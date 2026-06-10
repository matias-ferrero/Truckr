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
               :pickup_locality, :delivery_locality,
               :weight_kg, :volume_cm3, :declared_value_cents,
               :pickup_window_start, :pickup_window_end,
               :cargo_description, :status, :distance_km
  end

  # Identity + headline review numbers for the counterparty. The carrier is
  # the party assuming the obligation, so they get to vet the shipper before
  # accepting (asymmetric reveal — see carrier-dashboard-v2 PRD). rating_avg
  # mirrors ShipperResource: carrier-authored reviews, 1 dp, nil when unrated.
  attribute :shipper do |offer|
    shipper = offer.cargo.shipper
    ratings = Review.carrier_authored.where(shipper_id: shipper.id)
    {
      id: shipper.id,
      name: shipper.user.full_name,
      rating_avg: ratings.average(:rating)&.round(1)&.to_s,
      reviews_count: ratings.count
    }
  end

  one :transport_window do
    attributes :id, :origin_locality, :origin_admin_area,
               :destination_locality, :destination_admin_area,
               :available_from, :available_to, :price_per_km,
               :max_km, :status
  end
end
