# frozen_string_literal: true

# Solid Cable backplane table (INF-FE-00005 / ADR-013).
#
# Solid Cable 4.0's installer generates a standalone `db/cable_schema.rb` aimed
# at a *separate* cable database. We deliberately keep the realtime backplane on
# the **primary** SQLite database instead (see config/cable.yml) — no extra DB,
# no Redis, consistent with the SQLite-forever policy and the Kamal
# single-container deploy. So the table lives in the primary schema via this
# regular migration rather than the generated standalone schema file.
class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false

      t.index :channel
      t.index :channel_hash
      t.index :created_at
    end
  end
end
