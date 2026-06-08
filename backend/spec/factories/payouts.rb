FactoryBot.define do
  factory :payout do
    association :shipment, factory: %i[shipment delivered]
    payment do
      shipment.payments.find_by(state: "escrowed") ||
        association(:payment, :escrowed, shipment: shipment)
    end

    after(:build) do |payout|
      payout.gross_amount_cents ||= payout.payment.amount_cents
      payout.commission_rate    ||= BigDecimal("0.15")
      commission = (payout.gross_amount_cents * payout.commission_rate).ceil
      payout.commission_cents   ||= commission
      payout.amount_cents       ||= payout.gross_amount_cents - commission
    end

    currency { "ARS" }
    state    { "paid" }
    paid_at  { Time.current }

    trait :paid do
      state   { "paid" }
      paid_at { Time.current }
    end

    trait :failed do
      state          { "failed" }
      paid_at        { nil }
      failed_at      { Time.current }
      failure_reason { "no_escrowed_payment" }
    end
  end
end
