# frozen_string_literal: true

module Payments
  # Payment gateway interface. Implementations are synchronous and deterministic
  # for the MVP. The contract is: given a Shipment, return a struct describing
  # the outcome of a single payment attempt. The :approved outcome is the only
  # one expected in the MVP — the Symbol keeps the door open for a real adapter
  # that may add other outcomes later.
  #
  # Concrete adapters extend this module and implement `process_payment!`.
  module Gateway
    # @param shipment [Shipment]
    # @return [#outcome, #provider_reference] outcome ∈ {:approved}.
    def process_payment!(shipment:)
      raise NotImplementedError
    end
  end
end
