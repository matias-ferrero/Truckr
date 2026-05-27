# frozen_string_literal: true

# Adds `pending_payment` as a first-class FSM state (ADR-012 amendment).
# Previously `payment_state` was a derived attribute computed from the Payments
# table. The new FSM is:
#   accepted → pending_payment → in_transit → delivered
#   (cancelled is terminal from any non-terminal state)
class AddPendingPaymentToShipments < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :shipments, name: "shipments_status_check"
    add_column :shipments, :payment_received_at, :datetime
    add_check_constraint :shipments,
      "status IN ('accepted','pending_payment','in_transit','delivered','cancelled')",
      name: "shipments_status_check"
  end

  def down
    remove_check_constraint :shipments, name: "shipments_status_check"
    remove_column :shipments, :payment_received_at
    execute "UPDATE shipments SET status = 'accepted' WHERE status = 'pending_payment'"
    add_check_constraint :shipments,
      "status IN ('accepted','in_transit','delivered','cancelled')",
      name: "shipments_status_check"
  end
end
