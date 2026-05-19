# frozen_string_literal: true

# Renames the Shipment intermediate state `quoted` → `offered` to match the
# 2026-05-19 domain rename (REF-BE-00002). Updates the CHECK constraint plus
# any pre-existing rows on `shipments` and `tracking_events`.
class RenameShipmentQuotedState < ActiveRecord::Migration[8.1]
  def up
    if check_constraint_exists?(:shipments, name: "shipments_status_check")
      remove_check_constraint :shipments, name: "shipments_status_check"
    end

    execute "UPDATE shipments SET status = 'offered' WHERE status = 'quoted'"
    execute "UPDATE tracking_events SET from_status = 'offered' WHERE from_status = 'quoted'"
    execute "UPDATE tracking_events SET to_status = 'offered' WHERE to_status = 'quoted'"

    add_check_constraint :shipments,
                         "status IN ('draft','offered','accepted','in_transit','delivered','settled','cancelled')",
                         name: "shipments_status_check"
  end

  def down
    if check_constraint_exists?(:shipments, name: "shipments_status_check")
      remove_check_constraint :shipments, name: "shipments_status_check"
    end

    execute "UPDATE tracking_events SET to_status = 'quoted' WHERE to_status = 'offered'"
    execute "UPDATE tracking_events SET from_status = 'quoted' WHERE from_status = 'offered'"
    execute "UPDATE shipments SET status = 'quoted' WHERE status = 'offered'"

    add_check_constraint :shipments,
                         "status IN ('draft','quoted','accepted','in_transit','delivered','settled','cancelled')",
                         name: "shipments_status_check"
  end

  private

  def check_constraint_exists?(table, name:)
    connection.check_constraints(table).any? { |c| c.options[:name] == name }
  end
end
