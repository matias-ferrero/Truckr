FactoryBot.define do
  factory :transport_window do
    association :vehicle
    origin_address       { "Av. Corrientes 1234, CABA" }
    origin_locality      { "CABA" }
    origin_admin_area    { "Ciudad Autónoma de Buenos Aires" }
    origin_lat           { -34.603722 } # CABA
    origin_lng           { -58.381592 }
    destination_address  { "Av. Colón 500, Córdoba" }
    destination_locality { "Córdoba" }
    destination_admin_area { "Córdoba" }
    destination_lat      { -31.420083 } # Córdoba
    destination_lng      { -64.188776 }
    price_per_km     { 1500.50 }
    max_km           { 1200 }
    pickup_radius_km  { 50 }
    dropoff_radius_km { 50 }
    sequence(:available_from) { |n| (n + 1).days.from_now }
    sequence(:available_to)   { |n| (n + 7).days.from_now }
    active { true }
    status { "open" }

    # "Destino abierto" — all six destination fields blank in unison so the
    # open_destination_consistency validator passes (REQ-BE-00039 / ADR-014).
    trait :open_destination do
      destination_address    { nil }
      destination_locality   { nil }
      destination_admin_area { nil }
      destination_lat        { nil }
      destination_lng        { nil }
      dropoff_radius_km      { nil }
    end
  end
end
