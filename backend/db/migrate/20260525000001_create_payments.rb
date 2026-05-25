# frozen_string_literal: true

# Schema-only Payment table for ADR-012. The model is a bare AR shell with an
# immutability guard; the service / gateway that writes rows lands later
# (REQ-BE-00033 / Brian).
#
# Per ADR-012 amendment 2026-05-24: born-terminal FSM `escrowed | failed`,
# per-attempt rows (Shipment 1:N Payment), hard-delete only (no `discarded_at`).
class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :shipment, null: false, foreign_key: { on_delete: :restrict }
      t.integer    :amount_cents,       null: false
      t.string     :currency,           null: false, default: "ARS"
      t.string     :provider,           null: false, default: "fake"
      t.string     :provider_reference
      t.string     :state,              null: false
      t.datetime   :escrowed_at
      t.datetime   :failed_at
      t.string     :failure_reason

      t.timestamps
    end

    add_index :payments, [ :shipment_id, :state ]
    add_index :payments, :provider_reference

    add_check_constraint :payments,
                         "state IN ('escrowed','failed')",
                         name: "payments_state_check"

    add_check_constraint :payments,
                         "provider IN ('fake','mercadopago','stripe','other')",
                         name: "payments_provider_check"
  end
end
