# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

admin_email    = ENV["SEED_ADMIN_EMAIL"]
admin_password = ENV["SEED_ADMIN_PASSWORD"]

if Rails.env.production?
  if admin_email.blank? || admin_password.blank?
    abort("SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD must be set in production")
  end
else
  admin_email    = admin_email.presence    || "admin@example.com"
  admin_password = admin_password.presence || "password"
end

AdminUser.find_or_create_by!(email: admin_email) do |user|
  user.password              = admin_password
  user.password_confirmation = admin_password
end

# Identity fixtures — REQ-BE-00020.
# 3 Users, 2 Carriers, 2 Shippers, 2 Vehicles. Idempotent.
identity_users = [
  { email: "carrier1@truckr.test", full_name: "Carrier One", role: :carrier },
  { email: "shipper1@truckr.test", full_name: "Shipper One", role: :shipper },
  { email: "both@truckr.test",     full_name: "Both Roles",  role: :both    }
]

identity_users.each do |spec|
  user = User.find_or_create_by!(email: spec[:email]) do |u|
    u.password  = "password"
    u.full_name = spec[:full_name]
  end

  if %i[carrier both].include?(spec[:role])
    carrier = Carrier.find_or_create_by!(user: user) do |c|
      c.legal_name = "#{spec[:full_name]} Transport SRL"
      c.tax_id     = "30#{format('%08d', user.id)}1"
      c.base_city  = "Buenos Aires"
      c.province   = "CABA"
    end

    Vehicle.find_or_create_by!(carrier: carrier) do |v|
      v.plate        = "AA#{format('%03d', user.id)}XX"
      v.capacity_kg  = 5_000
      v.vehicle_type = "truck_small"
    end
  end

  if %i[shipper both].include?(spec[:role])
    Shipper.find_or_create_by!(user: user) do |s|
      s.company_name = "#{spec[:full_name]} S.A."
      s.tax_id       = "20#{format('%08d', user.id)}9"
    end
  end
end
