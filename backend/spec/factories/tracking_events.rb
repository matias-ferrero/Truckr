FactoryBot.define do
  factory :tracking_event do
    association :shipment
    kind         { "status_change" }
    from_status  { "accepted" }
    to_status    { "in_transit" }
    recorded_at  { Time.current }
    metadata     { {} }

    trait :shipment_accepted do
      kind        { "shipment_accepted" }
      from_status { nil }
      to_status   { nil }
    end

    trait :payment_escrowed do
      kind        { "payment_escrowed" }
      from_status { nil }
      to_status   { nil }
    end

    trait :payment_failed do
      kind        { "payment_failed" }
      from_status { nil }
      to_status   { nil }
    end

    trait :gps_update do
      kind        { "gps_update" }
      from_status { nil }
      to_status   { nil }
      lat         { -34.6037 }
      lng         { -58.3816 }
    end

    trait :note do
      kind        { "note" }
      from_status { nil }
      to_status   { nil }
      metadata    { { author: "ops", body: "Demo note" } }
    end
  end
end
