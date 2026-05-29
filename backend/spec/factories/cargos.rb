FactoryBot.define do
  factory :cargo do
    association :shipper
    status                { "open" }
    pickup_address        { "Av. Corrientes 1234, CABA" }
    pickup_locality       { "CABA" }
    pickup_admin_area     { "Ciudad Autónoma de Buenos Aires" }
    delivery_address      { "Av. Colón 500, Córdoba" }
    delivery_locality     { "Córdoba" }
    delivery_admin_area   { "Córdoba" }
    pickup_lat            { -34.603722 } # CABA
    pickup_lng            { -58.381592 }
    delivery_lat          { -31.420083 } # Córdoba
    delivery_lng          { -64.188776 }
    pickup_window_start   { 2.days.from_now }
    pickup_window_end     { 4.days.from_now }
    cargo_description     { "Pallets de electrodomésticos" }
    weight_kg             { 1500.0 }
    volume_cm3            { 4_000_000 }
    declared_value_cents  { 5_000_000 }

    trait(:open)      { status { "open" } }
    trait(:accepted)  { status { "accepted" } }
    trait(:cancelled) do
      status              { "cancelled" }
      cancelled_at        { Time.current }
      cancellation_reason { "Ya no necesito el transporte" }
    end
  end
end
