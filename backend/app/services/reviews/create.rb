# frozen_string_literal: true

module Reviews
  # Reviews::Create — race-safe write side for the Carrier→Shipper review
  # (US30 / [[REQ-BE-00044]]). Mirrors Payments::Create (REQ-BE-00033): the
  # state guard and the per-direction uniqueness guard run inside
  # `shipment.with_lock` so two concurrent POSTs can't both land a
  # `carrier_authored` row for the same Shipment (SQLite — race-safety lives
  # at the application layer, no advisory locks).
  #
  # Returns the persisted Review on success. Raises `ConflictError` (mapped to
  # HTTP 409 by the controller) when the Shipment isn't `delivered` yet or a
  # Carrier review already exists. Validation failures (rating range, body
  # length) surface as ActiveRecord::RecordInvalid → 422 via BaseController.
  class Create
    class ConflictError < StandardError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super(reason.to_s)
      end
    end

    def self.call(shipment:, carrier:, rating:, body:)
      new(shipment: shipment, carrier: carrier, rating: rating, body: body).call
    end

    def initialize(shipment:, carrier:, rating:, body:)
      @shipment = shipment
      @carrier  = carrier
      @rating   = rating
      @body     = body
    end

    def call
      shipment.with_lock do
        raise ConflictError, :shipment_not_delivered unless shipment.status_delivered?

        if Review.carrier_authored.exists?(shipment_id: shipment.id)
          raise ConflictError, :already_reviewed
        end

        Review.create!(
          shipment:    shipment,
          carrier:     carrier,
          shipper:     shipment.cargo_offer.cargo.shipper,
          rating:      rating,
          body:        body,
          authored_by: :carrier_authored
        )
      end
    end

    private

    attr_reader :shipment, :carrier, :rating, :body
  end
end
