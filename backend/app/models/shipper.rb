# frozen_string_literal: true

# Shipper — Expedidor profile. Replaces the deprecated terms "Cliente" / "Productor"
# (see docs/05-appendices/glossary.md). Presence of the row IS the role state (ADR-008).
class Shipper < ApplicationRecord
  belongs_to :user
  has_many   :cargo_offers, dependent: :restrict_with_error, inverse_of: :shipper

  validates :user_id, uniqueness: true
  validates :tax_id,  uniqueness: { allow_blank: true }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id company_name tax_id billing_address created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user cargo_offers]
  end
end
