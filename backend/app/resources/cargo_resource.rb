# frozen_string_literal: true

# Alba serializer for Cargo (REQ-BE-00032). Serializes the publication, a
# `pending_offers_count`, an `editable` predicate and its nested CargoOffers
# (status + target-window summary — NOT the full CargoOfferResource, which
# would recurse back into the Cargo).
#
# On the `create` response the controller passes `matches:` so the freshly
# published Cargo ships its initial match list inline; otherwise the
# `matches` attribute is omitted (`nil`).
class CargoResource
  include Alba::Resource

  attributes :id, :shipper_id, :status, :cargo_description,
             :pickup_address, :delivery_address,
             :pickup_locality, :pickup_admin_area,
             :delivery_locality, :delivery_admin_area,
             :pickup_lat, :pickup_lng, :delivery_lat, :delivery_lng,
             :pickup_window_start, :pickup_window_end,
             :weight_kg, :volume_cm3, :declared_value_cents,
             :cancelled_at, :cancellation_reason, :created_at, :updated_at

  attribute :editable do |cargo|
    cargo.editable?
  end

  attribute :pending_offers_count do |cargo|
    cargo.cargo_offers.count { |o| o.status == "pending" }
  end

  attribute :cargo_offers do |cargo|
    cargo.cargo_offers.map do |offer|
      window = offer.transport_window
      {
        id: offer.id,
        cargo_id: offer.cargo_id,
        carrier_id: offer.carrier_id,
        transport_window_id: offer.transport_window_id,
        status: offer.status,
        amount_cents: offer.amount_cents,
        currency: offer.currency,
        expires_at: offer.expires_at,
        created_at: offer.created_at,
        updated_at: offer.updated_at,
        transport_window: window && {
          id:                     window.id,
          origin_locality:        window.origin_locality,
          origin_admin_area:      window.origin_admin_area,
          destination_locality:   window.destination_locality,
          destination_admin_area: window.destination_admin_area,
          available_from:         window.available_from,
          available_to:           window.available_to
        }
      }
    end
  end

  attribute :matches do |_cargo|
    next nil unless params.key?(:matches)

    CargoMatchResource.new(params[:matches]).to_h
  end
end
