# frozen_string_literal: true

class AddCoordinatesToCargos < ActiveRecord::Migration[7.1]
  def change
    add_column :cargos, :pickup_lat,   :decimal, precision: 9, scale: 6, null: false
    add_column :cargos, :pickup_lng,   :decimal, precision: 9, scale: 6, null: false
    add_column :cargos, :delivery_lat, :decimal, precision: 9, scale: 6, null: false
    add_column :cargos, :delivery_lng, :decimal, precision: 9, scale: 6, null: false
  end
end
