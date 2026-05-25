# frozen_string_literal: true

module Api
  module Shippers
    module Me
      # GET /api/shippers/me/shipments — REQ-BE-00035 §3.2.
      #
      # Mirror of Api::Carriers::Me::ShipmentsController#index for the
      # Expedidor side: returns every Shipment where the authenticated
      # Shipper owns the Cargo on the CargoOffer. Same sort, same payload
      # shape, same no-pagination contract (AC9).
      class ShipmentsController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_shipper!

        def index
          shipments = Shipments::Index.for(scope: policy_scope(Shipment))
          render json: ShipmentListResource.new(
            shipments,
            params: { current_user: current_user }
          ).serialize
        end
      end
    end
  end
end
