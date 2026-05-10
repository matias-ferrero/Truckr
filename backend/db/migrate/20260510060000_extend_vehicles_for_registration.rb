# frozen_string_literal: true

# REQ-BE-00009 — extend `vehicles` for the public registration form.
# Renames `capacity_kg` (int) → `max_load_kg` (decimal) and adds make / model
# / year / dimensions / description. No `unique index on carrier_id` (see
# Decisión A in the joint plan — multi-vehicle from day one).
class ExtendVehiclesForRegistration < ActiveRecord::Migration[8.1]
  def up
    rename_column :vehicles, :capacity_kg, :max_load_kg
    change_column :vehicles, :max_load_kg, :decimal, precision: 10, scale: 2, null: false, default: 0

    add_column :vehicles, :make,        :string,  null: false, default: ""
    add_column :vehicles, :model,       :string,  null: false, default: ""
    add_column :vehicles, :year,        :integer
    add_column :vehicles, :length_cm,   :integer
    add_column :vehicles, :width_cm,    :integer
    add_column :vehicles, :height_cm,   :integer
    add_column :vehicles, :volume_cm3,  :bigint
    add_column :vehicles, :description, :text

    add_index :vehicles, :carrier_id, name: "index_vehicles_on_carrier_id_lookup",
                                      if_not_exists: true
  end

  def down
    remove_index  :vehicles, name: "index_vehicles_on_carrier_id_lookup", if_exists: true
    remove_column :vehicles, :description
    remove_column :vehicles, :volume_cm3
    remove_column :vehicles, :height_cm
    remove_column :vehicles, :width_cm
    remove_column :vehicles, :length_cm
    remove_column :vehicles, :year
    remove_column :vehicles, :model
    remove_column :vehicles, :make
    change_column :vehicles, :max_load_kg, :integer, null: false, default: 0
    rename_column :vehicles, :max_load_kg, :capacity_kg
  end
end
