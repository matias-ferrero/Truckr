# frozen_string_literal: true

# Pundit policy for Review creation (US30 / [[REQ-BE-00044]]).
#
# Authorisation is evaluated against the parent Shipment (the controller
# authorises the Shipment before handing off to the Reviews::Create service,
# mirroring PaymentPolicy / REQ-BE-00033).
#
# `create_carrier_review?`: only the Carrier assigned to the Shipment may
# review its Shipper. The Shipper→Carrier direction (US20) adds its own query
# method here when that issue lands — this policy is the natural home for it,
# but US30 does not need it.
class ReviewPolicy < ApplicationPolicy
  def create_carrier_review?
    return false unless user&.carrier
    return false unless record.is_a?(Shipment)

    record.cargo_offer.carrier_id == user.carrier.id
  end
end
