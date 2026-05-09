# frozen_string_literal: true

# CargoOffer — load published by a Shipper. Matched to Carrier via Quote.
class CargoOffer < ApplicationRecord
  belongs_to :shipper, inverse_of: :cargo_offers
  has_many :quotes, dependent: :restrict_with_error, inverse_of: :cargo_offer

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
    %w[shipper quotes]
  end
end
