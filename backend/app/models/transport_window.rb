# frozen_string_literal: true

# TransportWindow — published carrier availability tied to a specific Vehicle.
# Carrier is reachable via vehicle.carrier (no denormalised carrier_id, see plan §4.1).
class TransportWindow < ApplicationRecord
  belongs_to :vehicle, inverse_of: :transport_windows
  has_many :cargo_offers, dependent: :restrict_with_error, inverse_of: :transport_window

  delegate :carrier, to: :vehicle, allow_nil: true

  validates :origin_zone, :destination_zone, presence: true
  validates :price_per_km, numericality: { greater_than: 0 }
  validates :max_km, numericality: { greater_than: 0, only_integer: true }
  validates :available_from, :available_to, presence: true
  validate  :time_window_is_coherent
  validate  :no_vehicle_overlap

  before_save :normalize_search_fields

  scope :active, -> { where(active: true) }

  # MVP: diacritic-insensitive substring match via normalized columns.
  # Phase 2: replace with PostGIS / proper geocoded matching (ADR-010).
  # Filtering is delegated to Ransack via origin_zone_normalized_cont, destination_zone_normalized_cont
  # in Api::TransportWindowsController#index.

  def self.ransackable_attributes(_auth_object = nil)
    %w[id vehicle_id origin_zone destination_zone origin_zone_normalized destination_zone_normalized
       price_per_km max_km available_from available_to active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[vehicle cargo_offers]
  end

  private

  def normalize_search_fields
    self.origin_zone_normalized = I18n.transliterate(origin_zone.to_s).downcase if origin_zone.present?
    self.destination_zone_normalized = I18n.transliterate(destination_zone.to_s).downcase if destination_zone.present?
  end

  def time_window_is_coherent
    return if available_from.blank? || available_to.blank?
    errors.add(:available_to, "must be after available_from") if available_to <= available_from
  end

  # Guards against double-booking among active windows only. Inactive windows
  # are excluded so editing or reactivating them checks current availability.
  def no_vehicle_overlap
    return if vehicle_id.blank? || available_from.blank? || available_to.blank?
    overlap = TransportWindow.where(vehicle_id: vehicle_id)
                             .where(active: true)
                             .where.not(id: id)
                             .where("available_from < ? AND available_to > ?", available_to, available_from)
    errors.add(:base, "vehicle is already booked in an overlapping window") if overlap.exists?
  end
end
