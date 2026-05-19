# frozen_string_literal: true

# Cargo — load published by a Shipper. Matched to Carrier via CargoOffer.
class Cargo < ApplicationRecord
  belongs_to :shipper, inverse_of: :cargos
  has_many :cargo_offers, dependent: :restrict_with_error, inverse_of: :cargo

  validates :pickup_address, :delivery_address, :cargo_description, presence: true
  validates :weight_kg, numericality: { greater_than: 0 }
  validates :volume_cm3, numericality: { greater_than: 0, only_integer: true }
  validates :declared_value_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :pickup_date, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id shipper_id pickup_address delivery_address pickup_date cargo_description
       weight_kg volume_cm3 declared_value_cents created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[shipper cargo_offers]
  end
end
