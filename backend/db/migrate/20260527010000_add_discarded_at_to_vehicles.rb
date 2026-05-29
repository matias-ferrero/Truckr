class AddDiscardedAtToVehicles < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:vehicles, :discarded_at)
      add_column :vehicles, :discarded_at, :datetime
      add_index :vehicles, :discarded_at
    end
  end
end
