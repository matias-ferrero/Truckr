# frozen_string_literal: true

module Api
  module Shipments
    # POST /api/shipments/:shipment_id/reviews — US20 / US30.
    #
    # The authenticated party on a delivered Shipment leaves a review about
    # their counterparty. Direction is inferred from the poster's role (owning
    # Shipper → shipper_authored, assigned Carrier → carrier_authored).
    class ReviewsController < Api::BaseController
      before_action :authenticate_user!

      def create
        shipment = Shipment.find(params[:shipment_id])
        authorize shipment, :create?, policy_class: ReviewPolicy

        review = ::Reviews::Create.call(**create_args(shipment))

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

      def create_args(shipment)
        direction = ReviewPolicy.new(current_user, shipment).review_direction
        base = { shipment: shipment, authored_by: direction,
                 rating: review_params[:rating], body: review_params[:body] }
        case direction
        when :shipper_authored then base.merge(shipper: current_shipper)
        when :carrier_authored then base.merge(carrier: current_carrier)
        end
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
