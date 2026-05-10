# frozen_string_literal: true

# Vehicle — truck owned by a Carrier. SQLite has no native enum, so vehicle_type
# is stored as text and constrained at the AR layer (ADR-002).
#
# REQ-BE-00009 / REQ-BE-00010: registration data + photos + multi-vehicle fleet.
class Vehicle < ApplicationRecord
  VEHICLE_TYPES = %w[van truck_small truck_large semi_trailer].freeze
  PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTOS = 5
  PLATE_FORMAT = /\A[A-Z0-9]{6,8}\z/i

  belongs_to :carrier
  has_many :transport_windows, dependent: :destroy, inverse_of: :vehicle
  has_many_attached :photos

  before_save   :compute_volume_cm3
  before_destroy :ensure_no_active_commitments

  validates :plate,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { in: 6..8 },
            format: { with: PLATE_FORMAT, message: "must be alphanumeric (6-8 chars)" }
  validates :make, :model, presence: true, length: { maximum: 64 }
  validates :year,
            numericality: {
              only_integer: true, greater_than: 1980,
              less_than_or_equal_to: ->(_v) { Date.current.year + 1 }
            },
            allow_nil: true
  validates :max_load_kg, numericality: { greater_than: 0 }
  validates :vehicle_type, inclusion: { in: VEHICLE_TYPES }
  validates :length_cm, :width_cm, :height_cm,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validate :photos_within_limit
  validate :photos_have_allowed_content_type

  # Returns variant URLs for a given attached photo. Variants are processed
  # synchronously for MVP; a follow-up will pre-warm via ActiveJob.
  def photo_variants(photo)
    base = ::Rails.application.routes.url_helpers
    {
      thumbnail: base.url_for(photo.variant(resize_to_fill: [200, 200])),
      card:      base.url_for(photo.variant(resize_to_fill: [600, 400])),
      full:      base.url_for(photo.variant(resize_to_limit: [1200, 800]))
    }
  rescue StandardError
    { thumbnail: base.url_for(photo), card: base.url_for(photo), full: base.url_for(photo) }
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id carrier_id plate make model year vehicle_type max_load_kg
       length_cm width_cm height_cm volume_cm3 gps_enabled created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[carrier transport_windows]
  end

  private

  def compute_volume_cm3
    self.volume_cm3 = if [length_cm, width_cm, height_cm].all?(&:present?)
                        length_cm.to_i * width_cm.to_i * height_cm.to_i
                      end
  end

  def photos_within_limit
    return unless photos.attached? && photos.size > MAX_PHOTOS

    errors.add(:photos, "must be #{MAX_PHOTOS} or fewer")
  end

  def photos_have_allowed_content_type
    return unless photos.attached?

    photos.each do |p|
      next if PHOTO_CONTENT_TYPES.include?(p.blob.content_type)

      errors.add(:photos, "has invalid content type: #{p.blob.content_type}")
    end
  end

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
