FactoryBot.define do
  factory :vehicle do
    carrier
    sequence(:plate) { |n| format("AA%03dXX", n % 1000) }
    make         { "Mercedes-Benz" }
    model        { "Sprinter" }
    year         { 2020 }
    max_load_kg  { 5_000.0 }
    vehicle_type { "truck_small" }
    gps_enabled  { false }
    length_cm    { 600 }
    width_cm     { 200 }
    height_cm    { 250 }
  end
end
