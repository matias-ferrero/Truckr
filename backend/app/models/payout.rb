# frozen_string_literal: true

# Payout — born-terminal settlement record (ADR-012, US15 / REQ-BE-00046).
#
# Created by Payouts::Create when the Carrier confirms delivery. Immutable
# after creation — no updates are ever performed. The `(shipment_id, state)`
# index in the DB is the race-safety guard: Payouts::Create acquires a row
# lock on the parent Shipment before inserting, so two concurrent requests
# cannot produce two `paid` rows.
#
# States:
#   paid   — funds calculated and payout recorded (MVP: internal accounting only)
#   failed — creation failed (e.g. no escrowed payment found)
class Payout < ApplicationRecord
  STATES = %w[paid failed].freeze

  IMMUTABLE_FIELDS = %w[
    shipment_id payment_id gross_amount_cents commission_rate
    commission_cents amount_cents currency state paid_at failed_at
  ].freeze

  # ── Soft-delete (ADR-009) ──────────────────────────────────────────────────
  default_scope { where(discarded_at: nil) }
  scope :discarded,      -> { unscope(where: :discarded_at).where.not(discarded_at: nil) }
  scope :with_discarded, -> { unscope(where: :discarded_at) }

  def discard!
    update!(discarded_at: Time.current)
  end

  # ── Associations ────────────────────────────────────────────────────────────
  belongs_to :shipment, inverse_of: :payout
  belongs_to :payment,  inverse_of: :payout

  # ── Enums ───────────────────────────────────────────────────────────────────
  enum :state, STATES.index_with(&:itself), prefix: true

  # ── Validations ─────────────────────────────────────────────────────────────
  validates :gross_amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :commission_rate,    presence: true, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
  validates :commission_cents,   presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :amount_cents,       presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency,           presence: true
  validates :state,              presence: true, inclusion: { in: STATES }

  before_update :prevent_mutation

  private

  def prevent_mutation
    locked = changes.keys & IMMUTABLE_FIELDS
    return if locked.empty?

    raise ActiveRecord::ReadOnlyRecord,
          "Payout fields #{locked.join(', ')} are immutable after create"
  end
end
