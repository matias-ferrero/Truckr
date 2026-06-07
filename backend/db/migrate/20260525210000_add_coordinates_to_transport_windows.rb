# frozen_string_literal: true

class AddCoordinatesToTransportWindows < ActiveRecord::Migration[7.1]
  # Default coordinates used to backfill pre-existing transport windows that
  # were created before geocoding existed. Obelisco, Buenos Aires (CABA).
  BACKFILL_LAT = -34.603722
  BACKFILL_LNG = -58.381592

  def up
    # Add the columns nullable first so the NOT NULL constraint does not fail
    # against rows that already exist in the table.
    add_column :transport_windows, :origin_lat,      :decimal, precision: 9, scale: 6
    add_column :transport_windows, :origin_lng,      :decimal, precision: 9, scale: 6
    add_column :transport_windows, :destination_lat, :decimal, precision: 9, scale: 6
    add_column :transport_windows, :destination_lng, :decimal, precision: 9, scale: 6

    # Backfill origin coordinates for existing rows. Destination columns stay
    # nullable, so they need no backfill.
    execute(<<~SQL.squish)
      UPDATE transport_windows
      SET origin_lat = #{BACKFILL_LAT},
          origin_lng = #{BACKFILL_LNG}
      WHERE origin_lat IS NULL OR origin_lng IS NULL
    SQL

    # Now that every row has a value, enforce NOT NULL on origin coordinates.
    change_column_null :transport_windows, :origin_lat, false
    change_column_null :transport_windows, :origin_lng, false
  end

  def down
    remove_column :transport_windows, :origin_lat
    remove_column :transport_windows, :origin_lng
    remove_column :transport_windows, :destination_lat
    remove_column :transport_windows, :destination_lng
  end
end
