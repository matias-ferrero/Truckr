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

  belongs_to :shipper, inverse_of: :cargos
  has_many   :cargo_offers, dependent: :destroy, inverse_of: :cargo
  has_one    :accepted_cargo_offer, -> { where(status: "accepted") },
             class_name: "CargoOffer", inverse_of: :cargo

  before_save :normalize_zone_fields

  validates :cargo_description, presence: true, length: { maximum: 200 }
  validates :pickup_address, :delivery_address, :pickup_zone, :delivery_zone, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :weight_kg, numericality: { greater_than: 0 }
  validates :volume_cm3, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :declared_value_cents,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :pickup_window_start, :pickup_window_end, presence: true
  validate  :pickup_window_is_coherent

  scope :for_shipper, ->(shipper) { where(shipper_id: shipper.id) }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }

  def editable?    = status == "open" && accepted_cargo_offer.nil?
  def cancellable? = status == "open" && accepted_cargo_offer.nil?

  # Returns the TransportWindows that match this Cargo for the purposes of
  # offering (US4/US5): active, no pending/accepted contender, origin and
  # destination zone substring-match, availability overlaps pickup window,
  # vehicle can carry the weight. Open-destination windows match any delivery zone.
  def matching_windows
    blocked = CargoOffer.where(status: %w[pending accepted]).select(:transport_window_id)
    base    = TransportWindow.active.where.not(id: blocked)

    date_params = {
      available_from_lteq: pickup_window_end,
      available_to_gteq:   pickup_window_start
    }

    fixed_dest = base.ransack(
      origin_province_normalized_cont:      pickup_zone_normalized,
      destination_province_normalized_cont: delivery_zone_normalized,
      **date_params
    ).result(distinct: true)

    open_dest = base.ransack(
      origin_province_normalized_cont: pickup_zone_normalized,
      **date_params
    ).result(distinct: true).where(destination_province_normalized: nil)

    fixed_dest.or(open_dest)
              .joins(:vehicle).where("vehicles.max_load_kg >= ?", weight_kg)
              .includes(vehicle: { carrier: :user }).order(:available_from)
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
    %w[id shipper_id status pickup_address delivery_address pickup_zone delivery_zone
       pickup_zone_normalized delivery_zone_normalized pickup_window_start pickup_window_end
       cargo_description weight_kg volume_cm3 declared_value_cents created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[shipper cargo_offers]
  end

  private

  def normalize_zone_fields
    self.pickup_zone_normalized   = I18n.transliterate(pickup_zone.to_s).downcase   if pickup_zone.present?
    self.delivery_zone_normalized = I18n.transliterate(delivery_zone.to_s).downcase if delivery_zone.present?
  end

  def pickup_window_is_coherent
    return if pickup_window_start.blank? || pickup_window_end.blank?

    errors.add(:pickup_window_end, :must_be_after_start) if pickup_window_end <= pickup_window_start
  end
end
