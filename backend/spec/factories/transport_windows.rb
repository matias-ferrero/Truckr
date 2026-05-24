FactoryBot.define do
  factory :transport_window do
    association :vehicle
    origin_zone      { "Buenos Aires" }
    destination_zone { "Córdoba" }
    price_per_km     { 1500.50 }
    max_km           { 1200 }
    sequence(:available_from) { |n| (n + 1).days.from_now }
    sequence(:available_to)   { |n| (n + 7).days.from_now }
    active { true }
    status { "open" }
  end
end
