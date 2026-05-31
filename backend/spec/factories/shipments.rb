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
      status      { "accepted" }
      accepted_at { 4.hours.ago }

      after(:create) do |shipment|
        create(:payment, :escrowed, shipment: shipment)
        shipment.update!(status: "in_transit", picked_up_at: 1.hour.ago)
      end
    end

    trait :delivered do
      status      { "accepted" }
      accepted_at { 1.day.ago }

      after(:create) do |shipment|
        create(:payment, :escrowed, shipment: shipment)
        shipment.update!(status: "delivered", picked_up_at: 4.hours.ago, delivered_at: 30.minutes.ago)
      end
    end

    trait :cancelled do
      status        { "cancelled" }
      accepted_at   { 2.hours.ago }
      cancelled_at  { 30.minutes.ago }
    end
  end
end
