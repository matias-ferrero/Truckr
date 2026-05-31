# frozen_string_literal: true

# Alba resource for the Shipment detail endpoint (REQ-BE-00035 §3.3, §4.2).
#
# Multi-role: receives `current_user` via `params:` so role-dependent blocks
# (`counterparty`, `available_actions`) resolve from the same payload for
# both Carrier and Shipper viewers. The frontend (REQ-FE-00024) is agnostic
# to which side is consuming.
class ShipmentDetailResource
  include Alba::Resource

  attributes :id, :created_at

  attribute :state do |shipment|
    shipment.status
  end

  attribute :amount_cents do |shipment|
    shipment.cargo_offer.amount_cents
  end

  attribute :currency do |shipment|
    shipment.cargo_offer.currency
  end

  attribute :cargo do |shipment|
    cargo = shipment.cargo_offer.cargo
    {
      id: cargo.id,
      origin: cargo.pickup_address,
      destination: cargo.delivery_address,
      description: cargo.cargo_description,
      weight_kg: cargo.weight_kg,
      pickup_lat:   cargo.pickup_lat,
      pickup_lng:   cargo.pickup_lng,
      delivery_lat: cargo.delivery_lat,
      delivery_lng: cargo.delivery_lng
    }
  end

  attribute :vehicle do |shipment|
    vehicle = shipment.cargo_offer.transport_window.vehicle
    {
      id:    vehicle.id,
      plate: vehicle.plate,
      kind:  vehicle.vehicle_type
    }
  end

  attribute :counterparty do |shipment|
    user = params[:current_user]
    role = Shipment::AvailableActions.active_role(shipment, user)

    if role == :carrier
      shipper = shipment.cargo_offer.cargo.shipper
      {
        kind:         "shipper",
        id:           shipper.id,
        display_name: shipper.company_name
      }
    elsif role == :shipper
      # `cargo_offer.carrier` is the canonical denormalised FK that the
      # policy uses; deriving the counterparty from the same edge keeps
      # the detail payload consistent with the index scope.
      carrier = shipment.cargo_offer.carrier
      {
        kind:         "carrier",
        id:           carrier.id,
        display_name: carrier.legal_name
      }
    end
  end

  # Contact info reveal — REQ-BE-00033 / US8 / AC9. Returns `nil` while no
  # Payment is escrowed for the Shipment; once escrowed, exposes the
  # counterparty's user contact triple to both sides of the trade.
  attribute :counterparty_contact do |shipment|
    next nil unless shipment.payments.any? { |p| p.state == "escrowed" }

    user = params[:current_user]
    role = Shipment::AvailableActions.active_role(shipment, user)

    contact_user =
      case role
      when :carrier then shipment.cargo_offer.cargo.shipper.user
      when :shipper then shipment.cargo_offer.carrier.user
      end

    next nil unless contact_user

    {
      full_name: contact_user.full_name,
      email:     contact_user.email,
      phone:     contact_user.phone
    }
  end

  attribute :payment, if: proc { |shipment| shipment.status != "cancelled" } do |shipment|
    payment = shipment.payments.max_by { |p| p.escrowed_at || p.created_at }
    next nil if payment.nil?

    {
      id:           payment.id,
      state:        payment.state,
      amount_cents: payment.amount_cents,
      currency:     payment.currency,
      escrowed_at:  payment.escrowed_at
    }
  end

  attribute :tracking_events do |shipment|
    shipment.tracking_events.sort_by(&:recorded_at).map do |te|
      entry = { id: te.id, kind: te.kind, occurred_at: te.recorded_at }
      if te.kind == "status_change"
        entry[:from_status] = te.from_status
        entry[:to_status]   = te.to_status
      end
      entry
    end
  end

  attribute :available_actions do |shipment|
    Shipment::AvailableActions.for(shipment: shipment, user: params[:current_user])
  end
end
