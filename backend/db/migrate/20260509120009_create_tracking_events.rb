class CreateTrackingEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :tracking_events do |t|
      t.references :shipment, null: false, foreign_key: { on_delete: :cascade }

      t.string :kind, null: false # status_change | gps_update | note
      t.string :from_status
      t.string :to_status

      t.decimal :lat, precision: 9, scale: 6
      t.decimal :lng, precision: 9, scale: 6

      t.text     :metadata
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :tracking_events, [ :shipment_id, :recorded_at ]
    add_index :tracking_events, :kind
    add_check_constraint :tracking_events,
      "kind IN ('status_change','gps_update','note')",
      name: "tracking_events_kind_check"
  end
end
