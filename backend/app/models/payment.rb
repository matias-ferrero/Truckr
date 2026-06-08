# frozen_string_literal: true

# Payment — born-terminal record of one gateway attempt (ADR-012, amended
# 2026-05-24). Bare AR shell: validations, enums, and an immutability guard
# that locks the terminal-state fields after create. The write side
# (`Payments::Create`, `Payments::Gateway`) lands with REQ-BE-00033.
class Payment < ApplicationRecord
  STATES    = %w[escrowed failed].freeze
  PROVIDERS = %w[fake mercadopago stripe other].freeze

  IMMUTABLE_FIELDS = %w[shipment_id amount_cents currency provider state escrowed_at failed_at].freeze

  belongs_to :shipment, inverse_of: :payments
  has_one    :payout,   inverse_of: :payment

  enum :state,    STATES.index_with(&:itself),    prefix: true
  enum :provider, PROVIDERS.index_with(&:itself), prefix: true

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency,     presence: true
  validates :provider,     presence: true, inclusion: { in: PROVIDERS }
  validates :state,        presence: true, inclusion: { in: STATES }

  before_update :prevent_terminal_mutation

  def self.ransackable_attributes(_auth_object = nil)
    %w[id shipment_id amount_cents currency provider provider_reference state
       escrowed_at failed_at failure_reason created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[shipment]
  end

  private

  def prevent_terminal_mutation
    locked = changes.keys & IMMUTABLE_FIELDS
    return if locked.empty?

    raise ActiveRecord::ReadOnlyRecord,
          "Payment fields #{locked.join(', ')} are immutable after create"
  end
end
