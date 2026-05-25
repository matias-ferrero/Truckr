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

# Marketplace fixtures — REQ-BE-00021 (post-rename REF-BE-00002; schema +
# validations updated by REQ-BE-00032). Seeds Cargo publications + CargoOffer
# bids consistent with every model rule: TransportWindows on a vehicle never
# overlap; a Cargo weighs within the vehicle's capacity; a CargoOffer's Cargo
# pickup window overlaps the target window; a window holds at most one
# pending/accepted offer (window-lock). cargo1 carries two parallel offers;
# cargo2 is left un-offered so its detail demos the matches view against the
# still-free tw3. Idempotent. Skips silently when the dependent Identity rows
# have not been seeded yet.
if defined?(Carrier) && defined?(Shipper) && defined?(Vehicle) &&
   Carrier.any? && Shipper.any? && Vehicle.any?

  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  if vehicle
    # Three non-overlapping windows on the same vehicle — TransportWindow
    # rejects overlapping active windows per vehicle.
    tw1 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_zone: "Buenos Aires", destination_zone: "Córdoba"
    ) do |w|
      w.price_per_km   = 1500.0
      w.max_km         = 1200
      w.available_from = 1.day.from_now
      w.available_to   = 9.days.from_now
      w.active         = true
    end

    tw2 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_zone: "Rosario", destination_zone: "Mendoza"
    ) do |w|
      w.price_per_km   = 1700.0
      w.max_km         = 900
      w.available_from = 11.days.from_now
      w.available_to   = 19.days.from_now
      w.active         = true
    end

    tw3 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_zone: "La Plata", destination_zone: "Mar del Plata"
    ) do |w|
      w.price_per_km   = 1400.0
      w.max_km         = 500
      w.available_from = 21.days.from_now
      w.available_to   = 29.days.from_now
      w.active         = true
    end

    # Cargo weights stay within the seeded vehicle's 5 t capacity so the
    # CargoOffer capacity validation passes; pickup windows overlap the
    # windows their offers target.
    cargo1 = Cargo.find_or_create_by!(
      shipper: shipper, cargo_description: "Pallets de granos"
    ) do |c|
      c.pickup_address       = "Puerto de Buenos Aires"
      c.delivery_address     = "Av. Sabattini 5500, Córdoba"
      c.pickup_zone          = "Buenos Aires"
      c.delivery_zone        = "Córdoba"
      c.pickup_window_start  = 5.days.from_now
      c.pickup_window_end    = 15.days.from_now
      c.weight_kg            = 4_200.0
      c.volume_cm3           = 30_000_000
      c.declared_value_cents = 150_000_000
    end

    cargo2 = Cargo.find_or_create_by!(
      shipper: shipper, cargo_description: "Materiales de construcción"
    ) do |c|
      c.pickup_address       = "Av. 7 1200, La Plata"
      c.delivery_address     = "Av. Luro 3500, Mar del Plata"
      c.pickup_zone          = "La Plata"
      c.delivery_zone        = "Mar del Plata"
      c.pickup_window_start  = 22.days.from_now
      c.pickup_window_end    = 27.days.from_now
      c.weight_kg            = 3_800.0
      c.volume_cm3           = 18_000_000
      c.declared_value_cents = 90_000_000
    end

    # Parallel-offers demo: cargo1 collects two pending bids against two
    # distinct windows so the shipper UI has data for the comparison view
    # (US10/US12). tw3 is intentionally left un-offered — cargo2's detail
    # then demos the matches view against it.
    CargoOffer.find_or_create_by!(cargo: cargo1, carrier: carrier, transport_window: tw1) do |co|
      co.amount_cents = 18_000_000
      co.currency     = "ARS"
      co.status       = "pending"
      co.expires_at   = 24.hours.from_now
    end

    CargoOffer.find_or_create_by!(cargo: cargo1, carrier: carrier, transport_window: tw2) do |co|
      co.amount_cents = 16_500_000
      co.currency     = "ARS"
      co.status       = "pending"
      co.expires_at   = 24.hours.from_now
    end
  end
end

# Fulfilment fixtures — REQ-BE-00022.
# One Shipment per state for any available CargoOffer rows. Idempotent.
if defined?(CargoOffer) && defined?(Shipment) && CargoOffer.exists?
  Shipment::STATUSES.each_with_index do |state, i|
    cargo_offer = CargoOffer.offset(i).first or next
    next if Shipment.with_discarded.exists?(cargo_offer_id: cargo_offer.id)

    attrs = { cargo_offer: cargo_offer, status: state }
    case state
    when "accepted"
      attrs[:accepted_at] = 2.hours.ago
    when "in_transit"
      attrs[:accepted_at] = 4.hours.ago
      attrs[:picked_up_at] = 1.hour.ago
    when "delivered"
      attrs[:accepted_at] = 1.day.ago
      attrs[:picked_up_at] = 4.hours.ago
      attrs[:delivered_at] = 30.minutes.ago
    when "cancelled"
      attrs[:accepted_at] = 2.hours.ago
      attrs[:cancelled_at] = 30.minutes.ago
    end

    Shipment.create!(attrs)
  end
end
