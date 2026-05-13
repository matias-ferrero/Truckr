class AddNormalizedSearchFieldsToTransportWindows < ActiveRecord::Migration[8.1]
  def change
    add_column :transport_windows, :origin_zone_normalized, :string
    add_column :transport_windows, :destination_zone_normalized, :string

    add_index :transport_windows, :origin_zone_normalized
    add_index :transport_windows, :destination_zone_normalized
  end
end
