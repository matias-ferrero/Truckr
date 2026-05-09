class CreateTransportWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :transport_windows do |t|
      t.references :vehicle,
                   null: false,
                   foreign_key: { to_table: :vehicles, on_delete: :cascade }
      t.string  :origin_zone,      null: false
      t.string  :destination_zone, null: false
      t.decimal :price_per_km,     null: false, precision: 10, scale: 2
      t.integer :max_km,           null: false
      t.datetime :available_from,  null: false
      t.datetime :available_to,    null: false
      t.boolean :active,           null: false, default: true
      t.timestamps
    end

    add_index :transport_windows, :active
    add_index :transport_windows, [:available_from, :available_to]
    add_index :transport_windows, [:vehicle_id, :available_from, :available_to],
              name: "idx_tw_on_vehicle_and_window"
  end
end
