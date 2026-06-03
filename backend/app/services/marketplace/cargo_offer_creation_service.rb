# frozen_string_literal: true

module Marketplace
  # Creates a CargoOffer for a Shipper bidding a published Cargo against an
  # active TransportWindow (US7 / REQ-BE-00032 §2.7).
  #
  # Mirrors the lock-then-validate pattern of CargoOfferAcceptanceService:
  # the window is locked inside a transaction so concurrent bids can't race
  # past the `status == "open"` guard.
  class CargoOfferCreationService
    class ConflictError < StandardError; end

    def initialize(cargo:, window:, estimated_km:)
      @cargo        = cargo
      @window       = window
      @estimated_km = estimated_km
    end

    def call
      cargo_offer = nil

      ActiveRecord::Base.transaction do
        window.lock!
        unless window.status == "open"
          offer = CargoOffer.new
          offer.errors.add(:transport_window, :already_taken)
          raise ConflictError, "window_already_taken"
        end

        cargo_offer = CargoOffer.create!(
          cargo:            cargo,
          transport_window: window,
          estimated_km:     estimated_km
        )
        window.update!(status: "pending_offer")
      end

      cargo_offer
    end

    private

    attr_reader :cargo, :window, :estimated_km
  end
end
