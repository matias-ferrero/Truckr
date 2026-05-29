# frozen_string_literal: true

# REQ-BE-00039 / ADR-014: address-driven matching.
# Destructive — truncates the fulfilment chain before swapping schemas. Coursework
# data only; demo flows re-seed via `db:seed` after migration.
class AddressDrivenMatching < ActiveRecord::Migration[7.1]
  def up
    # FK chain: tracking_events → payments → routes → shipments → cargo_offers → cargos / transport_windows
    execute "DELETE FROM tracking_events"
    execute "DELETE FROM payments"
    execute "DELETE FROM routes"
    execute "DELETE FROM shipments"
    execute "DELETE FROM cargo_offers"
    execute "DELETE FROM cargos"
    execute "DELETE FROM transport_windows"

    change_table :transport_windows do |t|
      t.remove_index name: :index_transport_windows_on_origin_province_normalized
      t.remove_index name: :index_transport_windows_on_destination_province_normalized
      t.remove_index name: :index_transport_windows_on_origin_locality_normalized
      t.remove_index name: :index_transport_windows_on_destination_locality_normalized

      t.remove :origin_province
      t.remove :origin_province_normalized
      t.remove :origin_locality
      t.remove :origin_locality_normalized
      t.remove :destination_province
      t.remove :destination_province_normalized
      t.remove :destination_locality
      t.remove :destination_locality_normalized

      t.text :origin_address,        null: false
      t.text :origin_locality,       null: false
      t.text :origin_admin_area,     null: false
      t.text :destination_address
      t.text :destination_locality
      t.text :destination_admin_area
      t.integer :dropoff_radius_km
    end

    change_table :cargos do |t|
      t.remove_index name: :index_cargos_on_pickup_zone_normalized
      t.remove_index name: :index_cargos_on_delivery_zone_normalized

      t.remove :pickup_zone
      t.remove :pickup_zone_normalized
      t.remove :delivery_zone
      t.remove :delivery_zone_normalized

      t.text :pickup_locality,    null: false
      t.text :pickup_admin_area,  null: false
      t.text :delivery_locality,  null: false
      t.text :delivery_admin_area, null: false
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "AddressDrivenMatching is destructive (truncates fulfilment chain); re-seed instead of rolling back."
  end
end
