# frozen_string_literal: true

# TrackingEvent — append-only log entry tied to a Shipment.
#
# Event lifecycle — each action that mutates a Shipment or its Payment emits
# one TrackingEvent. Until REQ-BE-00038 wires FSM callbacks, events are seeded
# manually. Once that lands, the FSM/service layer becomes the sole emitter and
# seed-created events become permanent historical fixtures.
#
# `kind` values and their triggers:
#
# Lifecycle (emitted by the Shipment FSM — REQ-BE-00038):
#   shipment_accepted   : Shipment created when a CargoOffer is accepted
#   status_change       : Generic FSM step (used until REQ-BE-00038 activates
#                         dedicated transition kinds; kept for back-compat)
#   shipment_in_transit : Carrier calls start_transit — replaces
#                         status_change(accepted→in_transit) once REQ-BE-00038 lands
#   shipment_delivered  : Carrier calls deliver — replaces
#                         status_change(in_transit→delivered) once REQ-BE-00038 lands
#   shipment_cancelled  : Any party cancels — replaces status_change(*→cancelled)
#
# Payment (emitted by Payment service layer — REQ-BE-00038):
#   payment_escrowed    : Shipper's payment captured and held in escrow
#   payment_failed      : Payment attempt rejected by the provider
#
# Infrastructure (not lifecycle):
#   gps_update          : POST /api/trips/:id/locations — location ping
#   note                : Free-form operational note (ActiveAdmin / staff)
class TrackingEvent < ApplicationRecord
  KINDS = %w[
    status_change gps_update note
    shipment_accepted shipment_in_transit shipment_delivered shipment_cancelled
    payment_escrowed payment_failed
  ].freeze

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
