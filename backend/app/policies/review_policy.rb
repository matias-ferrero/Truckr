# frozen_string_literal: true

# Pundit policy for Review creation (US20 / US30).
#
# Authorisation is evaluated against the parent Shipment. The owning Shipper or
# the assigned Carrier may create one review each (direction inferred from the
# poster's role in ReviewsController).
class ReviewPolicy < ApplicationPolicy
  def create?
    return false unless user
    return false unless record.is_a?(Shipment)

    shipper_may_create? || carrier_may_create?
  end

  # Returns the authored_by direction for the current user on this shipment.
  # Guaranteed non-nil when called after a passing create? check.
  def review_direction
    return :shipper_authored if shipper_may_create?
    :carrier_authored if carrier_may_create?
  end

  private

  def shipper_may_create?
    user.shipper.present? &&
      record.cargo_offer.cargo.shipper_id == user.shipper.id
  end

  def carrier_may_create?
    user.carrier.present? &&
      record.cargo_offer.carrier_id == user.carrier.id
  end
end
