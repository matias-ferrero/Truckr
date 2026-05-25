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

        enqueue_notifications(rejected_siblings)
      end

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
                .includes(:transport_window)
    end

    def reject_sibling!(sibling)
      sibling.transition_to!("rejected")
      sibling.update!(rejected_at: at)
      sibling.transport_window.update!(status: "open")
    end

    def enqueue_notifications(rejected_siblings)
      CargoOfferMailer.notify_shipper_offer_accepted(cargo_offer).deliver_later

      rejected_siblings.each do |sibling|
        next unless sibling.status == "rejected"

        CargoOfferMailer.notify_shipper_offer_rejected(sibling).deliver_later
      end
    end
  end
end
