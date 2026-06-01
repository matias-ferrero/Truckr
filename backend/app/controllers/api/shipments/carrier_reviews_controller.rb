# frozen_string_literal: true

module Api
  module Shipments
    # POST /api/shipments/:shipment_id/carrier_reviews — US30 / [[REQ-BE-00044]].
    #
    # The Carrier assigned to a delivered Shipment writes a review about its
    # Shipper. Authz is `ReviewPolicy#create_carrier_review?` against the parent
    # Shipment (only the assigned Carrier). The service layer (`Reviews::Create`)
    # runs the state + uniqueness guards under `shipment.with_lock`.
    class CarrierReviewsController < Api::BaseController
      before_action :authenticate_user!

      def create
        shipment = Shipment.find(params[:shipment_id])
        authorize shipment, :create_carrier_review?, policy_class: ReviewPolicy

        review = ::Reviews::Create.call(
          shipment: shipment,
          carrier:  current_carrier,
          rating:   review_params[:rating],
          body:     review_params[:body]
        )

        render json: ReviewResource.new(review).serialize, status: :created
      rescue ::Reviews::Create::ConflictError => e
        render json: {
                 error: {
                   code:    "conflict",
                   message: I18n.t("errors.reviews.create.#{e.reason}")
                 }
               },
               status: :conflict
      end

      private

      def review_params
        params.permit(:rating, :body)
      end

      def forbidden(_e)
        render json: {
                 error: {
                   code:    "forbidden",
                   message: I18n.t("errors.reviews.create.unauthorized")
                 }
               },
               status: :forbidden
      end
    end
  end
end
