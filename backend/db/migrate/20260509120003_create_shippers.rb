class CreateShippers < ActiveRecord::Migration[8.1]
  def change
    create_table :shippers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :company_name
      t.string :tax_id
      t.string :billing_address
      t.timestamps
    end

    add_index :shippers, :tax_id, unique: true, where: "tax_id IS NOT NULL"
  end
end
