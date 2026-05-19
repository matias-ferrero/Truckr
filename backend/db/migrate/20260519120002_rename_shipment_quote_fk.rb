# frozen_string_literal: true

# Renames `shipments.quote_id` → `shipments.cargo_offer_id` to follow the
# 2026-05-19 domain rename (REF-BE-00002). The Quote model has been renamed
# to CargoOffer, so the FK column follows.
class RenameShipmentQuoteFk < ActiveRecord::Migration[8.1]
  def up
    rename_column :shipments, :quote_id, :cargo_offer_id

    if index_name_exists?(:shipments, "index_shipments_on_quote_id")
      rename_index :shipments, "index_shipments_on_quote_id", "index_shipments_on_cargo_offer_id"
    end
  end

  def down
    if index_name_exists?(:shipments, "index_shipments_on_cargo_offer_id")
      rename_index :shipments, "index_shipments_on_cargo_offer_id", "index_shipments_on_quote_id"
    end

    rename_column :shipments, :cargo_offer_id, :quote_id
  end
end
