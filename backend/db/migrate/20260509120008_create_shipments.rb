class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.references :quote, null: false, foreign_key: { on_delete: :restrict }, index: { unique: true }

      t.string :status, null: false, default: "draft"

      t.datetime :picked_up_at
      t.datetime :delivered_at
      t.datetime :settled_at
      t.datetime :cancelled_at
      t.string   :cancellation_reason

      t.datetime :discarded_at # soft-delete (ADR-009)

      t.timestamps
    end

    add_index :shipments, :status
    add_index :shipments, :discarded_at

    add_check_constraint :shipments,
      "status IN ('draft','quoted','accepted','in_transit','delivered','settled','cancelled')",
      name: "shipments_status_check"
  end
end
