# frozen_string_literal: true

module Marketplace
  # Accepts a carrier-facing CargoOffer and applies all required state changes
  # in one DB transaction to keep Cargo/CargoOffer/TransportWindow consistent.
  class CargoOfferAcceptanceService
    class ConflictError < StandardError; end

    def initialize(cargo_offer:, at: Time.current, sibling_rejector: nil)
      @cargo_offer = cargo_offer
      @at = at
      @sibling_rejector = sibling_rejector || method(:reject_sibling!)
    end

    def call
      shipment = nil
      rejected_siblings = []

      ActiveRecord::Base.transaction do
        cargo_offer.with_lock do
          ensure_acceptable!

          cargo_offer.transition_to!("accepted")
          cargo_offer.update!(accepted_at: at)

          cargo_offer.transport_window.update!(status: "reserved")
          cargo_offer.cargo.transition_to!(:accepted, at: at)

          rejected_siblings = sibling_pending_offers.to_a
          rejected_siblings.each do |sibling|
            sibling_rejector.call(sibling)
          end

          shipment = Shipment.create!(
            cargo_offer: cargo_offer,
            status: "accepted",
            accepted_at: at
          )
        end
      end

      # Post-commit: a Solid Cable broadcast writes to the primary SQLite DB on
      # its own connection, and SQLite permits a single writer — emitting while
      # the transaction above still holds the write lock self-locks
      # (SQLite3::BusyException). Run it after COMMIT so the lock is released.
      enqueue_notifications(rejected_siblings, shipment)

      shipment
    end

    private

    attr_reader :cargo_offer, :at, :sibling_rejector

    def ensure_acceptable!
      unless cargo_offer.status == "pending" && !cargo_offer.expired?
        raise ConflictError, "cargo_offer_not_pending_or_expired"
      end

      raise ConflictError, "cargo_not_open" unless cargo_offer.cargo.status == "open"
    end

    def sibling_pending_offers
      cargo_offer.cargo.cargo_offers
                .where(status: "pending")
                .where.not(id: cargo_offer.id)
                .includes(:transport_window, cargo: { shipper: :user })
    end

    def reject_sibling!(sibling)
      sibling.transition_to!("rejected")
      sibling.update!(rejected_at: at)
      sibling.transport_window.update!(status: "open")
    end

    def enqueue_notifications(rejected_siblings, shipment)
      CargoOfferMailer.notify_shipper_offer_accepted(cargo_offer).deliver_later
      publish_notification(
        user_id: cargo_offer.cargo.shipper.user_id,
        type: Notifications::Type::CARGO_OFFER_ACCEPTED,
        payload: offer_payload(cargo_offer, shipment_id: shipment&.id)
      )

      rejected_siblings.each do |sibling|
        next unless sibling.status == "rejected"

        CargoOfferMailer.notify_shipper_offer_rejected(sibling).deliver_later
        publish_notification(
          user_id: sibling.cargo.shipper.user_id,
          type: Notifications::Type::CARGO_OFFER_REJECTED,
          payload: offer_payload(sibling)
        )
      end
    end

    # Best-effort live delivery (ADR-013): a single broadcast failure must never
    # abort the post-commit fan-out (the siblings still need their durable email)
    # nor bubble a 500 — the accept has already committed.
    def publish_notification(user_id:, type:, payload:)
      Notifications::Publisher.publish(user_id: user_id, type: type, payload: payload)
    rescue StandardError => e
      Rails.logger.error(
        "[CargoOfferAcceptanceService] notification dispatch failed " \
        "(type=#{type}, user_id=#{user_id}): #{e.class}: #{e.message}"
      )
    end

    def offer_payload(offer, shipment_id: nil)
      payload = {
        cargo_offer_id: offer.id,
        cargo_id: offer.cargo_id,
        amount_cents: offer.amount_cents,
        currency: offer.currency
      }
      payload[:shipment_id] = shipment_id if shipment_id
      payload
    end
  end
end
