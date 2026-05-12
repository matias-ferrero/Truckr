# frozen_string_literal: true

module Api
  # Public read endpoints on Carrier itself.
  #   GET /api/carriers/:id — full profile (US6)
  #
  # Unauthenticated — this is the shopfront the prospective shipper sees
  # before deciding to start an offer.
  class CarriersController < Api::BaseController
    def show
      @carrier = ::Carrier.includes(
        vehicles: { photos_attachments: :blob }
      ).find(params[:id])
      authorize @carrier

      render json: ::CarrierDetailResource.new(@carrier).serialize
    end
  end
end
