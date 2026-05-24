FactoryBot.define do
  factory :shipment do
    association :cargo_offer
    status { "pending_payment" }
    accepted_at { 1.hour.ago }

    trait :pending_payment do
      status      { "pending_payment" }
      accepted_at { 1.hour.ago }
    end

    trait :to_pick_up do
      status      { "to_pick_up" }
      accepted_at { 4.hours.ago }
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
  end
end
