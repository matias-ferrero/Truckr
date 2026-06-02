# frozen_string_literal: true

# Review — a rating + optional comment written about one side of a completed
# Shipment. Table + model introduced by US20 ([[REQ-BE-00042]]); shared with
# US26 / US30 / US54.
#
# `authored_by` distinguishes the two possible review directions:
#   - shipper_authored (US20): Shipper → Carrier.
#   - carrier_authored (US30): Carrier → Shipper.
#
# A review only exists once a Shipment reaches `delivered`. The state guard and
# the per-direction uniqueness guard live in Reviews::Create (race-safe under
# shipment.with_lock). The model carries the data invariants: rating range,
# body length, and the DB-backed uniqueness scope.
class Review < ApplicationRecord
  AUTHORS = { shipper_authored: "shipper", carrier_authored: "carrier" }.freeze

  belongs_to :shipment, inverse_of: :reviews
  belongs_to :shipper
  belongs_to :carrier

  enum :authored_by, AUTHORS

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :body,   length: { maximum: 1_000 }, allow_nil: true
  validates :shipment_id, uniqueness: { scope: :authored_by }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id shipment_id shipper_id carrier_id rating body authored_by
       created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[shipment shipper carrier]
  end
end
