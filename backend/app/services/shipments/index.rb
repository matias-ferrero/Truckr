# frozen_string_literal: true

# Shipments::Index — query helper for the Carrier / Shipper shipment index
# endpoints (REQ-BE-00035 §3.1, §3.2).
#
# Two-step query (AC11, ≤ 3 SQL statements total):
#   1. Aggregate sort: LEFT JOIN tracking_events + GROUP BY shipments.id +
#      ORDER BY COALESCE(MAX(tracking_events.recorded_at), shipments.updated_at) DESC.
#      SQLite-clean (B-tree index `index_tracking_events_on_shipment_id_and_recorded_at`
#      already covers the aggregation; no migration required).
#   2. Eager load: Shipment.where(id: <ordered_ids>).eager_load(...) for the
#      association graph (payments, tracking_events, cargo_offer → cargo →
#      shipper, transport_window → vehicle → carrier).
#
# Returns an Array<Shipment> in the order computed by step 1.
module Shipments
  module Index
    EAGER_LOADS = {
      cargo_offer: [
        :carrier,
        { cargo: :shipper },
        { transport_window: { vehicle: :carrier } }
      ]
    }.freeze

    module_function

    def for(scope:)
      ordered_ids = scope
                    .unscope(:order)
                    .left_outer_joins(:tracking_events)
                    .group("shipments.id")
                    .order(
                      Arel.sql(
                        "COALESCE(MAX(tracking_events.recorded_at), shipments.updated_at) DESC"
                      )
                    )
                    .pluck("shipments.id")

      return [] if ordered_ids.empty?

      records = Shipment
                .where(id: ordered_ids)
                .eager_load(:payments, :tracking_events, :reviews, **EAGER_LOADS)
                .to_a

      by_id = records.index_by(&:id)
      ordered_ids.filter_map { |id| by_id[id] }
    end
  end
end
