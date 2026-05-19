FactoryBot.define do
  factory :quote do
    association :carrier
    # Coordinate cargo_offer.pickup_date with the transport_window's range so
    # Quote's pickup_date_within_window cross-validation passes by default.
    transport_window { association :transport_window, available_from: 1.day.from_now, available_to: 10.days.from_now }
    cargo_offer      { association :cargo_offer, pickup_date: 3.days.from_now.to_date }

    amount_cents { 2_500_000 }
    currency     { "ARS" }
    status       { "pending" }
    expires_at   { 24.hours.from_now }

    trait(:pending)   { status { "pending" } }
    trait(:accepted)  { status { "accepted" } }
    trait(:paid)      { status { "paid" } }
    trait(:expired)   { status { "expired" } }
    trait(:cancelled) { status { "cancelled" } }
  end
end
