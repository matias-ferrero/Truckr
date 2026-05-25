# frozen_string_literal: true

# Shipment — Fulfilment context aggregate root.
#
# Canonical FSM (ADR-012, amended 2026-05-24):
#
#                ┌─────────────┐   ┌────────────┐   ┌───────────┐
#                │  accepted   │──▶│ in_transit │──▶│ delivered │
#                └─────────────┘   └────────────┘   └───────────┘
#                       │                 │
#                       ▼                 ▼
#                  ┌────────────────────────┐
#                  │       cancelled        │  (terminal from accepted or in_transit)
#                  └────────────────────────┘
#
# Permissive at the model layer: model accepts any allowed pair without
# checking sprint-scope interlocks (e.g. "no cancel after an escrowed
# Payment"). The Shipments::Cancel service (REQ-BE-00033) layers those
# checks on top.
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
  has_one    :route, dependent: :destroy, inverse_of: :shipment

  # ── Validations ───────────────────────────────────────────────────────
  validates :cargo_offer_id, presence: true, uniqueness: true
  validates :status,         presence: true, inclusion: { in: STATUSES }
  validate :timestamps_match_status

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

  def self.ransackable_attributes(_auth_object = nil)
     %w[id cargo_offer_id status accepted_at picked_up_at delivered_at cancelled_at
        discarded_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cargo_offer tracking_events route payments]
  end

  private

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
