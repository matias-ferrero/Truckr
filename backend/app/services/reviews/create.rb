# frozen_string_literal: true

module Reviews
  # Reviews::Create — race-safe write side for both review directions on a
  # delivered Shipment (US20 Shipper→Carrier, US30 Carrier→Shipper).
  # Mirrors Payments::Create (REQ-BE-00033): state + per-direction uniqueness
  # guards run inside `shipment.with_lock`.
  #
  # Pass `authored_by: :shipper_authored` with `shipper:` (the author), or
  # `authored_by: :carrier_authored` with `carrier:` (the author). The
  # counterparty is always derived from the Shipment.
  #
  # Raises ConflictError (→ HTTP 409) when not delivered or already reviewed.
  # Validation failures surface as ActiveRecord::RecordInvalid → 422.
  class Create
    class ConflictError < StandardError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super(reason.to_s)
      end
    end

    def self.call(shipment:, authored_by:, rating:, body:, carrier: nil, shipper: nil)
      new(
        shipment: shipment, authored_by: authored_by, rating: rating, body: body,
        carrier: carrier, shipper: shipper
      ).call
    end

    def initialize(shipment:, authored_by:, rating:, body:, carrier: nil, shipper: nil)
      @shipment    = shipment
      @authored_by = authored_by.to_sym
      @rating      = rating
      @body        = body
      @carrier     = carrier
      @shipper     = shipper

      validate_author!
    end

    def call
      shipment.with_lock do
        raise ConflictError, :shipment_not_delivered unless shipment.status_delivered?
        raise ConflictError, :already_reviewed if review_scope.exists?(shipment_id: shipment.id)

        Review.create!(review_attributes)
      end
    end

    private

    attr_reader :shipment, :authored_by, :rating, :body, :carrier, :shipper

    def review_scope
      case authored_by
      when :shipper_authored then Review.shipper_authored
      when :carrier_authored then Review.carrier_authored
      else raise ArgumentError, "unsupported authored_by: #{authored_by}"
      end
    end

    def validate_author!
      case authored_by
      when :shipper_authored
        raise ArgumentError, "shipper is required for shipper_authored" if shipper.nil?
      when :carrier_authored
        raise ArgumentError, "carrier is required for carrier_authored" if carrier.nil?
      end
    end

    def review_attributes
      case authored_by
      when :shipper_authored
        {
          shipment: shipment,
          shipper:  shipper,
          carrier:  shipment.cargo_offer.carrier,
          rating:   rating,
          body:     body,
          authored_by: :shipper_authored
        }
      when :carrier_authored
        {
          shipment: shipment,
          carrier:  carrier,
          shipper:  shipment.cargo_offer.cargo.shipper,
          rating:   rating,
          body:     body,
          authored_by: :carrier_authored
        }
      end
    end
  end
end
