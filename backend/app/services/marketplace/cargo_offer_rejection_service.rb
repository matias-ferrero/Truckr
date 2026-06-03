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

      # Post-commit: a Solid Cable broadcast writes to the primary SQLite DB on
      # its own connection, and SQLite permits a single writer — emitting while
      # the transaction above still holds the write lock self-locks
      # (SQLite3::BusyException). Run it after COMMIT so the lock is released.
      enqueue_notifications

      cargo_offer
    end

    private

    attr_reader :cargo_offer, :at

    def enqueue_notifications
      CargoOfferMailer.notify_shipper_offer_rejected(cargo_offer).deliver_later
      publish_notification(
        user_id: cargo_offer.cargo.shipper.user_id,
        type: Notifications::Type::CARGO_OFFER_REJECTED,
        payload: {
          cargo_offer_id: cargo_offer.id,
          cargo_id: cargo_offer.cargo_id,
          amount_cents: cargo_offer.amount_cents,
          currency: cargo_offer.currency
        }
      )
    end

    # Best-effort live delivery (ADR-013): a broadcast failure must never bubble
    # a 500 — the reject has already committed and the durable email is queued.
    def publish_notification(user_id:, type:, payload:)
      Notifications::Publisher.publish(user_id: user_id, type: type, payload: payload)
    rescue StandardError => e
      Rails.logger.error(
        "[CargoOfferRejectionService] notification dispatch failed " \
        "(type=#{type}, user_id=#{user_id}): #{e.class}: #{e.message}"
      )
    end
  end
end
