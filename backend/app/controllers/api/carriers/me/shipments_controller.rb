# frozen_string_literal: true

module Api
  module Carriers
    module Me
      class ShipmentsController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_carrier!

        # GET /api/carriers/me/shipments?status=accepted|in_transit|delivered|cancelled
        # Default view is the active shipment queue.
        def index
          render_collection(ShipmentResource, filtered_scope.order(created_at: :desc))
        end

        private

        def filtered_scope
          scope = policy_scope(Shipment)

          return scope.in_progress if params[:status].blank?

          allowed = Shipment::STATUSES
          return scope.none unless allowed.include?(params[:status])

          scope.where(status: params[:status])
        end
      end
    end
  end
end
