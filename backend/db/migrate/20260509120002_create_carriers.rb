class CreateCarriers < ActiveRecord::Migration[8.1]
  def change
    create_table :carriers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string  :legal_name
      t.string  :tax_id
      t.string  :base_city
      t.string  :province
      t.decimal :rating_avg,          precision: 3, scale: 2, null: false, default: 0.0
      t.integer :completed_shipments, null: false, default: 0
      t.timestamps
    end

    add_index :carriers, [ :province, :base_city ]
    add_index :carriers, :tax_id, unique: true, where: "tax_id IS NOT NULL"
  end
end
