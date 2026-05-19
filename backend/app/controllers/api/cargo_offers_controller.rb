# frozen_string_literal: true

module Api
  # POST /api/cargo_offers — Shipper publishes a cargo and bids it against a transport window.
  #
  # US7 / REQ-FE-00015. The action atomically creates a Cargo (the shipper's
  # load description) and a CargoOffer (the carrier match + estimated price).
  # Only a logged-in Shipper can call this; carriers are rejected by
  # CargoOfferPolicy.
  #
  # Business rules live on the CargoOffer / Cargo models (cross-record
  # validations for pickup-date range, vehicle capacity, positive km, and
  # amount/expiry derivation). This action only translates HTTP → models → HTTP.
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

    def create
      authorize CargoOffer

      window = TransportWindow.active.includes(vehicle: :carrier).find(cargo_offer_params[:transport_window_id])

      cargo_offer = nil
      ActiveRecord::Base.transaction do
        cargo = Cargo.create!(cargo_attrs)
        cargo_offer = CargoOffer.create!(cargo_offer_attrs(window, cargo))
      end

      CargoOfferMailer.notify_carrier(cargo_offer).deliver_later
      render json: CargoOfferResource.new(cargo_offer).serialize, status: :created
    end

    private

    def cargo_offer_params
      params.require(:cargo_offer).permit(
        :transport_window_id, :pickup_address, :delivery_address,
        :pickup_date, :cargo_description, :weight_kg, :volume_cm3,
        :declared_value_cents, :estimated_km
      )
    end

    def cargo_attrs
      {
        shipper:              current_shipper,
        pickup_address:       cargo_offer_params[:pickup_address],
        delivery_address:     cargo_offer_params[:delivery_address],
        pickup_date:          cargo_offer_params[:pickup_date],
        cargo_description:    cargo_offer_params[:cargo_description],
        weight_kg:            cargo_offer_params[:weight_kg],
        volume_cm3:           cargo_offer_params[:volume_cm3],
        declared_value_cents: cargo_offer_params[:declared_value_cents]
      }
    end

    def cargo_offer_attrs(window, cargo)
      {
        cargo:            cargo,
        carrier:          window.carrier,
        transport_window: window,
        currency:         "ARS",
        status:           "pending",
        estimated_km:     cargo_offer_params[:estimated_km]
      }
    end
  end
end
