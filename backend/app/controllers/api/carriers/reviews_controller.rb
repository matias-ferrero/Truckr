# frozen_string_literal: true

module Api
  module Carriers
    # GET /api/carriers/:carrier_id/reviews — US26.
    #
    # Paginated list of shipper-authored reviews about a Carrier. Any
    # authenticated user may browse; unauthenticated callers get 401.
    class ReviewsController < Api::BaseController
      before_action :authenticate_user!

      skip_after_action :verify_policy_scoped, only: :index

      def index
        carrier = ::Carrier.find(params[:carrier_id])
        authorize carrier, :reviews_index?

        scope = carrier.shipper_authored_reviews.order(created_at: :desc)
        @pagy, reviews = pagy(scope, limit: 10)
        render json: ReviewResource.new(reviews).serialize
      end
    end
  end
end
