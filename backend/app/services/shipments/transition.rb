# frozen_string_literal: true

module Shipments
  # Write-side service for carrier shipment transitions (US18 / US19).
  #
  # Maps endpoint actions to FSM target states and returns semantic conflict
  # reasons so the API can answer HTTP 409 with stable error codes/messages.
  class Transition
    class ConflictError < StandardError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super(reason.to_s)
      end
    end

    def self.call(shipment:, target_status:, reason:)
      new(shipment:, target_status:, reason:).call
    end

    def initialize(shipment:, target_status:, reason:)
      @shipment = shipment
      @target_status = target_status.to_sym
      @reason = reason
    end

    def call
      validate_preconditions!
      shipment.transition_to!(target_status, reason:, at: Time.current)
      shipment
    rescue Shipment::IllegalTransition
      raise ConflictError, :transition_not_allowed
    end

    private

    attr_reader :shipment, :target_status, :reason

    def validate_preconditions!
      case target_status
      when :in_transit
        raise ConflictError, :shipment_not_accepted unless shipment.status_accepted?
        raise ConflictError, :shipment_not_paid unless shipment.payment_escrowed?
      when :delivered
        raise ConflictError, :shipment_not_in_transit unless shipment.status_in_transit?
      else
        raise ConflictError, :transition_not_allowed
      end
    end
  end
end
