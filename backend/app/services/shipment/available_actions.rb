# frozen_string_literal: true

# Computes the list of transition strings the authenticated user may trigger
# on a Shipment given its current state and the derived payment_state.
#
# Single source of truth for the buttons rendered by REQ-FE-00024 (US39).
# The frontend MUST NOT recalculate availability — it only maps the strings
# below to i18n labels and POST endpoints (owned by REQ-BE-00033 /
# REQ-BE-00038).
#
# Whitelist (stable strings):
#   start_transit | deliver | pay | cancel
#
# Derivation table (REQ-BE-00035 plan §4.4):
#   role     state       payment_state   actions
#   shipper  accepted    pending         ["pay"]      (cancel deferred; D8)
#   shipper  accepted    paid            []           (interlock D8)
#   carrier  accepted    paid            ["start_transit"]
#   carrier  accepted    pending         []
#   carrier  in_transit  *               ["deliver"]
#   *        delivered   *               []
#   *        cancelled   *               []
module Shipment::AvailableActions
  module_function

  def for(shipment:, user:)
    return [] if user.nil?

    payment_state = derive_payment_state(shipment)
    role          = active_role(shipment, user)

    case [ role, shipment.status, payment_state ]
    in [ :carrier,  "accepted",   "paid" ]    then [ "start_transit" ]
    in [ :carrier,  "in_transit", _ ]         then [ "deliver" ]
    in [ :shipper,  "accepted",   "pending" ] then [ "pay" ]
    else
      []
    end
  end

  def derive_payment_state(shipment)
    shipment.payments.any? { |p| p.state == "escrowed" } ? "paid" : "pending"
  end

  def active_role(shipment, user)
    if user.carrier && shipment.cargo_offer.carrier_id == user.carrier.id
      :carrier
    elsif user.shipper && shipment.cargo_offer.cargo.shipper_id == user.shipper.id
      :shipper
    end
  end
end
