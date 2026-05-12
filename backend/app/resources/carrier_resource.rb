# frozen_string_literal: true

# Alba serializer for Carrier — slim variant: identity + headline numbers.
# Used wherever a carrier is embedded (e.g. inside MeResource). The full
# `CarrierDetailResource` (description + vehicles + transport_windows) lives
# in its own file so Zeitwerk can autoload it.
class CarrierResource
  include Alba::Resource
  attributes :id, :legal_name, :tax_id, :base_city, :province,
             :rating_avg, :reviews_count, :completed_shipments
end
