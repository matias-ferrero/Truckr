FactoryBot.define do
  factory :shipment do
    association :quote
    status { "draft" }

    trait :draft      do; status { "draft" } end
    trait :quoted     do; status { "quoted" } end
    trait :accepted   do; status { "accepted" } end
    trait :in_transit do
      status        { "in_transit" }
      picked_up_at  { 1.hour.ago }
    end
    trait :delivered do
      status        { "delivered" }
      picked_up_at  { 4.hours.ago }
      delivered_at  { 30.minutes.ago }
    end
    trait :settled do
      status        { "settled" }
      picked_up_at  { 1.day.ago }
      delivered_at  { 6.hours.ago }
      settled_at    { 30.minutes.ago }
    end
    trait :cancelled do
      status              { "cancelled" }
      cancelled_at        { 5.minutes.ago }
      cancellation_reason { "demo cancellation" }
    end
  end
end
