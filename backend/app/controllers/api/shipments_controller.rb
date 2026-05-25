# frozen_string_literal: true

module Api
  # GET /api/shipments/:id — REQ-BE-00035 §3.3.
  #
  # Multi-role detail. Authorisation is via Pundit ShipmentPolicy#show? and
  # admits both Carrier (owner of the Vehicle) and Shipper (owner of the
  # Cargo). Non-counterparties — and discarded shipments — receive 404, not
  # 403, so we don't leak existence (D2). The 404-on-not-authorised mapping
  # is local to this controller; the parent BaseController keeps Pundit's
  # default 403 for other endpoints.
  class ShipmentsController < Api::BaseController
    before_action :authenticate_user!

    rescue_from Pundit::NotAuthorizedError, with: :not_found

    def show
      shipment = Shipment
                 .eager_load(
                   :payments, :tracking_events,
                   cargo_offer: [ :carrier, { cargo: :shipper }, { transport_window: { vehicle: :carrier } } ]
                 )
                 .find(params[:id])
      authorize shipment
      render json: ShipmentDetailResource.new(
        shipment,
        params: { current_user: current_user }
      ).serialize
    end
  end
end
