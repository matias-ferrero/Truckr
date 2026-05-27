# frozen_string_literal: true

# Alba resource for `POST /api/shipments/:shipment_id/payments`. The success
# response is intentionally minimal — the contact reveal is fetched in a
# follow-up GET against the shipment detail endpoint.
class PaymentResource
  include Alba::Resource

  attribute :payment_id do |payment|
    payment.id
  end

  attributes :state
end
