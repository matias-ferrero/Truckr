FactoryBot.define do
  factory :tracking_event do
    association :shipment
    kind         { "status_change" }
    from_status  { "draft" }
    to_status    { "offered" }
    recorded_at  { Time.current }
    metadata     { {} }

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
