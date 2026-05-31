# frozen_string_literal: true

# Removes pending_payment as a first-class FSM state (ADR-012 amendment).
#
# Canonical FSM is now: accepted → in_transit → delivered
# (cancelled is terminal from accepted or in_transit)
#
# Shipments previously in pending_payment (payment escrowed, carrier hasn't
# started transit yet) revert to accepted. The escrowed Payment row preserves
# the audit trail; AvailableActions continues to show "start_transit" for the
# carrier when payment_escrowed? is true.
class RemovePendingPaymentFromShipments < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE shipments SET status = 'accepted' WHERE status = 'pending_payment'"
    remove_check_constraint :shipments, name: "shipments_status_check"
    add_check_constraint :shipments,
                         "status IN ('accepted','in_transit','delivered','cancelled')",
                         name: "shipments_status_check"
    remove_column :shipments, :payment_received_at
  end

  def down
    add_column :shipments, :payment_received_at, :datetime
    remove_check_constraint :shipments, name: "shipments_status_check"
    add_check_constraint :shipments,
                         "status IN ('accepted','pending_payment','in_transit','delivered','cancelled')",
                         name: "shipments_status_check"
    execute <<~SQL
      UPDATE shipments
      SET status = 'pending_payment'
      WHERE status = 'accepted'
        AND id IN (SELECT DISTINCT shipment_id FROM payments WHERE state = 'escrowed')
    SQL
  end
end
