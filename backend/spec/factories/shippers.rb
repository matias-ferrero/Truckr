FactoryBot.define do
  factory :shipper do
    user
    company_name    { "#{Faker::Company.name} S.A." }
    billing_address { Faker::Address.full_address }
  end
end
