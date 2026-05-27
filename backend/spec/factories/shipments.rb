FactoryBot.define do
  factory :shipment do
    association :cargo_offer
    status { "accepted" }
    accepted_at { 1.hour.ago }

    trait :accepted do
      status      { "accepted" }
      accepted_at { 1.hour.ago }
    end

    trait :in_transit do
      status        { "in_transit" }
      accepted_at   { 4.hours.ago }
      picked_up_at  { 1.hour.ago }
    end

    trait :delivered do
      status        { "delivered" }
      accepted_at   { 1.day.ago }
      picked_up_at  { 4.hours.ago }
      delivered_at  { 30.minutes.ago }
    end

    trait :pending_payment do
      status               { "pending_payment" }
      accepted_at          { 4.hours.ago }
      payment_received_at  { 1.hour.ago }
    end

    trait :cancelled do
      status        { "cancelled" }
      accepted_at   { 2.hours.ago }
      cancelled_at  { 30.minutes.ago }
    end
  end
end
