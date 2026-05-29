# frozen_string_literal: true

# TransportWindow — published carrier availability tied to a specific Vehicle.
# Carrier is reachable via vehicle.carrier (no denormalised carrier_id, see plan §4.1).
#
# Location model (REQ-BE-00039 / ADR-014): origin is mandatory; destination is
# either fully set (address, coords, locality, admin_area, dropoff_radius_km
# all present) or fully NULL (a "destino abierto" — the carrier accepts cargo
# bound anywhere). Province / locality string narrowing is retired; matching is
# pure Haversine.
class TransportWindow < ApplicationRecord
  STATUSES = %w[open pending_offer reserved].freeze
  LAT_RANGE = -90..90
  LNG_RANGE = -180..180
  PICKUP_RADIUS_KM_MIN = 1
  PICKUP_RADIUS_KM_MAX = 200

  belongs_to :vehicle, -> { unscope(where: :discarded_at) }, inverse_of: :transport_windows
  has_many :cargo_offers, dependent: :restrict_with_error, inverse_of: :transport_window

  delegate :carrier, to: :vehicle, allow_nil: true

  validates :status, inclusion: { in: STATUSES }
  validates :price_per_km, numericality: { greater_than: 0 }
  validates :max_km, numericality: { greater_than: 0, only_integer: true }
  validates :available_from, :available_to, presence: true
  validates :origin_address, :origin_locality, :origin_admin_area, presence: true
  validates :origin_lat, presence: true,
                         numericality: { greater_than_or_equal_to: LAT_RANGE.begin,
                                         less_than_or_equal_to:    LAT_RANGE.end }
  validates :origin_lng, presence: true,
                         numericality: { greater_than_or_equal_to: LNG_RANGE.begin,
                                         less_than_or_equal_to:    LNG_RANGE.end }
  validates :destination_lat, numericality: { greater_than_or_equal_to: LAT_RANGE.begin,
                                              less_than_or_equal_to:    LAT_RANGE.end },
                              allow_nil: true
  validates :destination_lng, numericality: { greater_than_or_equal_to: LNG_RANGE.begin,
                                              less_than_or_equal_to:    LNG_RANGE.end },
                              allow_nil: true
  validates :pickup_radius_km,
            presence: true,
            numericality: {
              only_integer:             true,
              greater_than_or_equal_to: PICKUP_RADIUS_KM_MIN,
              less_than_or_equal_to:    PICKUP_RADIUS_KM_MAX
            }
  validates :dropoff_radius_km,
            numericality: {
              only_integer:             true,
              greater_than_or_equal_to: PICKUP_RADIUS_KM_MIN,
              less_than_or_equal_to:    PICKUP_RADIUS_KM_MAX
            },
            allow_nil: true
  validate :time_window_is_coherent
  validate :no_vehicle_overlap
  validate :open_destination_consistency

  scope :active, -> { where(active: true) }
  scope :marketplace_open, -> { where(status: "open") }

  validate :vehicle_must_be_kept_when_active

  # SQL prefilter: any window whose origin pin sits inside the axis-aligned
  # bounding box of radius `radius_km` around the given point. Cheap, indexable
  # on origin_lat / origin_lng (no spatial index needed — plain B-tree range).
  # Subsequent Haversine passes refine to the true disk.
  scope :within_bbox_of, ->(lat, lng, radius_km) {
    min_lat, max_lat, min_lng, max_lng = Truckr::Geo.bbox_for(lat.to_f, lng.to_f, radius_km)
    where(origin_lat: min_lat..max_lat, origin_lng: min_lng..max_lng)
  }

  # Filters windows whose origin is within their own `pickup_radius_km` of the
  # given cargo's pickup point. Haversine is computed in Ruby because the
  # product runs on SQLite forever (CLAUDE.md "Database policy"); PostGIS or
  # any spatial index is off-limits.
  #
  # The implementation breaks lazy chainability — it materialises the upstream
  # relation, filters in memory, then narrows back to `where(id: ...)` so the
  # callsite can still chain `.order(...)`, `.limit(...)`, etc. Compose this
  # AFTER all cheap SQL pre-filters (status, date overlap, vehicle capacity,
  # bbox), never on `TransportWindow.all`.
  scope :within_pickup_radius_of, ->(cargo) {
    pickup = [ cargo.pickup_lat.to_f, cargo.pickup_lng.to_f ]
    passing_ids = select(:id, :origin_lat, :origin_lng, :pickup_radius_km).map { |window|
      distance = Truckr::Geo.haversine_km(
        [ window.origin_lat.to_f, window.origin_lng.to_f ], pickup
      )
      window.id if distance <= window.pickup_radius_km
    }.compact
    where(id: passing_ids)
  }

  # Symmetric to within_pickup_radius_of: keeps a window if its destination pin
  # is within `dropoff_radius_km` of the cargo's delivery point. Open-destination
  # windows (`destination_lat IS NULL`) pass through unconditionally — the
  # carrier opted out of the destination filter entirely.
  scope :within_dropoff_radius_of, ->(cargo) {
    delivery = [ cargo.delivery_lat.to_f, cargo.delivery_lng.to_f ]
    passing_ids = select(:id, :destination_lat, :destination_lng, :dropoff_radius_km).map { |window|
      next window.id if window.destination_lat.nil?

      distance = Truckr::Geo.haversine_km(
        [ window.destination_lat.to_f, window.destination_lng.to_f ], delivery
      )
      window.id if distance <= window.dropoff_radius_km.to_i
    }.compact
    where(id: passing_ids)
  }

  # Orders the relation by Haversine distance from the cargo's pickup point,
  # ascending. Same SQLite-forever caveat as `within_pickup_radius_of` —
  # ordering happens in Ruby and is re-anchored to SQL via a CASE expression
  # so subsequent `.limit`/`.offset` still work correctly.
  scope :order_by_distance_to, ->(cargo) {
    pickup = [ cargo.pickup_lat.to_f, cargo.pickup_lng.to_f ]
    sorted = to_a.sort_by { |w|
      Truckr::Geo.haversine_km([ w.origin_lat.to_f, w.origin_lng.to_f ], pickup)
    }
    return none if sorted.empty?

    when_clauses = ([ "WHEN ? THEN ?" ] * sorted.size).join(" ")
    bindings     = sorted.each_with_index.flat_map { |w, i| [ w.id, i ] }
    case_sql     = sanitize_sql_array([ "CASE transport_windows.id #{when_clauses} END", *bindings ])

    where(id: sorted.map(&:id)).reorder(Arel.sql(case_sql))
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id vehicle_id origin_address origin_locality origin_admin_area
       destination_address destination_locality destination_admin_area
       origin_lat origin_lng destination_lat destination_lng
       price_per_km max_km pickup_radius_km dropoff_radius_km
       available_from available_to active status created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[vehicle cargo_offers]
  end

  private

  def vehicle_must_be_kept_when_active
    return unless active
    return if vehicle.nil?
    errors.add(:base, :vehicle_must_be_kept_when_active) if vehicle.discarded?
  end

  def open_destination_consistency
    fields = {
      destination_lat:        destination_lat,
      destination_lng:        destination_lng,
      destination_address:    destination_address,
      destination_locality:   destination_locality,
      destination_admin_area: destination_admin_area,
      dropoff_radius_km:      dropoff_radius_km
    }
    present_keys = fields.select { |_, v| v.present? || v.is_a?(Numeric) }.keys
    return if present_keys.empty? || present_keys.length == fields.length

    errors.add(:base, :open_destination_partial)
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
