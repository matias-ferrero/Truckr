# frozen_string_literal: true

# Shipment — Fulfilment context aggregate root.
#
# Canonical FSM (ADR-012, amended 2026-05-30):
#
#                ┌─────────────┐   ┌────────────┐    ┌───────────┐
#                │  accepted   │──▶│ in_transit │──▶│ delivered │
#                └─────────────┘   └────────────┘    └───────────┘
#                       │                 │
#                       ▼                 ▼
#                  ┌────────────────────────┐
#                  │       cancelled        │  (terminal from accepted or in_transit)
#                  └────────────────────────┘
#
# Model-level interlock: any transition that leaves `accepted` requires at
# least one escrowed Payment linked to the shipment.
# Payment state is tracked via the payments association (payment_escrowed?)
# rather than a separate FSM state — accepted stays accepted after payment.
class Shipment < ApplicationRecord
  class IllegalTransition < StandardError; end

  ALLOWED_TRANSITIONS = {
    accepted:   [ :in_transit, :cancelled ],
    in_transit: [ :delivered, :cancelled ],
    delivered:  [],
    cancelled:  []
  }.freeze

  STATUS_TIMESTAMP_COLUMNS = {
    accepted:   :accepted_at,
    in_transit: :picked_up_at,
    delivered:  :delivered_at,
    cancelled:  :cancelled_at
  }.freeze

  STATUSES = ALLOWED_TRANSITIONS.keys.map(&:to_s).freeze

  enum :status, STATUSES.index_with(&:itself), prefix: true

  # ── Soft-delete (ADR-009) ─────────────────────────────────────────────
  default_scope { where(discarded_at: nil) }
  scope :discarded,      -> { unscope(where: :discarded_at).where.not(discarded_at: nil) }
  scope :with_discarded, -> { unscope(where: :discarded_at) }

  def discard!
    update!(discarded_at: Time.current)
  end

  # ── Associations ──────────────────────────────────────────────────────
  belongs_to :cargo_offer, inverse_of: :shipment
  has_many   :tracking_events, dependent: :destroy, inverse_of: :shipment
  has_many   :payments, dependent: :restrict_with_error, inverse_of: :shipment
  has_many   :reviews, dependent: :destroy, inverse_of: :shipment
  has_one    :route, dependent: :destroy, inverse_of: :shipment
  has_one    :payout, dependent: :destroy, inverse_of: :shipment

  # ── Validations ───────────────────────────────────────────────────────
  validates :cargo_offer_id, presence: true, uniqueness: true
  validates :status,         presence: true, inclusion: { in: STATUSES }
  validate :timestamps_match_status
  validate :in_transit_or_delivered_requires_escrowed_payment

  # ── Scopes ────────────────────────────────────────────────────────────
  scope :active,      -> { where(status: %w[accepted in_transit]) }
  scope :completed,   -> { where(status: %w[delivered]) }
  scope :in_progress, -> { active }

  # ── State machine ─────────────────────────────────────────────────────
  #
  # Atomically advances `status` to `new_status`, validates the transition,
  # stamps the matching timestamp column, and emits a TrackingEvent of
  # kind=:status_change. Raises Shipment::IllegalTransition on a rejected
  # pair. Wrapped in a row-level lock so concurrent transition attempts
  # serialise instead of racing.
  def transition_to!(new_status, reason: nil, at: Time.current)
    new_status = new_status.to_sym
    transaction do
      with_lock do
        from = status.to_sym
        unless ALLOWED_TRANSITIONS.fetch(from, []).include?(new_status)
          raise IllegalTransition,
                "Shipment #{id}: transition #{from} -> #{new_status} is not allowed"
        end

        # Payment validation: prevent transition from accepted if payment is pending
        if from == :accepted && !payment_escrowed?
          raise IllegalTransition,
                "Shipment #{id}: cannot transition from accepted without escrowed payment"
        end

        attrs = { status: new_status.to_s }
        if (col = STATUS_TIMESTAMP_COLUMNS[new_status])
          attrs[col] = at
        end
        update!(attrs)

        tracking_events.create!(
          kind:        :status_change,
          from_status: from.to_s,
          to_status:   new_status.to_s,
          recorded_at: at,
          metadata:    { reason: reason }.compact
        )
      end
    end
  end

  # Payment status check: returns true if shipment has at least one escrowed payment.
  # Checks loaded records first so callers in serializers (where payments are eager-loaded)
  # don't pay an extra SQL round-trip.
  def payment_escrowed?
    if payments.loaded?
      payments.any? { |p| p.state == "escrowed" }
    else
      payments.exists?(state: :escrowed)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id cargo_offer_id status accepted_at picked_up_at
       delivered_at cancelled_at discarded_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cargo_offer tracking_events route payments reviews]
  end

  private

  def in_transit_or_delivered_requires_escrowed_payment
    return unless %w[in_transit delivered].include?(status.to_s)
    return if payments.where(state: "escrowed").exists?

    errors.add(:base, "cannot be in_transit or delivered without an escrowed payment")
  end

  def timestamps_match_status
    return if status.blank?

    case status.to_sym
    when :accepted
      errors.add(:accepted_at, "must be set when accepted") if accepted_at.blank?
    when :in_transit
      errors.add(:picked_up_at, "must be set when in transit") if picked_up_at.blank?
    when :delivered
      errors.add(:delivered_at, "must be set when delivered") if delivered_at.blank?
    when :cancelled
      errors.add(:cancelled_at, "must be set when cancelled") if cancelled_at.blank?
    end
  end
end
