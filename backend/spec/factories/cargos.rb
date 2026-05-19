FactoryBot.define do
  factory :cargo do
    association :shipper
    pickup_address       { "Av. Corrientes 1234, CABA" }
    delivery_address     { "Av. Colón 500, Córdoba" }
    pickup_date          { 2.days.from_now }
    cargo_description    { "Pallets de electrodomésticos" }
    weight_kg            { 1500.0 }
    volume_cm3           { 4_000_000 }
    declared_value_cents { 5_000_000 }
  end
end
