# frozen_string_literal: true

# Alba serializer for CargoOffer. Used by US7 (create) and shipper/carrier list views.
class CargoOfferResource
  include Alba::Resource

  attributes :id, :cargo_id, :carrier_id, :transport_window_id,
             :amount_cents, :currency, :status, :expires_at,
             :created_at, :updated_at

  # Embed the minimal cargo summary needed for list-view cards.
  # Avoids a separate round-trip on the index endpoint.
  one :cargo do
    attributes :pickup_address, :delivery_address,
               :pickup_window_start, :pickup_window_end, :cargo_description
  end
end
