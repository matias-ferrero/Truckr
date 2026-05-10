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
# 2 Users, 1 Carrier, 1 Shipper, 1 Vehicle. Idempotent.
identity_users = [
  { email: "carrier1@truckr.test", full_name: "Carrier One", role: :carrier },
  { email: "shipper1@truckr.test", full_name: "Shipper One", role: :shipper }
]

identity_users.each do |spec|
  user = User.find_or_create_by!(email: spec[:email]) do |u|
    u.password  = "Password123"
    u.full_name = spec[:full_name]
  end

  if spec[:role] == :carrier
    carrier = Carrier.find_or_create_by!(user: user) do |c|
      c.legal_name = "#{spec[:full_name]} Transport SRL"
      c.tax_id     = "30#{format('%08d', user.id)}1"
      c.base_city  = "Buenos Aires"
      c.province   = "CABA"
    end

    Vehicle.find_or_create_by!(carrier: carrier) do |v|
      v.plate        = "AA#{format('%03d', user.id)}XX"
      v.make         = "Mercedes-Benz"
      v.model        = "Sprinter"
      v.max_load_kg  = 5_000.0
      v.vehicle_type = "truck_small"
    end
  end

  if spec[:role] == :shipper
    Shipper.find_or_create_by!(user: user) do |s|
      s.company_name = "#{spec[:full_name]} S.A."
      s.tax_id       = "20#{format('%08d', user.id)}9"
    end
  end
end

# Marketplace fixtures — REQ-BE-00021.
# 2 TransportWindows, 2 CargoOffers, 2 Quotes. Idempotent. Skips silently when
# the dependent Identity rows have not been seeded yet.
if defined?(Carrier) && defined?(Shipper) && defined?(Vehicle) &&
   Carrier.any? && Shipper.any? && Vehicle.any?

  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  if vehicle
    tw1 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_zone: "Buenos Aires", destination_zone: "Córdoba"
    ) do |w|
      w.price_per_km   = 1500.0
      w.max_km         = 1200
      w.available_from = 1.day.from_now
      w.available_to   = 10.days.from_now
      w.active         = true
    end

    tw2 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_zone: "Rosario", destination_zone: "Mendoza"
    ) do |w|
      w.price_per_km   = 1700.0
      w.max_km         = 900
      w.available_from = 11.days.from_now
      w.available_to   = 18.days.from_now
      w.active         = true
    end

    co1 = CargoOffer.find_or_create_by!(
      shipper: shipper, cargo_description: "Pallets de granos"
    ) do |c|
      c.pickup_address       = "Puerto de Buenos Aires"
      c.delivery_address     = "Av. Sabattini 5500, Córdoba"
      c.pickup_date          = 3.days.from_now
      c.weight_kg            = 12_000.0
      c.volume_cm3           = 30_000_000
      c.declared_value_cents = 150_000_000
    end

    co2 = CargoOffer.find_or_create_by!(
      shipper: shipper, cargo_description: "Materiales de construcción"
    ) do |c|
      c.pickup_address       = "Parque industrial Rosario"
      c.delivery_address     = "Godoy Cruz 1200, Mendoza"
      c.pickup_date          = 4.days.from_now
      c.weight_kg            = 8_500.0
      c.volume_cm3           = 18_000_000
      c.declared_value_cents = 90_000_000
    end

    Quote.find_or_create_by!(cargo_offer: co1, carrier: carrier, transport_window: tw1) do |q|
      q.amount_cents = 18_000_000
      q.currency     = "ARS"
      q.status       = "pending"
      q.expires_at   = 24.hours.from_now
    end

    Quote.find_or_create_by!(cargo_offer: co2, carrier: carrier, transport_window: tw2) do |q|
      q.amount_cents = 15_300_000
      q.currency     = "ARS"
      q.status       = "pending"
      q.expires_at   = 24.hours.from_now
    end
  end
end

# Fulfilment fixtures — REQ-BE-00022.
# One Shipment per state for any available Quote rows. Idempotent.
if defined?(Quote) && defined?(Shipment) && Quote.exists?
  Shipment::STATUSES.each_with_index do |state, i|
    quote = Quote.offset(i).first or next
    next if Shipment.with_discarded.exists?(quote_id: quote.id)

    attrs = { quote: quote, status: state }
    case state
    when "in_transit" then attrs[:picked_up_at] = 1.hour.ago
    when "delivered"  then attrs.merge!(picked_up_at: 4.hours.ago, delivered_at: 30.minutes.ago)
    when "settled"    then attrs.merge!(picked_up_at: 1.day.ago, delivered_at: 6.hours.ago, settled_at: 30.minutes.ago)
    when "cancelled"  then attrs.merge!(cancelled_at: 1.minute.ago, cancellation_reason: "demo")
    end

    Shipment.create!(attrs)
  end
end
