class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.references :carrier,   null: false, foreign_key: true
      t.string  :plate,        null: false
      t.integer :capacity_kg,  null: false
      t.string  :vehicle_type, null: false, default: "truck_small"
      t.boolean :gps_enabled,  null: false, default: false
      t.timestamps
    end

    add_index :vehicles, :plate, unique: true
  end
end
