# frozen_string_literal: true

# Wires the production-default Payments gateway. The fake gateway is mounted
# in every environment because the project is academic coursework — there is
# no real provider integration on the roadmap. A real adapter would replace
# this line at the moment it lands.
Rails.application.config.to_prepare do
  module Payments
    mattr_accessor :gateway
    self.gateway = Payments::FakeGateway
  end
end
