FactoryBot.define do
  factory :quote do
    association :cargo_offer
    association :carrier
    association :transport_window
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
