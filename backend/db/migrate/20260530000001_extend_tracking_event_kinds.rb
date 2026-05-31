# frozen_string_literal: true

# Adds dedicated event kinds for the full shipment lifecycle so the timeline
# can display meaningful labels without the generic status_change adapter.
#
# New kinds seeded manually until REQ-BE-00038 wires FSM callbacks to emit them:
#   shipment_accepted   — Shipment created (offer accepted by shipper)
#   payment_escrowed    — Shipper's payment held in escrow
#   payment_failed      — Payment attempt failed
#
# Kinds that REQ-BE-00038 will also activate (added now to avoid a future migration):
#   shipment_in_transit — Carrier started transit (replaces status_change accepted→in_transit)
#   shipment_delivered  — Carrier confirmed delivery (replaces status_change in_transit→delivered)
#   shipment_cancelled  — Shipment cancelled (replaces status_change *→cancelled)
class ExtendTrackingEventKinds < ActiveRecord::Migration[8.1]
  OLD_CONSTRAINT = "kind IN ('status_change','gps_update','note')"
  NEW_CONSTRAINT = "kind IN ('status_change','gps_update','note'," \
                   "'shipment_accepted','shipment_in_transit','shipment_delivered'," \
                   "'shipment_cancelled','payment_escrowed','payment_failed')"

  def up
    remove_check_constraint :tracking_events, name: "tracking_events_kind_check"
    add_check_constraint :tracking_events, NEW_CONSTRAINT,
                         name: "tracking_events_kind_check"
  end

  def down
    remove_check_constraint :tracking_events, name: "tracking_events_kind_check"
    add_check_constraint :tracking_events, OLD_CONSTRAINT,
                         name: "tracking_events_kind_check"
  end
end
