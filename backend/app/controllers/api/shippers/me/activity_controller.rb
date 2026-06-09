# frozen_string_literal: true

module Api
  module Shippers
    module Me
      # GET /api/shippers/me/activity — Shipper Dashboard activity feed.
      #
      # Returns the most recent TrackingEvents across every Shipment the
      # authenticated Shipper owns (via the Cargo on the CargoOffer), newest
      # first, capped at RECENT_LIMIT. Read-only; exposes the existing
      # append-only TrackingEvent log with no schema change. Shipment ownership
      # is enforced through ShipmentPolicy::Scope — identical to the scope used
      # by the shipment index — so a Shipper only ever sees their own events.
      class ActivityController < Api::BaseController
        RECENT_LIMIT = 20

        before_action :authenticate_user!
        before_action :require_shipper!

        def index
          shipment_ids = policy_scope(Shipment).select(:id)
          events = TrackingEvent
                   .where(shipment_id: shipment_ids)
                   .order(recorded_at: :desc, id: :desc)
                   .limit(RECENT_LIMIT)
          render json: TrackingEventResource.new(events).serialize
        end
      end
    end
  end
end
