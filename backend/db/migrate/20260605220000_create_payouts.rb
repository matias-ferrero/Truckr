# frozen_string_literal: true

# US15 — Carrier payout on delivery (REQ-BE-00046).
#
# Payouts are born-terminal records (ADR-012): they are created in a final
# state (`paid` or `failed`) and never updated. The `shipment_id` +
# compound index on `(shipment_id, state)` is the idempotency guard used by
# Payouts::Create#race-safety check.
class CreatePayouts < ActiveRecord::Migration[8.0]
  def change
    create_table :payouts do |t|
      t.references :payment,  null: false, foreign_key: true,                  comment: "Source escrow payment — FK audit trail"
      t.references :shipment, null: false, foreign_key: true,                  comment: "Shipment this payout settles"
      t.integer    :gross_amount_cents, null: false,                            comment: "What the shipper paid (from payment.amount_cents)"
      t.decimal    :commission_rate,    null: false, precision: 5, scale: 4,   comment: "Platform commission rate (0.1500 in MVP)"
      t.integer    :commission_cents,   null: false,                            comment: "ceil(gross × rate)"
      t.integer    :amount_cents,       null: false,                            comment: "Net to carrier: gross − commission"
      t.string     :currency,           null: false, default: "ARS"
      t.string     :state,              null: false,                            comment: "paid | failed (born-terminal)"
      t.datetime   :paid_at
      t.datetime   :failed_at
      t.string     :failure_reason
      t.datetime   :discarded_at,                                               comment: "Soft-delete (ADR-009)"

      t.timestamps
    end

    add_index :payouts, %i[shipment_id state]
  end
end
