# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_19_130001) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.integer "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "cargo_offers", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.integer "cargo_id", null: false
    t.integer "carrier_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "ARS", null: false
    t.datetime "expires_at", null: false
    t.string "status", default: "pending", null: false
    t.integer "transport_window_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cargo_id"], name: "index_cargo_offers_on_cargo_id"
    t.index ["carrier_id"], name: "index_cargo_offers_on_carrier_id"
    t.index ["expires_at"], name: "index_cargo_offers_on_expires_at"
    t.index ["status"], name: "index_cargo_offers_on_status"
    t.index ["transport_window_id"], name: "index_cargo_offers_on_transport_window_id"
  end

  create_table "cargos", force: :cascade do |t|
    t.string "cancellation_reason"
    t.datetime "cancelled_at"
    t.text "cargo_description", null: false
    t.datetime "created_at", null: false
    t.integer "declared_value_cents", null: false
    t.string "delivery_address", null: false
    t.string "delivery_zone"
    t.string "delivery_zone_normalized"
    t.string "pickup_address", null: false
    t.datetime "pickup_window_end", null: false
    t.datetime "pickup_window_start", null: false
    t.string "pickup_zone"
    t.string "pickup_zone_normalized"
    t.integer "shipper_id", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.integer "volume_cm3"
    t.decimal "weight_kg", precision: 10, scale: 2, null: false
    t.index ["delivery_zone_normalized"], name: "index_cargos_on_delivery_zone_normalized"
    t.index ["pickup_zone_normalized"], name: "index_cargos_on_pickup_zone_normalized"
    t.index ["shipper_id"], name: "index_cargos_on_shipper_id"
    t.index ["status"], name: "index_cargos_on_status"
  end

  create_table "carriers", force: :cascade do |t|
    t.string "base_city"
    t.integer "completed_shipments", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "legal_name"
    t.string "province"
    t.decimal "rating_avg", precision: 3, scale: 2, default: "0.0", null: false
    t.integer "reviews_count", default: 0, null: false
    t.string "tax_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["province", "base_city"], name: "index_carriers_on_province_and_base_city"
    t.index ["tax_id"], name: "index_carriers_on_tax_id", unique: true, where: "tax_id IS NOT NULL"
    t.index ["user_id"], name: "index_carriers_on_user_id", unique: true
  end

  create_table "routes", force: :cascade do |t|
    t.datetime "calculated_at"
    t.datetime "created_at", null: false
    t.integer "distance_m"
    t.integer "duration_s"
    t.text "polyline"
    t.string "provider", default: "google_maps_directions", null: false
    t.integer "shipment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shipment_id"], name: "index_routes_on_shipment_id", unique: true
  end

  create_table "shipments", force: :cascade do |t|
    t.datetime "accepted_at"
    t.string "cancellation_reason"
    t.datetime "cancelled_at"
    t.integer "cargo_offer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.datetime "discarded_at"
    t.datetime "estimated_delivery_at"
    t.datetime "picked_up_at"
    t.datetime "settled_at"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_at"], name: "index_shipments_on_accepted_at"
    t.index ["cargo_offer_id"], name: "index_shipments_on_cargo_offer_id", unique: true
    t.index ["discarded_at"], name: "index_shipments_on_discarded_at"
    t.index ["status"], name: "index_shipments_on_status"
    t.check_constraint "status IN ('draft','offered','accepted','in_transit','delivered','settled','cancelled')", name: "shipments_status_check"
  end

  create_table "shippers", force: :cascade do |t|
    t.string "billing_address"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "tax_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["tax_id"], name: "index_shippers_on_tax_id", unique: true, where: "tax_id IS NOT NULL"
    t.index ["user_id"], name: "index_shippers_on_user_id", unique: true
  end

  create_table "tracking_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "from_status"
    t.string "kind", null: false
    t.decimal "lat", precision: 9, scale: 6
    t.decimal "lng", precision: 9, scale: 6
    t.text "metadata"
    t.datetime "recorded_at", null: false
    t.integer "shipment_id", null: false
    t.string "to_status"
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_tracking_events_on_kind"
    t.index ["shipment_id", "recorded_at"], name: "index_tracking_events_on_shipment_id_and_recorded_at"
    t.index ["shipment_id"], name: "index_tracking_events_on_shipment_id"
    t.check_constraint "kind IN ('status_change','gps_update','note')", name: "tracking_events_kind_check"
  end

  create_table "transport_windows", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "available_from", null: false
    t.datetime "available_to", null: false
    t.datetime "created_at", null: false
    t.string "destination_zone", null: false
    t.string "destination_zone_normalized"
    t.integer "max_km", null: false
    t.string "origin_zone", null: false
    t.string "origin_zone_normalized"
    t.decimal "price_per_km", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.integer "vehicle_id", null: false
    t.index ["active"], name: "index_transport_windows_on_active"
    t.index ["available_from", "available_to"], name: "index_transport_windows_on_available_from_and_available_to"
    t.index ["destination_zone_normalized"], name: "index_transport_windows_on_destination_zone_normalized"
    t.index ["origin_zone_normalized"], name: "index_transport_windows_on_origin_zone_normalized"
    t.index ["vehicle_id", "available_from", "available_to"], name: "idx_tw_on_vehicle_and_window"
    t.index ["vehicle_id"], name: "index_transport_windows_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name"
    t.string "jti", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.integer "carrier_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "gps_enabled", default: false, null: false
    t.integer "height_cm"
    t.integer "length_cm"
    t.string "make", default: "", null: false
    t.decimal "max_load_kg", precision: 10, scale: 2, default: "0.0", null: false
    t.string "model", default: "", null: false
    t.string "plate", null: false
    t.datetime "updated_at", null: false
    t.string "vehicle_type", default: "truck_small", null: false
    t.bigint "volume_cm3"
    t.integer "width_cm"
    t.integer "year"
    t.index ["carrier_id"], name: "index_vehicles_on_carrier_id"
    t.index ["carrier_id"], name: "index_vehicles_on_carrier_id_lookup"
    t.index ["plate"], name: "index_vehicles_on_plate", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cargo_offers", "cargos"
  add_foreign_key "cargo_offers", "carriers"
  add_foreign_key "cargo_offers", "transport_windows"
  add_foreign_key "cargos", "shippers"
  add_foreign_key "carriers", "users"
  add_foreign_key "routes", "shipments", on_delete: :cascade
  add_foreign_key "shipments", "cargo_offers", on_delete: :restrict
  add_foreign_key "shippers", "users"
  add_foreign_key "tracking_events", "shipments", on_delete: :cascade
  add_foreign_key "transport_windows", "vehicles", on_delete: :cascade
  add_foreign_key "vehicles", "carriers"
end
