# frozen_string_literal: true

# Normalises Shipment into the fulfilment lifecycle used by the current domain:
# pending_payment -> to_pick_up -> in_transit -> delivered.
#
# This migration updates existing rows and the SQLite CHECK constraint so new
# records can only use the four valid states.
class UpdateShipmentStatusesForPaymentFlow < ActiveRecord::Migration[8.1]
  def up
    if check_constraint_exists?(:shipments, name: "shipments_status_check")
      remove_check_constraint :shipments, name: "shipments_status_check"
    end

    execute <<~SQL
      UPDATE shipments
      SET status = CASE status
        WHEN 'draft' THEN 'pending_payment'
        WHEN 'offered' THEN 'pending_payment'
        WHEN 'accepted' THEN 'pending_payment'
        WHEN 'settled' THEN 'delivered'
        WHEN 'cancelled' THEN 'delivered'
        ELSE status
      END
    SQL

    execute <<~SQL
      UPDATE tracking_events
      SET from_status = CASE from_status
        WHEN 'draft' THEN 'pending_payment'
        WHEN 'offered' THEN 'pending_payment'
        WHEN 'accepted' THEN 'pending_payment'
        WHEN 'settled' THEN 'delivered'
        WHEN 'cancelled' THEN 'delivered'
        ELSE from_status
      END,
      to_status = CASE to_status
        WHEN 'draft' THEN 'pending_payment'
        WHEN 'offered' THEN 'pending_payment'
        WHEN 'accepted' THEN 'pending_payment'
        WHEN 'settled' THEN 'delivered'
        WHEN 'cancelled' THEN 'delivered'
        ELSE to_status
      END
    SQL

    add_check_constraint :shipments,
                         "status IN ('pending_payment','to_pick_up','in_transit','delivered')",
                         name: "shipments_status_check"
  end

  def down
    if check_constraint_exists?(:shipments, name: "shipments_status_check")
      remove_check_constraint :shipments, name: "shipments_status_check"
    end

    execute <<~SQL
      UPDATE shipments
      SET status = CASE status
        WHEN 'pending_payment' THEN 'accepted'
        WHEN 'to_pick_up' THEN 'accepted'
        WHEN 'in_transit' THEN 'in_transit'
        WHEN 'delivered' THEN 'settled'
        ELSE status
      END
    SQL

    execute <<~SQL
      UPDATE tracking_events
      SET from_status = CASE from_status
        WHEN 'pending_payment' THEN 'accepted'
        WHEN 'to_pick_up' THEN 'accepted'
        WHEN 'delivered' THEN 'settled'
        ELSE from_status
      END,
      to_status = CASE to_status
        WHEN 'pending_payment' THEN 'accepted'
        WHEN 'to_pick_up' THEN 'accepted'
        WHEN 'delivered' THEN 'settled'
        ELSE to_status
      END
    SQL

    add_check_constraint :shipments,
                         "status IN ('draft','offered','accepted','in_transit','delivered','settled','cancelled')",
                         name: "shipments_status_check"
  end

  private

  def check_constraint_exists?(table, name:)
    connection.check_constraints(table).any? { |constraint| constraint.options[:name] == name }
  end
end
