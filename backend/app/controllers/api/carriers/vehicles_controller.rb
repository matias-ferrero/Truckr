# frozen_string_literal: true

module Api
  module Carriers
    # Public read endpoints for a specific carrier's fleet.
    #   GET /api/carriers/:carrier_id/vehicles
    #   GET /api/carriers/:carrier_id/vehicles/:id
    # Consumed by the public carrier profile page (REQ-FE-00014).
    class VehiclesController < Api::BaseController
      # Public read — no Pundit scope needed (the nesting under `:carrier_id`
      # already restricts the rows). `VehiclePolicy::Scope` is owner-only and
      # would zero out an unauthenticated request, so skip the invariant.
      skip_after_action :verify_authorized, raise: false
      skip_after_action :verify_policy_scoped, raise: false

      def index
        carrier = ::Carrier.find(params[:carrier_id])
        @pagy, vehicles = pagy(carrier.vehicles.includes(photos_attachments: :blob))
        render json: VehicleResource.list.new(vehicles).serialize
      end

      def show
        vehicle = ::Vehicle.find(params[:id])
        render json: VehicleResource.new(vehicle).serialize
      end
    end
  end
end
