# frozen_string_literal: true

module Api
  module Shipments
    # POST /api/shipments/:id/start_transit
    # POST /api/shipments/:id/deliver
    class TransitionsController < Api::BaseController
      before_action :authenticate_user!
      before_action :require_carrier!
      before_action :set_shipment

      def start_transit
        authorize @shipment, :start_transit?
        transition!(:in_transit, reason: "carrier_started_transit")
      end

      def deliver
        authorize @shipment, :deliver?
        transition!(:delivered, reason: "carrier_delivered")
      end

      private

      def set_shipment
        @shipment = Shipment.find(params[:id])
      end

      def transition!(target_status, reason:)
        shipment = ::Shipments::Transition.call(
          shipment: @shipment,
          target_status:,
          reason:
        )

        render json: ShipmentResource.new(shipment).serialize, status: :ok
      rescue ::Shipments::Transition::ConflictError => e
        render json: {
                 error: {
                   code: "conflict",
                   message: I18n.t("errors.shipments.#{e.reason}", default: I18n.t("errors.shipments.generic"))
                 }
               },
               status: :conflict
      end
    end
  end
end
