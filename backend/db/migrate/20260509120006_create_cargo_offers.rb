class CreateCargoOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :cargo_offers do |t|
      t.references :shipper, null: false, foreign_key: true
      t.string  :pickup_address,       null: false
      t.string  :delivery_address,     null: false
      t.datetime :pickup_date,         null: false
      t.text    :cargo_description,    null: false
      t.decimal :weight_kg,            null: false, precision: 10, scale: 2
      t.integer :volume_cm3,           null: false
      t.integer :declared_value_cents, null: false
      t.timestamps
    end

    add_index :cargo_offers, :pickup_date
  end
end
