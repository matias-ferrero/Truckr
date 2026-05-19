# frozen_string_literal: true

# Pundit policy for Quote.
#
# Only logged-in Shippers may create quotes (US7 / REQ-FE-00015). Carriers and
# anonymous users are denied. Index/show are not exposed on the API yet — those
# land with US10 (REQ-FE-00017).
class QuotePolicy < ApplicationPolicy
  def index?  = user&.shipper.present? || user&.carrier.present?
  def create? = user&.shipper.present?

  class Scope < Scope
    def resolve
      if user&.shipper
        scope.joins(:cargo_offer).where(cargo_offers: { shipper_id: user.shipper.id })
      elsif user&.carrier
        scope.where(carrier_id: user.carrier.id)
      else
        scope.none
      end
    end
  end
end
