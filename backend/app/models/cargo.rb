# frozen_string_literal: true

# Cargo — load published by a Shipper. Matched to a Carrier's TransportWindow
# via CargoOffer.
#
# Publication FSM (hand-rolled, mirrors Shipment — no aasm gem in the repo):
#
#   open ──▶ accepted    (triggered downstream by US12 when a CargoOffer is accepted)
#   open ──▶ cancelled   (Shipper soft-cancel, only when no accepted CargoOffer)
#   accepted, cancelled  → terminal
#
# There is no intermediate `offered` state: a Cargo stays `open` while it has
# `pending` offers and only becomes `accepted` when one of them is accepted.
class Cargo < ApplicationRecord
  class IllegalTransition < StandardError; end

  STATUSES = %w[open accepted cancelled].freeze
  ALLOWED_TRANSITIONS = {
    open:      %i[accepted cancelled],
    accepted:  [],
    cancelled: []
  }.freeze
  LAT_RANGE = -90..90
  LNG_RANGE = -180..180

  belongs_to :shipper, inverse_of: :cargos
  has_many   :cargo_offers, dependent: :destroy, inverse_of: :cargo
  has_one    :accepted_cargo_offer, -> { where(status: "accepted") },
             class_name: "CargoOffer", inverse_of: :cargo

  validates :cargo_description, presence: true, length: { maximum: 200 }
  validates :pickup_address, :delivery_address,
            :pickup_locality, :pickup_admin_area,
            :delivery_locality, :delivery_admin_area,
            presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :weight_kg, numericality: { greater_than: 0 }
  validates :volume_cm3, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :declared_value_cents,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :pickup_window_start, :pickup_window_end, presence: true
  validates :pickup_lat, :delivery_lat,
            presence: true,
            numericality: { greater_than_or_equal_to: LAT_RANGE.begin,
                            less_than_or_equal_to:    LAT_RANGE.end }
  validates :pickup_lng, :delivery_lng,
            presence: true,
            numericality: { greater_than_or_equal_to: LNG_RANGE.begin,
                            less_than_or_equal_to:    LNG_RANGE.end }
  validate  :pickup_window_is_coherent

  before_create :set_distance_km
  before_save   :refresh_distance_on_route_change

  scope :for_shipper, ->(shipper) { where(shipper_id: shipper.id) }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }

  def editable?    = status == "open" && accepted_cargo_offer.nil?
  def cancellable? = status == "open" && accepted_cargo_offer.nil?

  # Returns the TransportWindows that match this Cargo for the purposes of
  # offering (US4/US5/US52 per ADR-014): active, no pending/accepted contender,
  # availability overlaps pickup window, vehicle can carry the weight, origin
  # pin within bbox + pickup_radius_km of the cargo's pickup, and (if the
  # window has a destination) destination pin within dropoff_radius_km of the
  # cargo's delivery. Open-destination windows skip the dropoff filter. No
  # province / locality strings consulted at any layer — pure Haversine.
  def matching_windows
    blocked = CargoOffer.where(status: %w[pending accepted]).select(:transport_window_id)

    pre_filtered = TransportWindow
      .active
      .where.not(id: blocked)
      .where("available_from <= ? AND available_to >= ?", pickup_window_end, pickup_window_start)
      .joins(:vehicle).where("vehicles.max_load_kg >= ?", weight_kg)
      .within_bbox_of(pickup_lat, pickup_lng, TransportWindow::PICKUP_RADIUS_KM_MAX)

    # Haversine passes run LAST — they materialise the relation in Ruby.
    pre_filtered.within_pickup_radius_of(self)
                .within_dropoff_radius_of(self)
                .includes(vehicle: { carrier: :user })
                .order(:available_from)
  end

  # Atomically advances `status`, validates the transition against the table
  # above and stamps the soft-cancel columns. Mirrors Shipment#transition_to! —
  # transaction + row lock so concurrent attempts serialise.
  def transition_to!(new_status, reason: nil, at: Time.current)
    new_status = new_status.to_sym
    transaction do
      with_lock do
        from = status.to_sym
        unless ALLOWED_TRANSITIONS.fetch(from, []).include?(new_status)
          raise IllegalTransition, "Cargo #{id}: transition #{from} -> #{new_status} is not allowed"
        end

        attrs = { status: new_status.to_s }
        if new_status == :cancelled
          attrs[:cancelled_at] = at
          attrs[:cancellation_reason] = reason
        end
        update!(attrs)
        cargo_offers.where(status: "pending").find_each { |o| o.transition_to!(:expired) } if new_status == :cancelled
      end
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id shipper_id status pickup_address delivery_address
       pickup_locality pickup_admin_area delivery_locality delivery_admin_area
       pickup_lat pickup_lng delivery_lat delivery_lng
       pickup_window_start pickup_window_end
       cargo_description weight_kg volume_cm3 declared_value_cents created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[shipper cargo_offers]
  end

  private

  def pickup_window_is_coherent
    return if pickup_window_start.blank? || pickup_window_end.blank?

    errors.add(:pickup_window_end, :must_be_after_start) if pickup_window_end <= pickup_window_start
  end

  def set_distance_km
    return if distance_km.present?
    km = GoogleMaps::DistanceService.fetch_km(
      pickup_lat, pickup_lng, delivery_lat, delivery_lng
    )
    if km.nil?
      errors.add(:base, :distance_unavailable)
      throw(:abort)
    else
      self.distance_km = km
    end
  end

  # Refreshes distance_km whenever the route coordinates change on an existing
  # record. Silently preserves the previous value if the Distance API is
  # unavailable — callers tolerate a slightly stale distance (the route is
  # still correct; only the displayed label lags). Creating records is handled
  # by the stricter before_create callback above.
  def refresh_distance_on_route_change
    return if new_record?
    return unless pickup_lat_changed? || pickup_lng_changed? ||
                  delivery_lat_changed? || delivery_lng_changed?

    km = GoogleMaps::DistanceService.fetch_km(
      pickup_lat, pickup_lng, delivery_lat, delivery_lng
    )
    self.distance_km = km unless km.nil?
  end
end
