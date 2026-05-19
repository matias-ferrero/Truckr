# frozen_string_literal: true

# Quote — Carrier's bid for a CargoOffer, tied to a TransportWindow.
#
# State machine (modelled by hand — Decision F of REQ-BE-00005):
#
#   pending ──► accepted ──► paid
#     │            │
#     ├──► expired │
#     │            └──► cancelled
#     └──► cancelled
#
# Allowed transitions:
#   pending   → accepted, expired, cancelled
#   accepted  → paid, cancelled
#   paid      → (terminal)
#   expired   → (terminal)
#   cancelled → (terminal)
#
# Triggers (NOT implemented in this issue — declared as the contract for
# downstream callers):
#   - pending  → accepted: US12 / REQ-BE-00007 (shipper accepts).
#   - accepted → paid:     REQ-BE-00007 (payment success).
#   - {pending,accepted} → expired: QuotePaymentTimeoutJob (REQ-BE-00007).
#   - any → cancelled: shipper / carrier explicit cancel.
#
# `accepted` is the transition that signals "ready to be picked up by Fulfilment
# (REQ-BE-00022)" — the trigger for `Shipment.create!(quote: ...)`.
class Quote < ApplicationRecord
  STATES = %w[pending accepted paid expired cancelled].freeze
  TERMINAL_STATES = %w[paid expired cancelled].freeze
  ALLOWED_TRANSITIONS = {
    "pending"   => %w[accepted expired cancelled],
    "accepted"  => %w[paid cancelled],
    "paid"      => [],
    "expired"   => [],
    "cancelled" => []
  }.freeze

  belongs_to :cargo_offer,      inverse_of: :quotes
  belongs_to :carrier,          inverse_of: :quotes
  belongs_to :transport_window, inverse_of: :quotes
  has_one    :shipment,         dependent: :restrict_with_error, inverse_of: :quote

  # Transient input: km the shipper estimates for the route. Used to derive
  # amount_cents at validation time; never persisted.
  attr_accessor :estimated_km

  # Cross-record attributes the Quote's validators report errors against.
  # Declared here so `errors.add(:pickup_date, ...)` resolves to a real
  # attribute reader and `errors.full_messages` doesn't blow up.
  delegate :pickup_date, :weight_kg, :volume_cm3, to: :cargo_offer, allow_nil: true

  before_validation :derive_amount_and_expiration, on: :create

  validates :amount_cents, numericality: { greater_than: 0, only_integer: true }
  validates :currency, inclusion: { in: %w[ARS] }
  validates :status,   inclusion: { in: STATES }
  validates :expires_at, presence: true

  validate :estimated_km_positive, on: :create, if: -> { amount_cents.blank? }
  validate :pickup_date_within_window
  validate :within_vehicle_capacity

  scope :pending,     -> { where(status: "pending") }
  scope :accepted,    -> { where(status: "accepted") }
  scope :paid,        -> { where(status: "paid") }
  scope :cancelled,   -> { where(status: "cancelled") }
  scope :expired,     -> { where(status: "expired") }
  scope :past_expiry, -> { where("expires_at < ?", Time.current) }

  def can_transition_to?(new_status)
    ALLOWED_TRANSITIONS.fetch(status, []).include?(new_status.to_s)
  end

  # Transition entry point. Invocation is the responsibility of US12 and
  # REQ-BE-00007; this method only enforces the table above.
  def transition_to!(new_status)
    new_status = new_status.to_s
    unless can_transition_to?(new_status)
      raise InvalidTransition,
            "Cannot transition Quote##{id} from #{status.inspect} to #{new_status.inspect}"
    end
    update!(status: new_status)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id cargo_offer_id carrier_id transport_window_id amount_cents currency
       status expires_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cargo_offer carrier transport_window]
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

  def pickup_date_within_window
    return unless transport_window && cargo_offer&.pickup_date

    range = transport_window.available_from.to_date..transport_window.available_to.to_date
    errors.add(:pickup_date, :out_of_window_range) unless range.cover?(cargo_offer.pickup_date)
  end

  def within_vehicle_capacity
    vehicle = transport_window&.vehicle
    return unless vehicle && cargo_offer

    if cargo_offer.weight_kg.present? && cargo_offer.weight_kg.to_d > vehicle.max_load_kg
      errors.add(:weight_kg, :exceeds_vehicle_capacity)
    end

    if vehicle.volume_cm3.present? && cargo_offer.volume_cm3.to_i > vehicle.volume_cm3
      errors.add(:volume_cm3, :exceeds_vehicle_capacity)
    end
  end
end
