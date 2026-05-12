FactoryBot.define do
  factory :carrier do
    user
    legal_name { "#{Faker::Company.name} SRL" }
    base_city  { "Buenos Aires" }
    province   { "CABA" }
    rating_avg { 0.0 }
    reviews_count { 0 }
    completed_shipments { 0 }
  end
end
