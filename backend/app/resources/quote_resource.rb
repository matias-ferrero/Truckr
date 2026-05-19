# frozen_string_literal: true

# Alba serializer for Quote. Used by US7 (create) and shipper/carrier list views.
class QuoteResource
  include Alba::Resource

  attributes :id, :cargo_offer_id, :carrier_id, :transport_window_id,
             :amount_cents, :currency, :status, :expires_at,
             :created_at, :updated_at

  # Embed the minimal cargo offer summary needed for list-view cards.
  # Avoids a separate round-trip on the index endpoint.
  one :cargo_offer do
    attributes :pickup_address, :delivery_address, :pickup_date, :cargo_description
  end
end
