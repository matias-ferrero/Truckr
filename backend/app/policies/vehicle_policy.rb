# frozen_string_literal: true

# Pundit policy for Vehicle. Public read endpoints (carrier galleries) are
# open; mutate-actions are owner-only and key on the user's carrier identity
# (`user.carrier == record.carrier`).
class VehiclePolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = owner?
  def update?  = owner?
  def destroy? = owner?

  class Scope < Scope
    def resolve
      return scope.none unless user&.carrier

      scope.where(carrier_id: user.carrier.id)
    end
  end

  private

  def owner?
    user&.carrier.present? && record.carrier_id == user.carrier.id
  end
end
