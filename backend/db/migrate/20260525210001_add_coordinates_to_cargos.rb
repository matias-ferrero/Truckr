# frozen_string_literal: true

class AddCoordinatesToCargos < ActiveRecord::Migration[7.1]
  # Default coordinates used to backfill pre-existing cargos that were created
  # before geocoding existed. Obelisco, Buenos Aires (CABA).
  BACKFILL_LAT = -34.603722
  BACKFILL_LNG = -58.381592

  def up
    # Add the columns nullable first so the NOT NULL constraint does not fail
    # against rows that already exist in the table.
    add_column :cargos, :pickup_lat,   :decimal, precision: 9, scale: 6
    add_column :cargos, :pickup_lng,   :decimal, precision: 9, scale: 6
    add_column :cargos, :delivery_lat, :decimal, precision: 9, scale: 6
    add_column :cargos, :delivery_lng, :decimal, precision: 9, scale: 6

    # Backfill coordinates for existing rows before enforcing NOT NULL.
    execute(<<~SQL.squish)
      UPDATE cargos
      SET pickup_lat   = #{BACKFILL_LAT},
          pickup_lng   = #{BACKFILL_LNG},
          delivery_lat = #{BACKFILL_LAT},
          delivery_lng = #{BACKFILL_LNG}
      WHERE pickup_lat IS NULL OR pickup_lng IS NULL
         OR delivery_lat IS NULL OR delivery_lng IS NULL
    SQL

    # Now that every row has a value, enforce NOT NULL.
    change_column_null :cargos, :pickup_lat,   false
    change_column_null :cargos, :pickup_lng,   false
    change_column_null :cargos, :delivery_lat, false
    change_column_null :cargos, :delivery_lng, false
  end

  def down
    remove_column :cargos, :pickup_lat
    remove_column :cargos, :pickup_lng
    remove_column :cargos, :delivery_lat
    remove_column :cargos, :delivery_lng
  end
end
