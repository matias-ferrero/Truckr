FactoryBot.define do
  factory :cargo_offer do
    association :carrier
    # Coordinate the cargo's pickup window with the transport_window's range so
    # CargoOffer's pickup_window_overlaps_transport_window cross-validation
    # passes by default.
    transport_window do
      association :transport_window, available_from: 1.day.from_now, available_to: 10.days.from_now
    end
    cargo do
      association :cargo, pickup_window_start: 3.days.from_now, pickup_window_end: 5.days.from_now
    end

    amount_cents { 2_500_000 }
    currency     { "ARS" }
    status       { "pending" }
    expires_at   { 24.hours.from_now }

    trait(:pending)   { status { "pending" } }
    trait(:accepted)  do
      status { "accepted" }
      accepted_at { 5.minutes.ago }
    end
    trait(:paid)      { status { "paid" } }
    trait(:rejected)  do
      status { "rejected" }
      rejected_at { 5.minutes.ago }
    end
    trait(:expired)   { status { "expired" } }
    trait(:cancelled) { status { "cancelled" } }
  end
end
