FactoryBot.define do
  factory :route do
    association :shipment
    provider { "google_maps_directions" }

    trait :calculated do
      polyline       { "u{~vFvyys@fS]" }
      distance_m     { 25_000 }
      duration_s     { 1_800 }
      calculated_at  { Time.current }
    end
  end
end
