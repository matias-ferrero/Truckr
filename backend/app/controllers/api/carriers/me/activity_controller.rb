# frozen_string_literal: true

module Api
  module Carriers
    module Me
      # GET /api/carriers/me/activity — Carrier Dashboard activity feed.
      #
      # Mirror of Api::Shippers::Me::ActivityController, but the Carrier's
      # news is heterogeneous (payouts, reviews received, offer events) so
      # the merge lives in Carriers::ActivityFeed. Read-only; newest first,
      # capped at Carriers::ActivityFeed::RECENT_LIMIT. Every source query is
      # scoped to the authenticated carrier's id inside the service.
      class ActivityController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_carrier!

        def index
          # The feed scopes by carrier_id internally; this satisfies (and
          # documents) the policy-scope invariant the same way the shipment
          # index does.
          policy_scope(Shipment)
          rows = ::Carriers::ActivityFeed.call(carrier: current_carrier)
          render json: rows
        end
      end
    end
  end
end
