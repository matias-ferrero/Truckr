# frozen_string_literal: true

# Adds the JTI column required by devise-jwt's JTIMatcher revocation strategy
# (ADR-011). Existing users are backfilled with a per-row UUID before the
# NOT NULL constraint is applied — SQLite has no `gen_random_uuid()`, so the
# backfill runs in Ruby.
class AddJtiToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :jti, :string

    User.reset_column_information
    User.where(jti: nil).find_each do |user|
      user.update_columns(jti: SecureRandom.uuid)
    end

    change_column_null :users, :jti, false
    add_index :users, :jti, unique: true
  end

  def down
    remove_index :users, :jti
    remove_column :users, :jti
  end
end
