# frozen_string_literal: true

module Api
  module Shipments
    # POST /api/shipments/:shipment_id/payments — REQ-BE-00033 / US8.
    #
    # Synchronous happy-path checkout. Authz is `PaymentPolicy#create?`
    # against the parent Shipment (only the Shipper that owns the Cargo
    # behind it). The service layer (`Payments::Create`) does the race-safe
    # write under `shipment.with_lock`.
    class PaymentsController < Api::BaseController
      before_action :authenticate_user!

      def create
        shipment = Shipment.find(params[:shipment_id])
        authorize shipment, :create?, policy_class: PaymentPolicy

        payment = ::Payments::Create.call(shipment: shipment)

        render json: PaymentResource.new(payment).serialize, status: :created
      rescue ::Payments::Create::ConflictError => e
        render json: {
                 error: {
                   code:    "conflict",
                   message: I18n.t("errors.payments.#{e.reason}")
                 }
               },
               status: :conflict
      end

      private

      def forbidden(_e)
        render json: {
                 error: {
                   code:    "forbidden",
                   message: I18n.t("errors.payments.unauthorized")
                 }
               },
               status: :forbidden
      end
    end
  end
end
