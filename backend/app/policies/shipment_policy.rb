# frozen_string_literal: true

# Pundit policy for Shipment (REQ-BE-00035).
#
# Two read paths, one resource:
#   - Listings (REQ-BE-00035 §3.1 / §3.2) scope via the user's role profile.
#     Carrier ←→ shipment.cargo_offer.carrier_id; Shipper ←→
#     shipment.cargo_offer.cargo.shipper_id.
#   - Detail (REQ-BE-00035 §3.3) authorises either side via #show?. The
#     controller maps a denied policy to 404 (not 403) so we don't leak
#     existence to non-counterparties.
class ShipmentPolicy < ApplicationPolicy
  def index? = user&.carrier.present? || user&.shipper.present?

  def show?
    return false unless user

    (user.carrier && record.cargo_offer.carrier_id == user.carrier.id) ||
      (user.shipper && record.cargo_offer.cargo.shipper_id == user.shipper.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.carrier
        scope.joins(:cargo_offer).where(cargo_offers: { carrier_id: user.carrier.id })
      elsif user&.shipper
        scope.joins(cargo_offer: :cargo).where(cargos: { shipper_id: user.shipper.id })
      else
        scope.none
      end
    end
  end
end
