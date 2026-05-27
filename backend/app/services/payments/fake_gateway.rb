# frozen_string_literal: true

module Payments
  # Synchronous, deterministic happy-path gateway. Mounted in every environment
  # (development, test, production) because no real provider is integrated for
  # this academic project. Always returns :approved — there is no override
  # surface and no rejected branch reachable through the production UI.
  class FakeGateway
    extend Gateway

    def self.process_payment!(shipment:)
      _ = shipment
      OpenStruct.new(
        outcome:            :approved,
        provider_reference: "fake-#{SecureRandom.uuid}"
      )
    end
  end
end
