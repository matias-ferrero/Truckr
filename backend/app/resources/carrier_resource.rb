# frozen_string_literal: true

class CarrierResource
  include Alba::Resource
  attributes :id, :legal_name, :tax_id, :base_city, :province, :rating_avg, :completed_shipments
end
