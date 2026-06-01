# frozen_string_literal: true

module Api
  module Shippers
    # GET /api/shippers/:shipper_id/reviews — US54 / REQ-BE-00045 (AC3).
    #
    # Lists the carrier-authored reviews about one Shipper, newest first,
    # paginated 10 per page (Pagy → X-Total / X-Page / X-Per-Page /
    # X-Total-Pages headers, matching every other paginated list in the API).
    # Authenticated users only (AC1). 404 when the Shipper does not exist.
    class ReviewsController < Api::BaseController
      before_action :authenticate_user!

      # Nesting under `:shipper_id` already restricts the rows; ReviewPolicy is
      # creation-oriented, so skip the read-side Pundit invariants here (same
      # pattern as Api::Carriers::VehiclesController).
      skip_after_action :verify_authorized, raise: false
      skip_after_action :verify_policy_scoped, raise: false

      def index
        shipper = ::Shipper.find(params[:shipper_id])
        scope = Review.carrier_authored
                      .where(shipper_id: shipper.id)
                      .order(created_at: :desc)
        @pagy, reviews = pagy(scope, limit: 10)
        render json: ReviewResource.new(reviews).serialize
      end
    end
  end
end
