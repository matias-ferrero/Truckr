# frozen_string_literal: true

module Marketplace
  # Rejects a pending CargoOffer and reverts the TransportWindow to "open"
  # (carrier inbox reject flow — US7 / REQ-BE-00032).
  #
  # Mirrors the lock-then-validate pattern of CargoOfferAcceptanceService.
  class CargoOfferRejectionService
    class ConflictError < StandardError; end

    def initialize(cargo_offer:, at: Time.current)
      @cargo_offer = cargo_offer
      @at          = at
    end

    def call
      ActiveRecord::Base.transaction do
        cargo_offer.with_lock do
          unless cargo_offer.status == "pending" && !cargo_offer.expired?
            raise ConflictError, "cargo_offer_not_pending_or_expired"
          end

          cargo_offer.transition_to!("rejected")
          cargo_offer.update!(rejected_at: at)
          cargo_offer.transport_window.update!(status: "open")
        end
      end

      cargo_offer
    end

    private

    attr_reader :cargo_offer, :at
  end
end
