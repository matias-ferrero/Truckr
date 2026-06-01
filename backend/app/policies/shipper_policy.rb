# frozen_string_literal: true

# Pundit policy for Shipper. The public profile (US54) is visible to any
# authenticated user — `show?` returns true; authentication itself is enforced
# at the controller via `authenticate_user!`. The Scope resolves to all
# shippers so any future listing endpoint satisfies `verify_policy_scoped`.
class ShipperPolicy < ApplicationPolicy
  def index? = true
  def show? = true

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
