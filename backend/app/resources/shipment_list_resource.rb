# frozen_string_literal: true

# Alba resource for the Carrier / Shipper shipment index endpoints
# (REQ-BE-00035 §3.1, §3.2, §4.1).
#
# Shape per row (US17): id, state, origin, destination, created_at,
# amount_cents, currency, latest_activity_at.
class ShipmentListResource
  include Alba::Resource

  attributes :id, :created_at

  attribute :state do |shipment|
    shipment.status
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

  # True when at least one escrowed Payment exists. Used by the listing row
  # to control the Pagar CTA and the counterparty mask without relying on a
  # dedicated FSM state (accepted stays accepted after payment — ADR-012).
  attribute :payment_escrowed do |shipment|
    shipment.payment_escrowed?
  end

  # Display label for the other party — used by the listing row to mask /
  # reveal the counterparty once payment_escrowed is true
  # (REQ-BE-00033 / AC1 / AC9). Falls back to nil for viewers with no
  # role attached.
  attribute :counterparty_display_name do |shipment|
    user = params[:current_user]
    if user&.shipper && shipment.cargo_offer.cargo.shipper_id == user.shipper.id
      shipment.cargo_offer.carrier.legal_name
    elsif user&.carrier && shipment.cargo_offer.carrier_id == user.carrier.id
      shipment.cargo_offer.cargo.shipper.company_name
    end
  end
end
