# frozen_string_literal: true

# Pundit policy for Carrier. The public profile (US6) is open to anyone —
# `index?` / `show?` return `true`. The Scope resolves to all carriers so the
# public listing endpoint satisfies `verify_policy_scoped` cleanly.
class CarrierPolicy < ApplicationPolicy
  def index? = true
  def show? = true

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
