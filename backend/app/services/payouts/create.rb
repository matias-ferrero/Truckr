# frozen_string_literal: true

module Payouts
  # US15 — Release escrow funds to Carrier on shipment delivery (REQ-BE-00046).
  #
  # Reads the escrowed Payment, calculates platform commission (15%), and
  # creates an immutable Payout record. Race-safe: acquires a row lock on the
  # parent Shipment so concurrent deliver requests produce exactly one payout.
  #
  # Usage:
  #   Payouts::Create.call(shipment:)
  #
  # Raises:
  #   ConflictError(:no_escrowed_payment) — no escrowed Payment found; 500
  #   ConflictError(:already_paid)        — payout already exists; 500
  class Create
    class ConflictError < StandardError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super(reason.to_s)
      end
    end

    PLATFORM_COMMISSION_RATE = BigDecimal("0.15")

    def self.call(shipment:)
      new(shipment:).call
    end

    def initialize(shipment:)
      @shipment = shipment
    end

    def call
      shipment.with_lock do
        guard_preconditions!

        escrowed_payment = shipment.payments.find_by(state: "escrowed")
        gross  = escrowed_payment.amount_cents
        rate   = PLATFORM_COMMISSION_RATE
        commission = (gross * rate).ceil
        net    = gross - commission

        payout = Payout.create!(
          shipment:             shipment,
          payment:              escrowed_payment,
          gross_amount_cents:   gross,
          commission_rate:      rate,
          commission_cents:     commission,
          amount_cents:         net,
          currency:             escrowed_payment.currency,
          state:                "paid",
          paid_at:              Time.current
        )

        emit_notification!(payout)
        payout
      end
    end

    private

    attr_reader :shipment

    def guard_preconditions!
      escrowed = shipment.payments.find_by(state: "escrowed")
      raise ConflictError, :no_escrowed_payment unless escrowed

      raise ConflictError, :already_paid if shipment.payout.present?
    end

    def emit_notification!(payout)
      carrier_user = shipment.cargo_offer.carrier.user
      Notifications::Publisher.publish(
        user_id: carrier_user.id,
        type:    Notifications::Type::PAYOUT_APPROVED,
        payload: {
          shipment_id:        shipment.id,
          gross_amount_cents: payout.gross_amount_cents,
          commission_cents:   payout.commission_cents,
          amount_cents:       payout.amount_cents,
          currency:           payout.currency
        }
      )
    rescue StandardError => e
      # Best-effort notification — payout is already persisted, so we log and
      # continue rather than rolling back the settled funds calculation.
      Rails.logger.error("[Payouts::Create] notification failed: #{e.class}: #{e.message}")
    end
  end
end
