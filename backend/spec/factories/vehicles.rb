FactoryBot.define do
  factory :vehicle do
    carrier
    sequence(:plate) { |n| format("AA%03dXX", n % 1000) }
    capacity_kg  { 5_000 }
    vehicle_type { "truck_small" }
    gps_enabled  { false }
  end
end
