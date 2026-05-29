# frozen_string_literal: true

class AddCoordinatesToTransportWindows < ActiveRecord::Migration[7.1]
  def change
    add_column :transport_windows, :origin_lat,      :decimal, precision: 9, scale: 6, null: false
    add_column :transport_windows, :origin_lng,      :decimal, precision: 9, scale: 6, null: false
    add_column :transport_windows, :destination_lat, :decimal, precision: 9, scale: 6, null: true
    add_column :transport_windows, :destination_lng, :decimal, precision: 9, scale: 6, null: true
  end
end
