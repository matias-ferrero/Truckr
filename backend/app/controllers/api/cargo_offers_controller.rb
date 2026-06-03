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

      window = TransportWindow.active.marketplace_open.includes(vehicle: :carrier)
                              .find(cargo_offer_params[:transport_window_id])

      cargo_offer = Marketplace::CargoOfferCreationService.new(
        cargo:        cargo,
        window:       window,
        estimated_km: cargo_offer_params[:estimated_km]
      ).call

      notify_carrier_of_new_offer(cargo_offer)
      render json: CargoOfferResource.new(cargo_offer).serialize, status: :created
    rescue Marketplace::CargoOfferCreationService::ConflictError
      render_error(code: "window_taken", status: :conflict)
    end

    private

    # Best-effort, post-commit dispatch (REQ-FE-00031). Emitted outside the
    # creation transaction/`window.lock!` so broadcast I/O never extends the lock
    # (AC4); a mailer or broadcast failure must not undo the 201 the Shipper
    # already earned by creating the offer (AC5).
    def notify_carrier_of_new_offer(cargo_offer)
      CargoOfferMailer.notify_carrier(cargo_offer).deliver_later
      Notifications::Publisher.publish(
        user_id: cargo_offer.carrier.user_id,
        type: Notifications::Type::CARGO_OFFER_RECEIVED,
        payload: {
          cargo_offer_id: cargo_offer.id,
          cargo_id: cargo_offer.cargo_id,
          transport_window_id: cargo_offer.transport_window_id,
          amount_cents: cargo_offer.amount_cents,
          currency: cargo_offer.currency
        }
      )
    rescue StandardError => e
      Rails.logger.error(
        "[CargoOffersController#create] notification dispatch failed for " \
        "CargoOffer##{cargo_offer.id}: #{e.class}: #{e.message}"
      )
    end

    def cargo_offer_params
      params.require(:cargo_offer).permit(:cargo_id, :transport_window_id, :estimated_km)
    end
  end
end
