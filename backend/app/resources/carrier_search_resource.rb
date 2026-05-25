# frozen_string_literal: true

# Alba serializer for the carrier search endpoint
# (`GET /api/transport_windows`). Each Carrier is rendered alongside its
# matching `transport_windows` — the subset of the carrier's published
# windows that satisfy the search filters.
#
# The controller pre-computes `windows_by_carrier` (a `Hash<carrier_id =>
# [TransportWindow]>`) and passes it via Alba's `params:` so the resource
# does not have to re-query.
class CarrierSearchResource
  include Alba::Resource

  attributes :legal_name, :base_city, :province, :rating_avg, :completed_shipments

  attribute :id do |carrier|
    carrier.id
  end

  attribute :display_name do |carrier|
    carrier.legal_name.presence || carrier.user&.full_name || carrier.user&.email
  end

  attribute :transport_windows do |carrier|
    windows = params[:windows_by_carrier]&.fetch(carrier.id, []) || []
    windows.map do |window|
      {
        id:                   window.id,
        origin_province:      window.origin_province,
        origin_locality:      window.origin_locality,
        destination_province: window.destination_province,
        destination_locality: window.destination_locality,
        price_per_km:         window.price_per_km,
        max_km:               window.max_km,
        available_from:       window.available_from,
        available_to:         window.available_to,
        active:               window.active
      }
    end
  end
end
