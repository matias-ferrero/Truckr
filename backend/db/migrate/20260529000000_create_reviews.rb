# frozen_string_literal: true

# Reviews table — introduced by US30 ([[REQ-BE-00044]]) so the Carrier→Shipper
# review feature ships independently, without waiting on US20.
#
# The table is deliberately direction-agnostic: `authored_by` ('shipper' |
# 'carrier') distinguishes the two review directions in a single table, and the
# unique index is scoped to (shipment_id, authored_by). US30 only writes the
# `carrier` direction; US20 / US26 / US54 consume this same table when they
# land (no second migration, no schema change required).
#
# SQLite-forever (ADR): no EXCLUDE constraints — per-direction uniqueness is
# enforced by the composite unique index plus the model-level guard in
# Reviews::Create (race-safe under shipment.with_lock).
class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :shipment, null: false, index: false, foreign_key: { on_delete: :restrict }
      t.references :shipper,  null: false, index: false, foreign_key: { on_delete: :restrict }
      t.references :carrier,  null: false, index: false, foreign_key: { on_delete: :restrict }
      t.integer    :rating,      null: false
      t.text       :body
      t.string     :authored_by, null: false

      t.timestamps
    end

    # One review per direction per shipment (AC3 — unicidad).
    add_index :reviews, [ :shipment_id, :authored_by ], unique: true,
                        name: "index_reviews_on_shipment_and_authored_by"
    # Profile read paths (the future US26 / US54): reviews about a given party.
    add_index :reviews, [ :carrier_id, :authored_by ]
    add_index :reviews, [ :shipper_id, :authored_by ]

    add_check_constraint :reviews,
                         "rating BETWEEN 1 AND 5",
                         name: "reviews_rating_range_check"

    add_check_constraint :reviews,
                         "authored_by IN ('shipper','carrier')",
                         name: "reviews_authored_by_check"
  end
end
