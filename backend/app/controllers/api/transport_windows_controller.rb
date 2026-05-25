# frozen_string_literal: true

module Api
  # TransportWindowsController — REST endpoint for searching available transport capacity.
  # Filters by origin/destination zone (diacritic-insensitive) and availability date range.
  # Public endpoint: no authentication, but Pundit's `policy_scope` still gates
  # the underlying TransportWindow relation (active rows only) so the
  # `verify_policy_scoped` invariant from Api::BaseController holds.
  class TransportWindowsController < Api::BaseController
    def index
      params.require(%i[origin_province destination_province date_from date_to])

      # `policy_scope` returns `TransportWindow.active` (see TransportWindowPolicy::Scope).
      # Called up-front so the `verify_policy_scoped` after_action invariant holds
      # even on the early-return error paths below.
      base_scope = policy_scope(TransportWindow)

      date_from = Date.iso8601(params[:date_from])
      date_to   = Date.iso8601(params[:date_to])

      if date_from > date_to
        return render_error(
          code: "unprocessable",
          status: :unprocessable_entity,
          details: { date_range: [ "date_from must be <= date_to" ] }
        )
      end

      # Ransack narrows the active scope by province (diacritic-insensitive substring match
      # against normalized columns) and by date-range overlap.
      ransack_params = {
        origin_province_normalized_cont:      params[:origin_province],
        destination_province_normalized_cont: params[:destination_province],
        available_from_lteq:                  date_to.end_of_day,
        available_to_gteq:                    date_from.beginning_of_day
      }
      ransack_windows = base_scope.ransack(ransack_params).result(distinct: true)

      # Open-destination windows (destination_province IS NULL) match any destination query:
      # a Carrier offering "any destination within their radius" should appear when a
      # Shipper filters by a specific destination.
      windows = if params[:destination_province].present?
        open_dest = base_scope.ransack(
          ransack_params.except(:destination_province_normalized_cont)
        ).result(distinct: true).where(destination_province_normalized: nil)
        ransack_windows.or(open_dest)
      else
        ransack_windows
      end

      windows = windows.includes(vehicle: :carrier).order(:available_from)

      windows_by_carrier = windows.group_by { |w| w.vehicle.carrier_id }
      carrier_scope = Carrier.includes(:user).where(id: windows_by_carrier.keys).order(:legal_name)

      @pagy, carriers = pagy(carrier_scope)
      render json: CarrierSearchResource.new(
        carriers,
        params: { windows_by_carrier: windows_by_carrier }
      ).serialize
    end
  end
end
