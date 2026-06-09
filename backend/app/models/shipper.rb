# frozen_string_literal: true

# Shipper — Expedidor profile. Replaces the deprecated terms "Cliente" / "Productor"
# (see docs/05-appendices/glossary.md). Presence of the row IS the role state (ADR-008).
class Shipper < ApplicationRecord
  belongs_to :user
  has_many   :cargos,   dependent: :restrict_with_error, inverse_of: :shipper
  has_many   :reviews,  dependent: :restrict_with_error

  # Carrier → Shipper reviews (US30). Mirrors Carrier#shipper_authored_reviews.
  def carrier_authored_reviews
    reviews.carrier_authored
  end

  validates :user_id, uniqueness: true
  validates :tax_id,  uniqueness: { allow_blank: true }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id company_name tax_id billing_address created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user cargos]
  end
end
