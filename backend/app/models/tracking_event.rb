# frozen_string_literal: true

# TrackingEvent — append-only log entry tied to a Shipment.
#
# `kind` is one of:
#   - status_change : emitted by Shipment#transition_to! on every FSM step.
#   - gps_update    : emitted by POST /api/trips/:id/locations (owned by a
#                     downstream tracking issue; this model just admits it).
#   - note          : free-form operational note (ActiveAdmin / staff).
class TrackingEvent < ApplicationRecord
  KINDS = %w[status_change gps_update note].freeze

  belongs_to :shipment, inverse_of: :tracking_events

  serialize :metadata, coder: JSON

  validates :kind,        inclusion: { in: KINDS }
  validates :recorded_at, presence: true
  validates :from_status, presence: true, if: -> { kind == "status_change" }
  validates :to_status,   presence: true, if: -> { kind == "status_change" }
  validates :lat, :lng,   presence: true, if: -> { kind == "gps_update" }

  scope :gps,        -> { where(kind: "gps_update") }
  scope :recent,     ->(n = 50) { order(recorded_at: :desc).limit(n) }
  scope :for_status, -> { where(kind: "status_change") }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id shipment_id kind from_status to_status lat lng recorded_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[shipment]
  end
end
