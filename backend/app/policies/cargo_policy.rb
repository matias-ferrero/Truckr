# frozen_string_literal: true

# Pundit policy for Cargo.
#
# A Cargo is a Shipper-owned publication: only the owning Shipper may read,
# update, cancel or run matches against it. `offer?` gates the REQ-FE-00015
# cargo-first bid flow — a Shipper may only bid on their own Cargo.
class CargoPolicy < ApplicationPolicy
  def index?   = user&.shipper.present?
  def create?  = user&.shipper.present?
  def show?    = owner?
  def update?  = owner?
  def destroy? = owner?
  def matches? = owner?
  def offer?   = owner?

  class Scope < Scope
    def resolve
      if user&.shipper
        scope.where(shipper_id: user.shipper.id)
      else
        scope.none
      end
    end
  end

  private

  def owner?
    user&.shipper.present? && record.shipper_id == user.shipper.id
  end
end
