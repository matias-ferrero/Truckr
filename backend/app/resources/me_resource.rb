# frozen_string_literal: true

# MeResource — composed view returned by /api/auth/{register,login,me}.
# Includes the user's roles (derived from carrier/shipper relations) and
# nested profile rows when present.
class MeResource
  include Alba::Resource

  attributes :id, :email, :full_name, :phone, :verified_at

  attribute :roles do |user|
    %w[carrier shipper].select { |r| user.public_send("#{r}?") }
  end

  one :carrier, resource: CarrierResource
  one :shipper, resource: ShipperResource
end
