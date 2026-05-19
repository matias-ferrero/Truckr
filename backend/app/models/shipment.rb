# frozen_string_literal: true

# Shipment — Fulfilment context aggregate root.
#
# State machine (hand-rolled, no gem — Decision F in domain-model.md):
#
#   ┌───────┐   ┌─────────┐   ┌──────────┐   ┌────────────┐   ┌───────────┐   ┌──────────┐
#   │ draft │──▶│ offered │──▶│ accepted │──▶│ in_transit │──▶│ delivered │──▶│ settled  │
#   └───────┘   └────┬────┘   └────┬─────┘   └─────┬──────┘   └───────────┘   └──────────┘
#                    │             │               │
#                    ▼             ▼               ▼
#               ┌─────────────────────────────────────┐
#               │             cancelled               │
#               └─────────────────────────────────────┘
#
# `delivered → cancelled` is NOT allowed: once goods are delivered the only forward
# path is `settled`. Disputes are handled in Commerce against the Payment row.
class Shipment < ApplicationRecord
  class IllegalTransition < StandardError; end

  ALLOWED_TRANSITIONS = {
    draft:      [ :offered ],
    offered:    [ :accepted, :cancelled ],
    accepted:   [ :in_transit, :cancelled ],
    in_transit: [ :delivered, :cancelled ],
    delivered:  [ :settled ],
    settled:    [],
    cancelled:  []
  }.freeze

  STATUS_TIMESTAMP_COLUMNS = {
    in_transit: :picked_up_at,
    delivered:  :delivered_at,
    settled:    :settled_at,
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
  has_one    :route, dependent: :destroy, inverse_of: :shipment

  # ── Validations ───────────────────────────────────────────────────────
  validates :cargo_offer_id, presence: true, uniqueness: true
  validates :status,         presence: true, inclusion: { in: STATUSES }
  validates :cancellation_reason,
            presence: true,
            if: -> { status_cancelled? }
  validate :timestamps_match_status, on: :update

  # ── Scopes ────────────────────────────────────────────────────────────
  scope :active,      -> { where.not(status: %w[settled cancelled]) }
  scope :completed,   -> { where(status: %w[settled cancelled]) }
  scope :in_progress, -> { where(status: %w[accepted in_transit]) }

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
        attrs[:cancellation_reason] = reason if new_status == :cancelled
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
    %w[id cargo_offer_id status picked_up_at delivered_at settled_at cancelled_at
       cancellation_reason discarded_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cargo_offer tracking_events route]
  end

  private

  def timestamps_match_status
    case status.to_sym
    when :cancelled
      errors.add(:cancelled_at, "must be set when cancelled") if cancelled_at.blank?
    when :settled
      errors.add(:settled_at, "must be set when settled") if settled_at.blank?
    end
  end
end
