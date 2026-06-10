# frozen_string_literal: true

module Carriers
  # Carrier Dashboard activity feed (carrier-dashboard-v2 PRD).
  #
  # Merges the events that happen *to* a Carrier — payouts settled, reviews
  # received from Shippers, and inbound offer activity — into one
  # newest-first list, capped at `limit`. Shipment lifecycle milestones the
  # carrier triggers themselves (start_transit / deliver) are deliberately
  # excluded: they are a self-authored log, not news.
  #
  # Read-only over existing tables; each row is a plain Hash so the
  # heterogeneous union needs no shared model or serializer:
  #
  #   { id:, kind:, occurred_at:, shipment_id:, cargo_offer_id:,
  #     origin:, destination:, amount_cents:, currency:, rating: }
  #
  # Kinds: payout_paid | review_received | offer_received | offer_accepted |
  #        offer_rejected
  class ActivityFeed
    RECENT_LIMIT = 20

    def self.call(carrier:, limit: RECENT_LIMIT)
      new(carrier: carrier, limit: limit).call
    end

    def initialize(carrier:, limit:)
      @carrier = carrier
      @limit   = limit
    end

    def call
      rows = payout_rows + review_rows + offer_rows
      rows.sort_by { |row| row[:occurred_at] }.reverse.first(limit)
    end

    private

    attr_reader :carrier, :limit

    def payout_rows
      Payout.state_paid
            .joins(shipment: :cargo_offer)
            .where(cargo_offers: { carrier_id: carrier.id })
            .includes(shipment: { cargo_offer: :cargo })
            .order(paid_at: :desc).limit(limit)
            .map do |payout|
        cargo = payout.shipment.cargo_offer.cargo
        row(id: "payout-#{payout.id}", kind: "payout_paid",
            occurred_at: payout.paid_at, shipment_id: payout.shipment_id,
            cargo: cargo, amount_cents: payout.amount_cents,
            currency: payout.currency)
      end
    end

    def review_rows
      Review.shipper_authored
            .where(carrier_id: carrier.id)
            .includes(shipment: { cargo_offer: :cargo })
            .order(created_at: :desc).limit(limit)
            .map do |review|
        cargo = review.shipment.cargo_offer.cargo
        row(id: "review-#{review.id}", kind: "review_received",
            occurred_at: review.created_at, shipment_id: review.shipment_id,
            cargo: cargo, rating: review.rating)
      end
    end

    # One offer yields up to two rows: its arrival, then its resolution
    # (accepted_at / rejected_at) when the Shipper has answered.
    def offer_rows
      offers = CargoOffer.where(carrier_id: carrier.id)
                         .includes(:cargo)
                         .order(created_at: :desc).limit(limit)
      offers.flat_map do |offer|
        rows = [ row(id: "offer-#{offer.id}-received", kind: "offer_received",
                     occurred_at: offer.created_at, cargo_offer_id: offer.id,
                     cargo: offer.cargo, amount_cents: offer.amount_cents,
                     currency: offer.currency) ]
        if offer.accepted_at.present?
          rows << row(id: "offer-#{offer.id}-accepted", kind: "offer_accepted",
                      occurred_at: offer.accepted_at, cargo_offer_id: offer.id,
                      cargo: offer.cargo, amount_cents: offer.amount_cents,
                      currency: offer.currency)
        end
        if offer.rejected_at.present?
          rows << row(id: "offer-#{offer.id}-rejected", kind: "offer_rejected",
                      occurred_at: offer.rejected_at, cargo_offer_id: offer.id,
                      cargo: offer.cargo)
        end
        rows
      end
    end

    def row(id:, kind:, occurred_at:, cargo:, shipment_id: nil,
            cargo_offer_id: nil, amount_cents: nil, currency: nil, rating: nil)
      {
        id: id,
        kind: kind,
        occurred_at: occurred_at,
        shipment_id: shipment_id,
        cargo_offer_id: cargo_offer_id,
        origin: cargo.pickup_locality.presence || cargo.pickup_address,
        destination: cargo.delivery_locality.presence || cargo.delivery_address,
        amount_cents: amount_cents,
        currency: currency,
        rating: rating
      }
    end
  end
end
