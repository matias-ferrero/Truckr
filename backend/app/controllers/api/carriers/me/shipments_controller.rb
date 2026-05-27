# frozen_string_literal: true

module Api
  module Carriers
    module Me
      # GET /api/carriers/me/shipments — REQ-BE-00035 §3.1.
      #
      # Returns every Shipment where the authenticated Carrier owns the
      # Vehicle on the CargoOffer's TransportWindow. Sorted by
      # latest_activity_at DESC (max tracking_events.recorded_at, fallback
      # shipments.updated_at). No pagination / filters / search this sprint
      # (AC9).
      class ShipmentsController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_carrier!

        def index
          # `::` qualified — `Api::Shipments` (created by the nested payments
          # route in REQ-BE-00033) would otherwise shadow the top-level
          # `Shipments` module from this lexical scope.
          shipments = ::Shipments::Index.for(scope: policy_scope(Shipment))
          render json: ShipmentListResource.new(
            shipments,
            params: { current_user: current_user }
          ).serialize
        end
      end
    end
  end
end
