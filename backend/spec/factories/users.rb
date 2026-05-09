FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@truckr.test" }
    password { "password123" }
    full_name { Faker::Name.name }
    phone     { Faker::PhoneNumber.cell_phone_in_e164 }

    trait :verified do
      verified_at { Time.current }
    end

    trait :with_carrier do
      after(:create) { |u| create(:carrier, user: u) }
    end

    trait :with_shipper do
      after(:create) { |u| create(:shipper, user: u) }
    end
  end
end
