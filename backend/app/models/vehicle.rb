# frozen_string_literal: true

# Vehicle — truck owned by a Carrier. SQLite has no native enum, so vehicle_type
# is stored as text and constrained at the AR layer (ADR-002).
class Vehicle < ApplicationRecord
  VEHICLE_TYPES = %w[van truck_small truck_large semi_trailer].freeze

  belongs_to :carrier
  has_many :transport_windows, dependent: :destroy, inverse_of: :vehicle

  before_destroy :ensure_no_active_commitments

  validates :plate,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { in: 6..8 }
  validates :capacity_kg,  numericality: { greater_than: 0, only_integer: true }
  validates :vehicle_type, inclusion: { in: VEHICLE_TYPES }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id carrier_id plate capacity_kg vehicle_type gps_enabled created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[carrier transport_windows]
  end

  private

  # Refuses to hard-delete if any TransportWindow on this Vehicle has a live
  # (non-terminal) Quote tied to it. Tolerates Quote being absent at boot —
  # REQ-BE-00021 introduces it.
  def ensure_no_active_commitments
    return unless defined?(Quote) && defined?(TransportWindow)

    has_live_quote = Quote.joins(:transport_window)
                          .where(transport_windows: { vehicle_id: id })
                          .where.not(status: %w[expired cancelled])
                          .exists?
    throw(:abort) if has_live_quote
  end
end
