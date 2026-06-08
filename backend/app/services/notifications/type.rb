# frozen_string_literal: true

module Notifications
  # Closed whitelist of notification types shared between the backend emitter
  # (Notifications::Publisher) and the frontend registry. Sprint 3 ships a
  # single type, `:ping`; every future feature adds its own constant here in the
  # PR that introduces it (INF-FE-00005 / ADR-013).
  module Type
    PING = :ping
    CARGO_OFFER_RECEIVED = :cargo_offer_received
    CARGO_OFFER_ACCEPTED = :cargo_offer_accepted
    CARGO_OFFER_REJECTED = :cargo_offer_rejected
    PAYOUT_APPROVED = :payout_approved
    PAYOUT_FAILED   = :payout_failed

    ALL = [ PING, CARGO_OFFER_RECEIVED, CARGO_OFFER_ACCEPTED, CARGO_OFFER_REJECTED, PAYOUT_APPROVED, PAYOUT_FAILED ].freeze

    def self.registered?(type)
      ALL.include?(type)
    end
  end
end
