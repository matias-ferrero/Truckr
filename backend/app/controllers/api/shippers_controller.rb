# frozen_string_literal: true

module Api
  # Public read endpoint on Shipper itself.
  #   GET /api/shippers/:id — full profile (US54 / REQ-BE-00045)
  #
  # Unlike the Carrier profile (open to anonymous prospective shippers), the
  # Shipper profile and its reviews are visible to *authenticated* users only
  # (AC1) — the audience is carriers comparing shippers before bidding.
  class ShippersController < Api::BaseController
    before_action :authenticate_user!

    def show
      @shipper = ::Shipper.find(params[:id])
      authorize @shipper

      render json: ::ShipperDetailResource.new(@shipper).serialize
    end
  end
end
