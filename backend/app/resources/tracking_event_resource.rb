# frozen_string_literal: true

# Alba resource for a TrackingEvent row in the Shipper Dashboard activity feed
# (GET /api/shippers/me/activity). Mirrors the per-event shape already emitted
# inline by ShipmentDetailResource#tracking_events, plus the owning
# `shipment_id` so the frontend can deep-link each entry back to its shipment.
class TrackingEventResource
  include Alba::Resource

  attributes :id, :shipment_id, :kind

  attribute :occurred_at do |event|
    event.recorded_at
  end

  attribute :from_status do |event|
    event.from_status if event.kind == "status_change"
  end

  attribute :to_status do |event|
    event.to_status if event.kind == "status_change"
  end
end
