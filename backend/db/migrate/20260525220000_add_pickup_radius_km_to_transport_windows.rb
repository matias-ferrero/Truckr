# frozen_string_literal: true

class AddPickupRadiusKmToTransportWindows < ActiveRecord::Migration[7.1]
  def change
    add_column :transport_windows, :pickup_radius_km, :integer, null: false, default: 10
  end
end
