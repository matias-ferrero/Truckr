# frozen_string_literal: true

# Pundit policy for Carrier. The public profile (US6) is open to anyone —
# `index?` / `show?` return `true`. The Scope resolves to all carriers so the
# public listing endpoint satisfies `verify_policy_scoped` cleanly.
class CarrierPolicy < ApplicationPolicy
  def index? = true
  def show? = true

  # US26 — any signed-in user may read shipper-authored reviews on a profile.
  def reviews_index? = user.present?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
