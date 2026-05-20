# frozen_string_literal: true

module Api
  # CargosController — the Shipper-facing Cargo publication lifecycle (US27 /
  # REQ-BE-00032). Six endpoints: index / show / create / update / destroy /
  # matches.
  #
  # `matches` runs zone-string matching (see plan §2.3 — no Haversine, no
  # distance_km): a TransportWindow matches a Cargo when it is active, has no
  # contending CargoOffer, its zones substring-match the Cargo's zones, its
  # availability overlaps the pickup window, and its vehicle can carry the
  # weight.
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
        cargo, params: { matches: matches_scope(cargo).to_a }
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

      ActiveRecord::Base.transaction do
        @cargo.transition_to!(:cancelled, reason: params[:reason])
        @cargo.cargo_offers.where(status: "pending").find_each do |offer|
          offer.transition_to!(:expired)
        end
      end
      head :no_content
    end

    # GET /api/cargos/:id/matches
    def matches
      authorize @cargo
      render_collection(CargoMatchResource, matches_scope(@cargo))
    end

    private

    def set_cargo
      @cargo = Cargo.find(params[:id])
    end

    def cargo_params
      params.require(:cargo).permit(
        :cargo_description, :pickup_address, :delivery_address,
        :pickup_zone, :delivery_zone, :pickup_window_start, :pickup_window_end,
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

    # Zone-string matching — see plan §2.3. No Haversine, no distance_km.
    # A TransportWindow matches when it is active, holds no pending/accepted
    # CargoOffer, its normalized zones contain the Cargo's normalized zones,
    # its availability overlaps the pickup window and its vehicle can carry
    # the cargo weight. Ordered by availability.
    def matches_scope(cargo)
      blocked = CargoOffer.where(status: %w[pending accepted]).select(:transport_window_id)

      TransportWindow.active.where.not(id: blocked)
        .ransack(
          origin_zone_normalized_cont:      cargo.pickup_zone_normalized,
          destination_zone_normalized_cont: cargo.delivery_zone_normalized,
          available_from_lteq:              cargo.pickup_window_end,
          available_to_gteq:                cargo.pickup_window_start
        ).result(distinct: true)
        .joins(:vehicle).where("vehicles.max_load_kg >= ?", cargo.weight_kg)
        .includes(vehicle: { carrier: :user }).order(:available_from)
    end
  end
end
