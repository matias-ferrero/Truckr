# frozen_string_literal: true

class AddOfferAndTransportWindowStatuses < ActiveRecord::Migration[8.1]
  def up
    add_column :cargo_offers, :accepted_at, :datetime
    add_column :cargo_offers, :rejected_at, :datetime

    add_column :transport_windows, :status, :string, null: false, default: "open"

    add_index :cargo_offers, :accepted_at
    add_index :cargo_offers, :rejected_at
    add_index :transport_windows, :status

    execute <<~SQL
      UPDATE transport_windows
      SET status = 'pending_offer'
      WHERE id IN (
        SELECT DISTINCT transport_window_id
        FROM cargo_offers
        WHERE status IN ('pending', 'accepted')
      )
    SQL
  end

  def down
    remove_index :transport_windows, :status
    remove_index :cargo_offers, :rejected_at
    remove_index :cargo_offers, :accepted_at

    remove_column :transport_windows, :status
    remove_column :cargo_offers, :rejected_at
    remove_column :cargo_offers, :accepted_at
  end
end
