# frozen_string_literal: true

module Api
  module Carriers
    module Me
      # Authenticated CRUD on the current carrier's fleet.
      #   GET    /api/carriers/me/vehicles
      #   GET    /api/carriers/me/vehicles/:id
      #   POST   /api/carriers/me/vehicles
      #   PATCH  /api/carriers/me/vehicles/:id
      #   DELETE /api/carriers/me/vehicles/:id
      class VehiclesController < Api::BaseController
        before_action :authenticate_user!
        before_action :require_carrier!

        def index
          @pagy, vehicles = pagy(policy_scope(::Vehicle).includes(photos_attachments: :blob))
          render json: VehicleResource.list.new(vehicles).serialize
        end

        def show
          vehicle = current_carrier.vehicles.find(params[:id])
          authorize vehicle
          render json: VehicleResource.new(vehicle).serialize
        end

        def create
          vehicle = current_carrier.vehicles.build(vehicle_params)
          authorize vehicle
          vehicle.save!
          render json: VehicleResource.new(vehicle).serialize, status: :created
        end

        def update
          vehicle = current_carrier.vehicles.find(params[:id])
          authorize vehicle
          # `remove_photo_ids` is a virtual param the form uses to detach
          # specific photos in the same PATCH that may also add new ones.
          # Strip it before update! so AR doesn't see an unknown attribute,
          # then resolve the IDs against this vehicle's attachments only —
          # never trust the IDs to belong to the caller.
          remove_ids = remove_photo_ids
          attrs = vehicle_params
          vehicle.update!(attrs)
          if remove_ids.any?
            vehicle.photos.attachments.where(id: remove_ids).each(&:purge_later)
          end
          render json: VehicleResource.new(vehicle).serialize
        end

        def destroy
          vehicle = current_carrier.vehicles.find(params[:id])
          authorize vehicle
          vehicle.destroy!
          head :no_content
        end

        private

        def vehicle_params
          params.require(:vehicle).permit(
            :make, :model, :year, :plate, :vehicle_type, :max_load_kg,
            :length_cm, :width_cm, :height_cm, :description, :gps_enabled,
            photos: []
          )
        end

        # Read + coerce the virtual `remove_photo_ids` array. FormData ships
        # values as strings; cast to Integer and drop blanks before the
        # subsequent `where(id: …)` so the SQL doesn't widen unnecessarily.
        def remove_photo_ids
          raw = params.dig(:vehicle, :remove_photo_ids)
          Array(raw).filter_map { |v| Integer(v, exception: false) }
        end
      end
    end
  end
end
