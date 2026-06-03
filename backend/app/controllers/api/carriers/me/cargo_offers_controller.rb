# frozen_string_literal: true

module Api
  module Carriers
    module Me
      class CargoOffersController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_carrier!

        # GET /api/carriers/me/cargo-offers?status=pending
        def index
          status = params[:status].presence || "pending"

          offers = policy_scope(CargoOffer)
                   .where(status: status)
                   .includes(cargo: { shipper: :user }, transport_window: :vehicle)
                   .order(created_at: :desc)

          render_collection(CarrierCargoOfferInboxResource, offers)
        end

        # POST /api/carriers/me/cargo-offers/:id/accept
        def accept
          offer = scoped_offer
          authorize offer, :accept?

          shipment = Marketplace::CargoOfferAcceptanceService.new(cargo_offer: offer).call

          render json: {
            cargo_offer: CarrierCargoOfferInboxResource.new(offer.reload).serialize,
            shipment: ShipmentResource.new(shipment).serialize
          }, status: :ok
        rescue Marketplace::CargoOfferAcceptanceService::ConflictError
          render_error(code: "conflict", status: :conflict)
        end

        # POST /api/carriers/me/cargo-offers/:id/reject
        def reject
          offer = scoped_offer
          authorize offer, :reject?

          Marketplace::CargoOfferRejectionService.new(cargo_offer: offer).call

          CargoOfferMailer.notify_shipper_offer_rejected(offer).deliver_later
          render json: CarrierCargoOfferInboxResource.new(offer.reload).serialize, status: :ok
        rescue Marketplace::CargoOfferRejectionService::ConflictError
          render_error(code: "conflict", status: :conflict)
        end

        private

        def scoped_offer
          CargoOffer.includes(:cargo, :transport_window).find(params[:id])
        end
      end
    end
  end
end
