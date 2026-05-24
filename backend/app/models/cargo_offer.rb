# frozen_string_literal: true

# CargoOffer — Carrier's bid for a Cargo, tied to a TransportWindow.
#
# State machine (modelled by hand — Decision F of REQ-BE-00005):
#
#   pending ──► accepted ──► paid
#     │            │
#     ├──► expired │
#     │            └──► cancelled
#     ├──► rejected
#     └──► cancelled
#
# Allowed transitions:
#   pending   → accepted, expired, rejected, cancelled
#   accepted  → paid, cancelled
#   paid      → (terminal)
#   expired   → (terminal)
#   rejected  → (terminal)
#   cancelled → (terminal)
#
# Triggers (NOT implemented in this issue — declared as the contract for
# downstream callers):
#   - pending  → accepted: US12 / REQ-BE-00007 (shipper accepts).
#   - accepted → paid:     REQ-BE-00007 (payment success).
#   - {pending,accepted} → expired: CargoOfferExpirationJob (INF-BE-00006).
#   - any → cancelled: shipper / carrier explicit cancel.
#
# `accepted` is the transition that signals "ready to be picked up by Fulfilment
# (REQ-BE-00022)" — the trigger for `Shipment.create!(cargo_offer: ...)`.
class CargoOffer < ApplicationRecord
  STATES = %w[pending accepted paid rejected expired cancelled].freeze
  TERMINAL_STATES = %w[paid rejected expired cancelled].freeze
  ALLOWED_TRANSITIONS = {
    "pending"   => %w[accepted expired rejected cancelled],
    "accepted"  => %w[paid cancelled],
    "paid"      => [],
    "rejected"  => [],
    "expired"   => [],
    "cancelled" => []
  }.freeze

  belongs_to :cargo,            inverse_of: :cargo_offers
  belongs_to :carrier,          inverse_of: :cargo_offers
  belongs_to :transport_window, inverse_of: :cargo_offers
  has_one    :shipment,         dependent: :restrict_with_error, inverse_of: :cargo_offer

  # Transient input: km the shipper estimates for the route. Used to derive
  # amount_cents at validation time; never persisted.
  attr_accessor :estimated_km

  # Cross-record attributes the CargoOffer's validators report errors against.
  # Declared here so `errors.add(...)` resolves to a real attribute reader and
  # `errors.full_messages` doesn't blow up.
  delegate :weight_kg, :volume_cm3, to: :cargo, allow_nil: true

  # Virtual readers so `errors.add(:pickup_window, ...)` /
  # `errors.add(:transport_window, ...)` resolve. The transport_window
  # association reader is overridden-free; pickup_window is purely a label.
  def pickup_window
    return nil unless cargo

    [ cargo.pickup_window_start, cargo.pickup_window_end ]
  end

  before_validation :derive_amount_and_expiration, on: :create

  validates :amount_cents, numericality: { greater_than: 0, only_integer: true }
  validates :currency, inclusion: { in: %w[ARS] }
  validates :status,   inclusion: { in: STATES }
  validates :expires_at, presence: true

  validate :estimated_km_positive, on: :create, if: -> { amount_cents.blank? }
  validate :pickup_window_overlaps_transport_window
  validate :within_vehicle_capacity
  validate :transport_window_not_already_taken, on: :create

  scope :pending,     -> { where(status: "pending") }
  scope :accepted,    -> { where(status: "accepted") }
  scope :paid,        -> { where(status: "paid") }
  scope :rejected,    -> { where(status: "rejected") }
  scope :cancelled,   -> { where(status: "cancelled") }
  scope :expired,     -> { where(status: "expired") }
  scope :past_expiry, -> { where("expires_at < ?", Time.current) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def can_transition_to?(new_status)
    ALLOWED_TRANSITIONS.fetch(status, []).include?(new_status.to_s)
  end

  # Transition entry point. Invocation is the responsibility of US12 and
  # REQ-BE-00007; this method only enforces the table above.
  def transition_to!(new_status)
    new_status = new_status.to_s
    unless can_transition_to?(new_status)
      raise InvalidTransition,
            "Cannot transition CargoOffer##{id} from #{status.inspect} to #{new_status.inspect}"
    end
    update!(status: new_status)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id cargo_id carrier_id transport_window_id amount_cents currency
       status expires_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cargo carrier transport_window]
  end

  class InvalidTransition < StandardError; end

  private

  def derive_amount_and_expiration
    return unless transport_window

    if amount_cents.blank? && estimated_km.present?
      km = estimated_km.to_d
      self.amount_cents = (transport_window.price_per_km * km * 100).ceil.to_i if km > 0
    end
    self.expires_at ||= [ transport_window.available_to.to_time, 72.hours.from_now ].min
  end

  def estimated_km_positive
    return if estimated_km.present? && estimated_km.to_d > 0

    errors.add(:estimated_km, :must_be_positive)
  end

  # The cargo's pickup window must overlap the transport window's availability:
  #   cargo.pickup_window_start <= window.available_to AND
  #   cargo.pickup_window_end   >= window.available_from
  def pickup_window_overlaps_transport_window
    return unless transport_window && cargo&.pickup_window_start && cargo&.pickup_window_end

    overlaps = cargo.pickup_window_start <= transport_window.available_to &&
               cargo.pickup_window_end   >= transport_window.available_from
    errors.add(:pickup_window, :out_of_window_range) unless overlaps
  end

  def within_vehicle_capacity
    vehicle = transport_window&.vehicle
    return unless vehicle && cargo

    if cargo.weight_kg.present? && cargo.weight_kg.to_d > vehicle.max_load_kg
      errors.add(:weight_kg, :exceeds_vehicle_capacity)
    end

    # volume_cm3 is optional on a Cargo — a nil volume imposes no constraint.
    if cargo.volume_cm3.present? && vehicle.volume_cm3.present? &&
       cargo.volume_cm3.to_i > vehicle.volume_cm3
      errors.add(:volume_cm3, :exceeds_vehicle_capacity)
    end
  end

  # Window-lock (REQ-BE-00032 §2.7): the chosen TransportWindow must hold no
  # other pending/accepted CargoOffer. SQLite serialises writes, so this check
  # inside the create transaction is race-safe with no explicit row lock.
  def transport_window_not_already_taken
    return unless transport_window

    contended = transport_window.cargo_offers
                                .where(status: %w[pending accepted])
                                .where.not(id: id)
                                .exists?
    errors.add(:transport_window, :already_taken) if contended
  end
end
