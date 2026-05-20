# frozen_string_literal: true

# REQ-BE-00032 — Cargo publication lifecycle (US27).
#
# Reconciles the `cargos` table with the publication model: a Shipper-managed
# entity with a status FSM, a pickup window (replacing the single pickup_date),
# zone fields (mirroring TransportWindow's zone-string matching) and soft-cancel
# bookkeeping columns. SQLite-portable — Rails rebuilds the table for
# change_column_null / remove_column.
class AddCargoPublicationFields < ActiveRecord::Migration[8.1]
  def up
    add_column :cargos, :status, :string, null: false, default: "open"
    add_index  :cargos, :status

    add_column :cargos, :pickup_window_start, :datetime
    add_column :cargos, :pickup_window_end,   :datetime

    add_column :cargos, :pickup_zone,              :string
    add_column :cargos, :delivery_zone,            :string
    add_column :cargos, :pickup_zone_normalized,   :string
    add_column :cargos, :delivery_zone_normalized, :string
    add_index  :cargos, :pickup_zone_normalized
    add_index  :cargos, :delivery_zone_normalized

    add_column :cargos, :cancelled_at,        :datetime
    add_column :cargos, :cancellation_reason, :string

    # Single pickup_date → pickup window. Backfill collapses both bounds onto the old date.
    execute "UPDATE cargos SET pickup_window_start = pickup_date, pickup_window_end = pickup_date"
    change_column_null :cargos, :pickup_window_start, false
    change_column_null :cargos, :pickup_window_end,   false
    remove_column :cargos, :pickup_date, :datetime

    change_column_null :cargos, :volume_cm3, true # US27: volume optional
  end

  def down
    add_column :cargos, :pickup_date, :datetime
    execute "UPDATE cargos SET pickup_date = pickup_window_start"
    change_column_null :cargos, :pickup_date, false
    change_column_null :cargos, :volume_cm3, false
    remove_column :cargos, :status
    remove_column :cargos, :pickup_window_start
    remove_column :cargos, :pickup_window_end
    remove_column :cargos, :pickup_zone
    remove_column :cargos, :delivery_zone
    remove_column :cargos, :pickup_zone_normalized
    remove_column :cargos, :delivery_zone_normalized
    remove_column :cargos, :cancelled_at
    remove_column :cargos, :cancellation_reason
  end
end
