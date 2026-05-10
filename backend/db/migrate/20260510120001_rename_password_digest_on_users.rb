# frozen_string_literal: true

# Renames `users.password_digest` (has_secure_password) to `users.encrypted_password`
# (Devise convention). BCrypt hashes are interchangeable so any pre-existing
# rows would still authenticate after the swap.
class RenamePasswordDigestOnUsers < ActiveRecord::Migration[8.1]
  def up
    rename_column :users, :password_digest, :encrypted_password
    change_column_null :users, :encrypted_password, false, ""
    change_column_default :users, :encrypted_password, ""
  end

  def down
    change_column_default :users, :encrypted_password, nil
    rename_column :users, :encrypted_password, :password_digest
  end
end
