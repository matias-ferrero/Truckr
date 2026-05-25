# frozen_string_literal: true

# Alba resource for the Carrier / Shipper shipment index endpoints
# (REQ-BE-00035 §3.1, §3.2, §4.1).
#
# Shape per row (US17): id, state, payment_state (derived; omitted if
# cancelled), origin, destination, created_at, amount_cents, currency,
# latest_activity_at.
class ShipmentListResource
  include Alba::Resource

  attributes :id, :created_at

  attribute :state do |shipment|
    shipment.status
  end

  attribute :payment_state, if: proc { |shipment| shipment.status != "cancelled" } do |shipment|
    shipment.payments.any? { |p| p.state == "escrowed" } ? "paid" : "pending"
  end

  attribute :origin do |shipment|
    shipment.cargo_offer.cargo.pickup_address
  end

  attribute :destination do |shipment|
    shipment.cargo_offer.cargo.delivery_address
  end

  attribute :amount_cents do |shipment|
    shipment.cargo_offer.amount_cents
  end

  attribute :currency do |shipment|
    shipment.cargo_offer.currency
  end

  attribute :latest_activity_at do |shipment|
    shipment.tracking_events.filter_map(&:recorded_at).max || shipment.updated_at
  end
end
