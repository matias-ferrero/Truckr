# frozen_string_literal: true

# Reverts the Shipment status surface back to the canonical FSM locked by
# ADR-012 (`accepted -> in_transit -> delivered`, plus terminal `cancelled`).
#
# The previous migration (20260524000000) leaked UI labels into the FSM as
# `pending_payment` / `to_pick_up`, which contradicts ADR-012 and the glossary
# (Envío vs. the UI label "A recoger"). It also collapsed the original
# `cancelled` / `settled` terminal rows into `delivered`, so the down-mapping
# here cannot recover them — acceptable: there is no production data.
class RevertShipmentStatusesToCanonicalFsm < ActiveRecord::Migration[8.1]
  def up
    if check_constraint_exists?(:shipments, name: "shipments_status_check")
      remove_check_constraint :shipments, name: "shipments_status_check"
    end

    execute <<~SQL
      UPDATE shipments
      SET status = CASE status
        WHEN 'pending_payment' THEN 'accepted'
        WHEN 'to_pick_up'      THEN 'accepted'
        ELSE status
      END
    SQL

    execute <<~SQL
      UPDATE tracking_events
      SET from_status = CASE from_status
        WHEN 'pending_payment' THEN 'accepted'
        WHEN 'to_pick_up'      THEN 'accepted'
        ELSE from_status
      END,
      to_status = CASE to_status
        WHEN 'pending_payment' THEN 'accepted'
        WHEN 'to_pick_up'      THEN 'accepted'
        ELSE to_status
      END
    SQL

    add_check_constraint :shipments,
                         "status IN ('accepted','in_transit','delivered','cancelled')",
                         name: "shipments_status_check"

    change_column_default :shipments, :status, from: "draft", to: "accepted"
  end

  def down
    change_column_default :shipments, :status, from: "accepted", to: "draft"

    if check_constraint_exists?(:shipments, name: "shipments_status_check")
      remove_check_constraint :shipments, name: "shipments_status_check"
    end

    execute <<~SQL
      UPDATE shipments
      SET status = CASE status
        WHEN 'accepted'  THEN 'pending_payment'
        WHEN 'cancelled' THEN 'delivered'
        ELSE status
      END
    SQL

    execute <<~SQL
      UPDATE tracking_events
      SET from_status = CASE from_status
        WHEN 'accepted'  THEN 'pending_payment'
        WHEN 'cancelled' THEN 'delivered'
        ELSE from_status
      END,
      to_status = CASE to_status
        WHEN 'accepted'  THEN 'pending_payment'
        WHEN 'cancelled' THEN 'delivered'
        ELSE to_status
      END
    SQL

    add_check_constraint :shipments,
                         "status IN ('pending_payment','to_pick_up','in_transit','delivered')",
                         name: "shipments_status_check"
  end

  private

  def check_constraint_exists?(table, name:)
    connection.check_constraints(table).any? { |constraint| constraint.options[:name] == name }
  end
end
