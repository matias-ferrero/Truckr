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

  validates :amount_cents, numericality: { greater_than: 0, only_integer: true }
  validates :currency, inclusion: { in: %w[ARS] }
  validates :status,   inclusion: { in: STATES }
  validates :expires_at, presence: true

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
end
