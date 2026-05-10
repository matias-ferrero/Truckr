# frozen_string_literal: true

class ShipperResource
  include Alba::Resource
  attributes :id, :company_name, :tax_id, :billing_address
end
