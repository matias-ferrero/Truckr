# frozen_string_literal: true

class ShipmentPolicy < ApplicationPolicy
  def index? = user&.carrier.present?

  class Scope < Scope
    def resolve
      return scope.none unless user&.carrier

      scope.joins(:cargo_offer).where(cargo_offers: { carrier_id: user.carrier.id })
    end
  end
end
