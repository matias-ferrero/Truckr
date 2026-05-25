FactoryBot.define do
  factory :payment do
    association :shipment, factory: %i[shipment accepted]
    amount_cents  { 50_000 }
    currency      { "ARS" }
    provider      { "fake" }
    state         { "escrowed" }
    escrowed_at   { Time.current }

    trait :escrowed do
      state              { "escrowed" }
      escrowed_at        { Time.current }
      failed_at          { nil }
      failure_reason     { nil }
      provider_reference { "fake-#{SecureRandom.hex(4)}" }
    end

    trait :failed do
      state              { "failed" }
      escrowed_at        { nil }
      failed_at          { Time.current }
      failure_reason     { "card_declined" }
      provider_reference { nil }
    end
  end
end
