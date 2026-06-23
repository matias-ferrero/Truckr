# frozen_string_literal: true

module Api
  module Carriers
    module Me
      # GET /api/carriers/me/payouts
      #
      # Returns the authenticated Carrier's payout history, newest first.
      # Each row includes the full financial breakdown plus the shipment's
      # origin, destination, and shipper company name (AC3).
      #
      # 401 without auth, 403 without Carrier role.
      class PayoutsController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_carrier!
        skip_after_action :verify_policy_scoped, only: :index

        def index
          carrier = current_user.carrier
          payouts = Payout
                    .joins(:shipment)
                    .where(shipments: { cargo_offer_id: carrier.cargo_offers.select(:id) })
                    .includes(shipment: { cargo_offer: { cargo: :shipper } })
                    .order(created_at: :desc)

          render json: payouts.map { |p| serialize_payout(p) }, status: :ok
        end

        private

        def serialize_payout(payout)
          shipment = payout.shipment
          cargo    = shipment.cargo_offer.cargo
          shipper  = cargo.shipper

          {
            id:                  payout.id,
            shipment_id:         payout.shipment_id,
            gross_amount_cents:  payout.gross_amount_cents,
            commission_rate:     payout.commission_rate.to_s,
            commission_cents:    payout.commission_cents,
            amount_cents:        payout.amount_cents,
            currency:            payout.currency,
            state:               payout.state,
            paid_at:             payout.paid_at&.iso8601,
            created_at:          payout.created_at.iso8601,
            origin:              cargo.pickup_address,
            destination:         cargo.delivery_address,
            shipper_name:        shipper.company_name.presence || shipper.user.full_name
          }
        end
      end
    end
  end
end
