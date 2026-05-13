# frozen_string_literal: true

module Api
  module Carriers
    module Me
      # Authenticated CRUD on the current carrier's transport windows.
      #   GET    /api/carriers/me/transport_windows
      #   GET    /api/carriers/me/transport_windows/:id
      #   POST   /api/carriers/me/transport_windows
      #   PATCH  /api/carriers/me/transport_windows/:id
      #   DELETE /api/carriers/me/transport_windows/:id  (hard delete; deactivate via PATCH active=false)
      class TransportWindowsController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_carrier!

        def index
          render_collection(
            TransportWindowResource,
            policy_scope(TransportWindow).includes(:vehicle).order(available_from: :asc)
          )
        end

        def show
          window = scoped_window
          authorize window
          render json: TransportWindowResource.new(window).serialize
        end

        def create
          vehicle = current_carrier.vehicles.find(create_params[:vehicle_id])
          window  = vehicle.transport_windows.build(create_params.except(:vehicle_id))
          authorize window
          window.save!
          render json: TransportWindowResource.new(window).serialize, status: :created
        end

        def update
          window = scoped_window
          authorize window
          window.update!(update_params)
          render json: TransportWindowResource.new(window).serialize
        end

        def destroy
          window = scoped_window
          authorize window
          window.destroy!
          head :no_content
        end

        private

        def scoped_window
          current_carrier.transport_windows.includes(:vehicle).find(params[:id])
        end

        def create_params
          params.require(:transport_window).permit(
            :vehicle_id, :origin_zone, :destination_zone,
            :price_per_km, :max_km, :available_from, :available_to
          )
        end

        def update_params
          params.require(:transport_window).permit(
            :origin_zone, :destination_zone,
            :price_per_km, :max_km, :available_from, :available_to, :active
          )
        end
      end
    end
  end
end
