# frozen_string_literal: true

# Pundit policy for TransportWindow.
#
# Public read (index/show): anyone can browse the active window catalog.
# Carrier mutations: the authenticated carrier must own the window's vehicle.
class TransportWindowPolicy < ApplicationPolicy
  def index?   = carrier_present?
  def show?    = owner?
  def create?  = owner?
  def update?  = owner?
  def destroy? = owner?

  class Scope < Scope
    def resolve
      if user&.carrier
        scope.joins(:vehicle).where(vehicles: { carrier_id: user.carrier.id })
      else
        scope.active
      end
    end
  end

  private

  def carrier_present?
    user&.carrier.present?
  end

  def owner?
    owns?(record.vehicle&.carrier_id)
  end
end
