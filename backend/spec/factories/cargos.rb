FactoryBot.define do
  factory :cargo do
    association :shipper
    status               { "open" }
    pickup_address       { "Av. Corrientes 1234, CABA" }
    delivery_address     { "Av. Colón 500, Córdoba" }
    pickup_zone          { "Buenos Aires" }
    delivery_zone        { "Córdoba" }
    pickup_window_start  { 2.days.from_now }
    pickup_window_end    { 4.days.from_now }
    cargo_description    { "Pallets de electrodomésticos" }
    weight_kg            { 1500.0 }
    volume_cm3           { 4_000_000 }
    declared_value_cents { 5_000_000 }

    trait(:open)      { status { "open" } }
    trait(:accepted)  { status { "accepted" } }
    trait(:cancelled) do
      status              { "cancelled" }
      cancelled_at        { Time.current }
      cancellation_reason { "Ya no necesito el transporte" }
    end
  end
end
