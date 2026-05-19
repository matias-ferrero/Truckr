# frozen_string_literal: true

# Renames marketplace tables to reflect the 2026-05-19 domain rename
# (REF-BE-00002): the bid `quotes` becomes `cargo_offers` and the old
# publication `cargo_offers` becomes `cargos`. Done in a single migration via
# a temporary alias to avoid name collision during the swap.
class RenameMarketplaceTables < ActiveRecord::Migration[8.1]
  def up
    rename_table :cargo_offers, :cargos
    rename_table :quotes, :cargo_offers

    if index_name_exists?(:cargo_offers, "index_quotes_on_cargo_offer_id")
      rename_index :cargo_offers, "index_quotes_on_cargo_offer_id", "index_cargo_offers_on_cargo_id"
    end
    if index_name_exists?(:cargo_offers, "index_quotes_on_carrier_id")
      rename_index :cargo_offers, "index_quotes_on_carrier_id", "index_cargo_offers_on_carrier_id"
    end
    if index_name_exists?(:cargo_offers, "index_quotes_on_expires_at")
      rename_index :cargo_offers, "index_quotes_on_expires_at", "index_cargo_offers_on_expires_at"
    end
    if index_name_exists?(:cargo_offers, "index_quotes_on_status")
      rename_index :cargo_offers, "index_quotes_on_status", "index_cargo_offers_on_status"
    end
    if index_name_exists?(:cargo_offers, "index_quotes_on_transport_window_id")
      rename_index :cargo_offers, "index_quotes_on_transport_window_id", "index_cargo_offers_on_transport_window_id"
    end

    if index_name_exists?(:cargos, "index_cargo_offers_on_pickup_date")
      rename_index :cargos, "index_cargo_offers_on_pickup_date", "index_cargos_on_pickup_date"
    end
    if index_name_exists?(:cargos, "index_cargo_offers_on_shipper_id")
      rename_index :cargos, "index_cargo_offers_on_shipper_id", "index_cargos_on_shipper_id"
    end

    rename_column :cargo_offers, :cargo_offer_id, :cargo_id
  end

  def down
    rename_column :cargo_offers, :cargo_id, :cargo_offer_id

    if index_name_exists?(:cargos, "index_cargos_on_shipper_id")
      rename_index :cargos, "index_cargos_on_shipper_id", "index_cargo_offers_on_shipper_id"
    end
    if index_name_exists?(:cargos, "index_cargos_on_pickup_date")
      rename_index :cargos, "index_cargos_on_pickup_date", "index_cargo_offers_on_pickup_date"
    end

    if index_name_exists?(:cargo_offers, "index_cargo_offers_on_transport_window_id")
      rename_index :cargo_offers, "index_cargo_offers_on_transport_window_id", "index_quotes_on_transport_window_id"
    end
    if index_name_exists?(:cargo_offers, "index_cargo_offers_on_status")
      rename_index :cargo_offers, "index_cargo_offers_on_status", "index_quotes_on_status"
    end
    if index_name_exists?(:cargo_offers, "index_cargo_offers_on_expires_at")
      rename_index :cargo_offers, "index_cargo_offers_on_expires_at", "index_quotes_on_expires_at"
    end
    if index_name_exists?(:cargo_offers, "index_cargo_offers_on_carrier_id")
      rename_index :cargo_offers, "index_cargo_offers_on_carrier_id", "index_quotes_on_carrier_id"
    end
    if index_name_exists?(:cargo_offers, "index_cargo_offers_on_cargo_id")
      rename_index :cargo_offers, "index_cargo_offers_on_cargo_id", "index_quotes_on_cargo_offer_id"
    end

    rename_table :cargo_offers, :quotes
    rename_table :cargos, :cargo_offers
  end
end
