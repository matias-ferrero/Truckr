# frozen_string_literal: true

# Pundit policy for TransportWindow.
#
# Public read: anyone (including anonymous) can search the catalog of
# published windows. There is no mutate-side here yet — carrier-side window
# CRUD lives in a sibling PR (#163) which will extend this policy.
class TransportWindowPolicy < ApplicationPolicy
  def index? = true
  def show?  = true

  class Scope < Scope
    # Public catalog == only `active` windows. Inactive (paused / retired)
    # rows must not leak into search results.
    def resolve
      scope.active
    end
  end
end
