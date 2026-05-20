# frozen_string_literal: true

module Api
  # CargoOffersController — a Carrier-directed bid against an existing Cargo
  # (US7 / REQ-FE-00015, remediated by REQ-BE-00032 §2.7).
  #
  # The bid no longer inline-creates a Cargo. The request body carries a
  # `cargo_id` referencing an already-published Cargo (managed by the Shipper
  # in "Mis cargas"); this action loads it, loads the TransportWindow, and
  # creates only the CargoOffer.
  #
  # Only the Shipper who owns the referenced Cargo may bid against it
  # (CargoPolicy#offer?). Business rules — pickup-window overlap, vehicle
  # capacity, positive km, the window-lock, amount/expiry derivation — live on
  # the CargoOffer model.
  class CargoOffersController < Api::BaseController
    before_action :authenticate_user!
    before_action :require_shipper!, only: :create

    # GET /api/cargo_offers — shipper sees their own offers; carrier sees offers directed at them.
    def index
      render_collection(
        CargoOfferResource,
        policy_scope(CargoOffer).includes(:cargo).order(created_at: :desc)
      )
    end

    # POST /api/cargo_offers
    # body: { cargo_offer: { cargo_id, transport_window_id, estimated_km } }
    def create
      cargo = Cargo.find(cargo_offer_params[:cargo_id])
      authorize cargo, :offer?

      window = TransportWindow.active.includes(vehicle: :carrier)
                              .find(cargo_offer_params[:transport_window_id])

      cargo_offer = CargoOffer.create!(
        cargo:            cargo,
        carrier:          window.carrier,
        transport_window: window,
        currency:         "ARS",
        status:           "pending",
        estimated_km:     cargo_offer_params[:estimated_km]
      )

      CargoOfferMailer.notify_carrier(cargo_offer).deliver_later
      render json: CargoOfferResource.new(cargo_offer).serialize, status: :created
    end

    private

    def cargo_offer_params
      params.require(:cargo_offer).permit(:cargo_id, :transport_window_id, :estimated_km)
    end
  end
end
