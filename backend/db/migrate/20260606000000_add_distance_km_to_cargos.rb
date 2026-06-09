# frozen_string_literal: true

class AddDistanceKmToCargos < ActiveRecord::Migration[8.1]
  def change
    add_column :cargos, :distance_km, :decimal, precision: 10, scale: 2
  end
end
