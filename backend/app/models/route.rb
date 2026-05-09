# frozen_string_literal: true

# Route — single calculated route for a Shipment.
#
# All geo / metric fields are nullable: the row is created together with
# the Shipment but populated by a downstream Google Maps Directions
# integration (separate issue). Provider defaults to google_maps_directions.
class Route < ApplicationRecord
  belongs_to :shipment, inverse_of: :route

  validates :shipment_id, uniqueness: true
  validates :provider,    presence: true
  validates :distance_m,  numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :duration_s,  numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def calculated?
    polyline.present? && calculated_at.present?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id shipment_id provider distance_m duration_s calculated_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[shipment]
  end
end
