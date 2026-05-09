# frozen_string_literal: true

# TransportWindow — published carrier availability tied to a specific Vehicle.
# Carrier is reachable via vehicle.carrier (no denormalised carrier_id, see plan §4.1).
class TransportWindow < ApplicationRecord
  belongs_to :vehicle, inverse_of: :transport_windows
  has_many :quotes, dependent: :restrict_with_error, inverse_of: :transport_window

  delegate :carrier, to: :vehicle, allow_nil: true

  validates :origin_zone, :destination_zone, presence: true
  validates :price_per_km, numericality: { greater_than: 0 }
  validates :max_km, numericality: { greater_than: 0, only_integer: true }
  validates :available_from, :available_to, presence: true
  validate  :time_window_is_coherent
  validate  :no_vehicle_overlap

  scope :active, -> { where(active: true) }

  # MVP: case-insensitive substring match on both endpoints.
  # Phase 2: replace with PostGIS / proper geocoded matching (ADR-010).
  scope :matching, ->(origin:, destination:) {
    where("LOWER(origin_zone) LIKE ?", "%#{origin.to_s.downcase}%")
      .where("LOWER(destination_zone) LIKE ?", "%#{destination.to_s.downcase}%")
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id vehicle_id origin_zone destination_zone price_per_km max_km
       available_from available_to active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[vehicle quotes]
  end

  private

  def time_window_is_coherent
    return if available_from.blank? || available_to.blank?
    errors.add(:available_to, "must be after available_from") if available_to <= available_from
  end

  # Phase 0/1 guard against double-booking. Race-safe at the application layer
  # only; a Postgres EXCLUDE constraint replaces this when we move off SQLite.
  def no_vehicle_overlap
    return if vehicle_id.blank? || available_from.blank? || available_to.blank?
    overlap = TransportWindow.where(vehicle_id: vehicle_id)
                             .where.not(id: id)
                             .where("available_from < ? AND available_to > ?", available_to, available_from)
    errors.add(:base, "vehicle is already booked in an overlapping window") if overlap.exists?
  end
end
