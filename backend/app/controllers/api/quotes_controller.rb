# frozen_string_literal: true

module Api
  # POST /api/quotes — Shipper creates a cargo offer + quote against a transport window.
  #
  # US7 / REQ-FE-00015. The action atomically creates a CargoOffer (the shipper's
  # load description) and a Quote (the carrier match + estimated price). Only a
  # logged-in Shipper can call this; carriers are rejected by QuotePolicy.
  #
  # Business rules live on the Quote / CargoOffer models (cross-record validations
  # for pickup-date range, vehicle capacity, positive km, and amount/expiry
  # derivation). This action only translates HTTP → models → HTTP.
  class QuotesController < Api::BaseController
    before_action :authenticate_user!
    before_action :require_shipper!, only: :create

    # GET /api/quotes — shipper sees their own quotes; carrier sees quotes directed at them.
    def index
      render_collection(
        QuoteResource,
        policy_scope(Quote).includes(:cargo_offer).order(created_at: :desc)
      )
    end

    def create
      authorize Quote

      window = TransportWindow.active.includes(vehicle: :carrier).find(quote_params[:transport_window_id])

      quote = nil
      ActiveRecord::Base.transaction do
        cargo_offer = CargoOffer.create!(cargo_offer_attrs)
        quote = Quote.create!(quote_attrs(window, cargo_offer))
      end

      QuoteMailer.notify_carrier(quote).deliver_later
      render json: QuoteResource.new(quote).serialize, status: :created
    end

    private

    def quote_params
      params.require(:quote).permit(
        :transport_window_id, :pickup_address, :delivery_address,
        :pickup_date, :cargo_description, :weight_kg, :volume_cm3,
        :declared_value_cents, :estimated_km
      )
    end

    def cargo_offer_attrs
      {
        shipper:              current_shipper,
        pickup_address:       quote_params[:pickup_address],
        delivery_address:     quote_params[:delivery_address],
        pickup_date:          quote_params[:pickup_date],
        cargo_description:    quote_params[:cargo_description],
        weight_kg:            quote_params[:weight_kg],
        volume_cm3:           quote_params[:volume_cm3],
        declared_value_cents: quote_params[:declared_value_cents]
      }
    end

    def quote_attrs(window, cargo_offer)
      {
        cargo_offer:      cargo_offer,
        carrier:          window.carrier,
        transport_window: window,
        currency:         "ARS",
        status:           "pending",
        estimated_km:     quote_params[:estimated_km]
      }
    end
  end
end
