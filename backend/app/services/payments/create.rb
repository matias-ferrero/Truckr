# frozen_string_literal: true

module Payments
  # Payments::Create — synchronous, race-safe write side for REQ-BE-00033 / US8.
  #
  # Wraps the entire flow under `shipment.with_lock` so two concurrent POSTs
  # can't both land an `escrowed` row for the same Shipment (SQLite —
  # race-safety lives at the application layer). The lock re-verifies the
  # guards inside the critical section before calling the gateway.
  #
  # The Shipment FSM state stays `accepted` after payment — the escrowed
  # Payment row is the source of truth for payment status. AvailableActions
  # surfaces "start_transit" for the carrier once payment_escrowed? is true.
  #
  # Returns the persisted Payment on success. Raises `Payments::ConflictError`
  # when the shipment cannot be paid (not in `accepted`, or already escrowed)
  # so the controller can map to HTTP 409.
  class Create
    class ConflictError < StandardError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super(reason.to_s)
      end
    end

    def self.call(shipment:)
      new(shipment: shipment).call
    end

    def initialize(shipment:)
      @shipment = shipment
    end

    def call
      shipment.with_lock do
        raise ConflictError, :shipment_not_accepted unless shipment.status_accepted?
        raise ConflictError, :already_paid          if shipment.payments.where(state: "escrowed").exists?

        outcome = Payments.gateway.process_payment!(shipment: shipment)

        payment = shipment.payments.create!(
          amount_cents:       shipment.cargo_offer.amount_cents,
          currency:           shipment.cargo_offer.currency,
          provider:           "fake",
          provider_reference: outcome.provider_reference,
          state:              "escrowed",
          escrowed_at:        Time.current
        )

        return payment
      end
    end

    private

    attr_reader :shipment
  end
end
