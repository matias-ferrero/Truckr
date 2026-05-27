# frozen_string_literal: true

# Pundit policy for Payment (REQ-BE-00033 / US8).
#
# Only the Shipper that owns the Cargo behind a Shipment can initiate a
# payment for that Shipment. Carriers and unrelated Shippers receive 403.
class PaymentPolicy < ApplicationPolicy
  # `record` is a Shipment here — the controller authorizes against the
  # parent before invoking the Payments::Create service.
  def create?
    return false unless user&.shipper
    return false unless record.is_a?(Shipment)

    record.cargo_offer.cargo.shipper_id == user.shipper.id
  end
end
