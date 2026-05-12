# frozen_string_literal: true

# Carrier — Transportista profile. One row per User-with-carrier-role; the
# presence of the row IS the role state (ADR-008).
class Carrier < ApplicationRecord
  belongs_to :user
  has_many   :vehicles, dependent: :destroy
  has_many   :transport_windows, through: :vehicles
  has_many   :quotes, dependent: :restrict_with_error, inverse_of: :carrier

  validates :user_id, uniqueness: true
  validates :tax_id,  uniqueness: { allow_blank: true }
  validates :rating_avg,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :completed_shipments,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :reviews_count,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :description, length: { maximum: 2_000 }, allow_blank: true

  # Returns the active TransportWindows visible from the public profile page.
  # Avoids hitting `vehicles` twice by going through the join association.
  def active_transport_windows
    TransportWindow.active.joins(:vehicle).where(vehicles: { carrier_id: id })
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id legal_name tax_id base_city province rating_avg reviews_count
       completed_shipments description created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user vehicles transport_windows quotes]
  end
end
