# frozen_string_literal: true

# Pundit policy for CargoOffer.
#
# Only logged-in Shippers may create cargo offers (US7 / REQ-FE-00015).
# Carriers and anonymous users are denied. Index/show are not exposed on the
# API yet — those land with US10 (REQ-FE-00017).
class CargoOfferPolicy < ApplicationPolicy
  def index?  = user&.shipper.present? || user&.carrier.present?
  def create? = user&.shipper.present?

  class Scope < Scope
    def resolve
      if user&.shipper
        scope.joins(:cargo).where(cargos: { shipper_id: user.shipper.id })
      elsif user&.carrier
        scope.where(carrier_id: user.carrier.id)
      else
        scope.none
      end
    end
  end
end
