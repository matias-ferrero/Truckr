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
        transition!(:delivered, reason: "carrier_delivered") do |shipment|
          Payouts::Create.call(shipment:)
        end
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

        yield shipment if block_given?

        render json: ShipmentResource.new(shipment).serialize, status: :ok
      rescue ::Shipments::Transition::ConflictError => e
        render json: {
                 error: {
                   code: "conflict",
                   message: I18n.t("errors.shipments.#{e.reason}", default: I18n.t("errors.shipments.generic"))
                 }
               },
               status: :conflict
      rescue Payouts::Create::ConflictError => e
        # Payout errors are programmer errors (missing escrow, duplicate payout)
        # — surface as 500 per AC2. Notify carrier per AC4 (US15).
        Rails.logger.error("[deliver] Payouts::Create failed: #{e.reason}")
        begin
          Notifications::Publisher.publish(
            user_id: @shipment.cargo_offer.carrier.user_id,
            type:    Notifications::Type::PAYOUT_FAILED,
            payload: { shipment_id: @shipment.id, reason: e.reason.to_s }
          )
        rescue StandardError => notify_err
          Rails.logger.error("[deliver] PAYOUT_FAILED notification failed: #{notify_err.message}")
        end
        render json: {
                 error: {
                   code: "payout_conflict",
                   message: I18n.t("errors.payouts.#{e.reason}", default: I18n.t("errors.payouts.generic"))
                 }
               },
               status: :internal_server_error
      end
    end
  end
end
