# frozen_string_literal: true

# Alba serializer for Carrier — slim variant: identity + headline numbers.
# Used wherever a carrier is embedded (e.g. inside MeResource). The full
# `CarrierDetailResource` (description + vehicles + transport_windows) lives
# in its own file so Zeitwerk can autoload it.
class CarrierResource
  include Alba::Resource
  attributes :id, :legal_name, :tax_id, :base_city, :province,
             :completed_shipments

  # Computed from shipper-authored reviews (US26), not the denormalised columns.
  attribute :rating_avg do |carrier|
    avg = carrier.shipper_rating_avg
    avg.nil? ? nil : avg.to_s
  end

  attribute :reviews_count do |carrier|
    carrier.shipper_reviews_count
  end
end
