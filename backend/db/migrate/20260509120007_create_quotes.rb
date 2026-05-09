class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.references :cargo_offer,      null: false, foreign_key: true
      t.references :carrier,          null: false, foreign_key: true
      t.references :transport_window, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string  :currency,     null: false, default: "ARS"
      t.string  :status,       null: false, default: "pending"
      t.datetime :expires_at,  null: false
      t.timestamps
    end

    add_index :quotes, :status
    add_index :quotes, :expires_at
  end
end
