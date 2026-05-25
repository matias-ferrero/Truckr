# frozen_string_literal: true

# Replaces the single `origin_zone` / `destination_zone` string columns with
# separate province + locality columns (nullable destination supports
# open-destination windows — see FIX-BE-00001 / glossary "Destino abierto").
class RefactorTransportWindowLocationFields < ActiveRecord::Migration[8.1]
  def up
    # destination_zone must become nullable before the rename so SQLite
    # preserves the null constraint on the resulting destination_province column.
    change_column_null :transport_windows, :destination_zone, true

    rename_column :transport_windows, :origin_zone,                :origin_province
    rename_column :transport_windows, :destination_zone,           :destination_province
    rename_column :transport_windows, :origin_zone_normalized,     :origin_province_normalized
    rename_column :transport_windows, :destination_zone_normalized, :destination_province_normalized

    add_column :transport_windows, :origin_locality,                :string
    add_column :transport_windows, :destination_locality,           :string
    add_column :transport_windows, :origin_locality_normalized,     :string
    add_column :transport_windows, :destination_locality_normalized, :string

    rename_index :transport_windows,
                 "index_transport_windows_on_origin_zone_normalized",
                 "index_transport_windows_on_origin_province_normalized"
    rename_index :transport_windows,
                 "index_transport_windows_on_destination_zone_normalized",
                 "index_transport_windows_on_destination_province_normalized"

    add_index :transport_windows, :origin_locality_normalized
    add_index :transport_windows, :destination_locality_normalized
  end

  def down
    remove_index :transport_windows, :destination_locality_normalized
    remove_index :transport_windows, :origin_locality_normalized

    rename_index :transport_windows,
                 "index_transport_windows_on_destination_province_normalized",
                 "index_transport_windows_on_destination_zone_normalized"
    rename_index :transport_windows,
                 "index_transport_windows_on_origin_province_normalized",
                 "index_transport_windows_on_origin_zone_normalized"

    remove_column :transport_windows, :destination_locality_normalized
    remove_column :transport_windows, :origin_locality_normalized
    remove_column :transport_windows, :destination_locality
    remove_column :transport_windows, :origin_locality

    rename_column :transport_windows, :destination_province_normalized, :destination_zone_normalized
    rename_column :transport_windows, :origin_province_normalized,      :origin_zone_normalized
    rename_column :transport_windows, :destination_province,            :destination_zone
    rename_column :transport_windows, :origin_province,                 :origin_zone

    change_column_null :transport_windows, :destination_zone, false
  end
end
