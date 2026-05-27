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
      vehicle: vehicle, origin_province: "Buenos Aires", destination_province: "Córdoba"
    ) do |w|
      w.price_per_km   = 1500.0
      w.max_km         = 1200
      w.available_from = 1.day.from_now
      w.available_to   = 9.days.from_now
      w.active         = true
    end

    tw2 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_province: "Rosario", destination_province: "Mendoza"
    ) do |w|
      w.price_per_km   = 1700.0
      w.max_km         = 900
      w.available_from = 11.days.from_now
      w.available_to   = 19.days.from_now
      w.active         = true
    end

    tw3 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_province: "La Plata", destination_province: "Mar del Plata"
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

# Fulfilment fixtures — one shipment per FSM state.
#
# Each combination gets its own dedicated TransportWindow + Cargo + CargoOffer
# so the carrier and shipper list screens have representative data for every
# chip variant. Windows use past date ranges and active: false so they don't
# appear in marketplace search and don't trigger the no_vehicle_overlap guard
# (which only checks active windows). Idempotent.
#
# FSM (ADR-012):
#   accepted → pending_payment → in_transit → delivered
#   cancelled is terminal from any non-terminal state
FULFILMENT_COMBOS = [
  { status: "accepted",
    tw_from: -70, tw_to: -62, origin: "Santa Fe",   dest: "Tucumán",
    cargo_desc: "Equipos industriales" },
  { status: "pending_payment",
    tw_from: -61, tw_to: -53, origin: "Entre Ríos", dest: "Salta",
    cargo_desc: "Insumos médicos" },
  { status: "in_transit",
    tw_from: -52, tw_to: -44, origin: "Corrientes", dest: "Jujuy",
    cargo_desc: "Maquinaria agrícola" },
  { status: "delivered",
    tw_from: -43, tw_to: -35, origin: "Misiones",   dest: "Catamarca",
    cargo_desc: "Autopartes" },
  { status: "cancelled",
    tw_from: -34, tw_to: -26, origin: "Chaco",      dest: "La Rioja",
    cargo_desc: "Bebidas y licores" }
].freeze

if defined?(Carrier) && defined?(Shipper) && defined?(Vehicle) &&
   Carrier.any? && Shipper.any?

  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  if vehicle
    FULFILMENT_COMBOS.each do |fx|
      tw = TransportWindow.find_or_create_by!(
        vehicle: vehicle,
        origin_province:      fx[:origin],
        destination_province: fx[:dest]
      ) do |w|
        w.price_per_km   = 1_500.0
        w.max_km         = 1_200
        w.available_from = fx[:tw_from].days.from_now
        w.available_to   = fx[:tw_to].days.from_now
        w.active         = false
        w.status         = "reserved"
      end

      cargo = Cargo.find_or_create_by!(
        shipper: shipper, cargo_description: fx[:cargo_desc]
      ) do |c|
        c.pickup_address       = "Av. Principal 100, #{fx[:origin]}"
        c.delivery_address     = "Av. Central 200, #{fx[:dest]}"
        c.pickup_zone          = fx[:origin]
        c.delivery_zone        = fx[:dest]
        c.pickup_window_start  = (fx[:tw_from] - 2).days.from_now
        c.pickup_window_end    = (fx[:tw_to]   + 2).days.from_now
        c.weight_kg            = 2_500.0
        c.volume_cm3           = 15_000_000
        c.declared_value_cents = 50_000_000
      end

      offer = CargoOffer.find_or_create_by!(
        cargo: cargo, carrier: carrier, transport_window: tw
      ) do |co|
        co.amount_cents = 12_000_000
        co.currency     = "ARS"
        co.status       = "accepted"
        co.accepted_at  = (fx[:tw_from].abs + 5).days.ago
        co.expires_at   = (fx[:tw_from].abs - 2).days.ago
      end

      next if Shipment.with_discarded.exists?(cargo_offer_id: offer.id)

      attrs = { cargo_offer: offer, status: fx[:status] }
      offset = fx[:tw_from].abs
      case fx[:status]
      when "accepted"
        attrs[:accepted_at]         = (offset + 4).days.ago
      when "pending_payment"
        attrs[:accepted_at]         = (offset + 6).days.ago
        attrs[:payment_received_at] = (offset + 4).days.ago
      when "in_transit"
        attrs[:accepted_at]         = (offset + 8).days.ago
        attrs[:payment_received_at] = (offset + 6).days.ago
        attrs[:picked_up_at]        = (offset + 4).days.ago
      when "delivered"
        attrs[:accepted_at]         = (offset + 10).days.ago
        attrs[:payment_received_at] = (offset + 8).days.ago
        attrs[:picked_up_at]        = (offset + 6).days.ago
        attrs[:delivered_at]        = (offset + 2).days.ago
      when "cancelled"
        attrs[:accepted_at]  = (offset + 4).days.ago
        attrs[:cancelled_at] = (offset + 2).days.ago
      end

      Shipment.create!(attrs)
    end
  end
end
