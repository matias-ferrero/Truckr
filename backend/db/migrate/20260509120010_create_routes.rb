class CreateRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :routes do |t|
      t.references :shipment, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.text     :polyline               # Google Maps encoded polyline
      t.integer  :distance_m
      t.integer  :duration_s
      t.string   :provider, null: false, default: "google_maps_directions"
      t.datetime :calculated_at

      t.timestamps
    end
  end
end
