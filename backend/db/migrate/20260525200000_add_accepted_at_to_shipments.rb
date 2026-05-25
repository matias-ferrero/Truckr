# frozen_string_literal: true

# Backfills the timestamp columns required by Shipment::STATUS_TIMESTAMP_COLUMNS.
# main's schema.rb already carries these columns (they were included in a schema
# regeneration before the dedicated migration was written), so the guards prevent
# duplicate-column errors on databases bootstrapped via db:schema:load.
class AddAcceptedAtToShipments < ActiveRecord::Migration[8.1]
  def change
    add_column :shipments, :accepted_at, :datetime unless column_exists?(:shipments, :accepted_at)
    add_column :shipments, :estimated_delivery_at, :datetime unless column_exists?(:shipments, :estimated_delivery_at)
    add_index  :shipments, :accepted_at unless index_exists?(:shipments, :accepted_at)
  end
end
