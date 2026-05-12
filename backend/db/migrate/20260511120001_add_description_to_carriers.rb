# frozen_string_literal: true

# US6 — public carrier detail page needs a free-text profile blurb separate
# from the per-vehicle `description`. `reviews_count` is denormalised here so
# the carrier card / hero can render rating + count without an extra join;
# both columns stay nullable until REQ-BE-00014 lands the Review model.
class AddDescriptionToCarriers < ActiveRecord::Migration[8.1]
  def change
    add_column :carriers, :description,   :text
    add_column :carriers, :reviews_count, :integer, null: false, default: 0
  end
end
