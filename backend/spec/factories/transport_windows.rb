FactoryBot.define do
  factory :transport_window do
    association :vehicle
    origin_province  { "Buenos Aires" }
    origin_locality  { nil }
    destination_province { "Córdoba" }
    destination_locality { nil }
    price_per_km     { 1500.50 }
    max_km           { 1200 }
    sequence(:available_from) { |n| (n + 1).days.from_now }
    sequence(:available_to)   { |n| (n + 7).days.from_now }
    active { true }
    status { "open" }

    trait :open_destination do
      destination_province             { nil }
      destination_province_normalized  { nil }
      destination_locality             { nil }
      destination_locality_normalized  { nil }
    end
  end
end
