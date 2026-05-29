# frozen_string_literal: true

module Api
  # CargosController — the Shipper-facing Cargo publication lifecycle (US27 /
  # REQ-BE-00032). Six endpoints: index / show / create / update / destroy /
  # matches.
  #
  # `matches` runs pure address-driven matching (US52 / REQ-BE-00039 /
  # ADR-014): a TransportWindow matches a Cargo when it is active, has no
  # contending CargoOffer, availability overlaps the pickup window, vehicle
  # can carry the weight, its origin pin is within `pickup_radius_km` of the
  # cargo's pickup point (Haversine), and — if the window has a destination —
  # its destination pin is within `dropoff_radius_km` of the cargo's delivery
  # point. Open-destination windows skip the dropoff filter.
  #
  # `destroy` is a soft-cancel cascade: the Cargo transitions to `cancelled`
  # and every `pending` sibling CargoOffer is expired, all in one transaction.
  class CargosController < Api::BaseController
    before_action :authenticate_user!
    before_action :require_shipper!
    before_action :set_cargo, only: %i[show update destroy matches]

    # GET /api/cargos
    def index
      render_collection(
        CargoResource,
        policy_scope(Cargo).with_status(params[:status]).order(created_at: :desc)
      )
    end

    # GET /api/cargos/:id
    def show
      authorize @cargo
      render json: CargoResource.new(@cargo).serialize
    end

    # POST /api/cargos
    def create
      authorize Cargo
      cargo = current_shipper.cargos.create!(cargo_params)
      render json: CargoResource.new(
        cargo, params: { matches: cargo.matching_windows.to_a }
      ).serialize, status: :created
    end

    # PATCH /api/cargos/:id
    def update
      authorize @cargo
      return render_cargo_locked(:not_editable) unless @cargo.editable?

      @cargo.update!(cargo_params)
      render json: CargoResource.new(@cargo).serialize
    end

    # DELETE /api/cargos/:id — soft-cancel cascade.
    def destroy
      authorize @cargo
      return render_cargo_locked(:not_cancellable) unless @cargo.cancellable?

      @cargo.transition_to!(:cancelled, reason: params[:reason])
      head :no_content
    end

    # GET /api/cargos/:id/matches
    #
    # `sort=distance` re-orders by Haversine distance from the cargo's pickup
    # point ascending (US5 AC8). Default ordering remains by `available_from`.
    def matches
      authorize @cargo
      windows = @cargo.matching_windows
      windows = windows.order_by_distance_to(@cargo) if params[:sort] == "distance"
      render_collection(CargoMatchResource, windows)
    end

    private

    def set_cargo
      @cargo = Cargo.find(params[:id])
    end

    def cargo_params
      params.require(:cargo).permit(
        :cargo_description, :pickup_address, :delivery_address,
        :pickup_locality, :pickup_admin_area,
        :delivery_locality, :delivery_admin_area,
        :pickup_lat, :pickup_lng, :delivery_lat, :delivery_lng,
        :pickup_window_start, :pickup_window_end,
        :weight_kg, :volume_cm3, :declared_value_cents
      )
    end

    def render_cargo_locked(detail_key)
      render_error(
        code: "cargo_locked",
        status: :unprocessable_entity,
        message: I18n.t("errors.cargo_locked"),
        details: { status: [ I18n.t("errors.#{detail_key}") ] }
      )
    end
  end
end
