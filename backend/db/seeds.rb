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
  { email: "carrier1@truckr.test", full_name: "Carrier One", phone: "+54 11 5555-1111", role: :carrier },
  { email: "shipper1@truckr.test", full_name: "Shipper One", phone: "+54 11 5555-2222", role: :shipper }
]

identity_users.each do |spec|
  user = User.find_or_create_by!(email: spec[:email]) do |u|
    u.password  = "Password123"
    u.full_name = spec[:full_name]
    u.phone     = spec[:phone]
  end

  # Backfill phone for users that were seeded before the field was populated.
  user.update!(phone: spec[:phone]) if user.phone.blank?

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
# validations updated by REQ-BE-00032; address-driven location shape via
# REQ-BE-00039 / ADR-014). Seeds Cargo publications + CargoOffer bids consistent
# with every model rule: TransportWindows on a vehicle never overlap; a Cargo
# weighs within the vehicle's capacity; a CargoOffer's Cargo pickup window
# overlaps the target window; a window holds at most one pending/accepted offer
# (window-lock). cargo1 carries two parallel offers; cargo2 is left un-offered
# so its detail demos the matches view against the still-free tw3. Idempotent.
# Skips silently when the dependent Identity rows have not been seeded yet.
if defined?(Carrier) && defined?(Shipper) && defined?(Vehicle) &&
   Carrier.any? && Shipper.any? && Vehicle.any?

  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  if vehicle
    # Three non-overlapping windows on the same vehicle — TransportWindow
    # rejects overlapping active windows per vehicle.
    tw1 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_locality: "CABA", destination_locality: "Córdoba"
    ) do |w|
      w.origin_address       = "Puerto de Buenos Aires, CABA"
      w.origin_admin_area    = "Ciudad Autónoma de Buenos Aires"
      w.destination_address  = "Av. Sabattini 5500, Córdoba"
      w.destination_admin_area = "Córdoba"
      w.price_per_km    = 1500.0
      w.max_km          = 1200
      w.available_from  = 1.day.from_now
      w.available_to    = 9.days.from_now
      w.active          = true
      w.origin_lat       = -34.603722 # CABA
      w.origin_lng       = -58.381592
      w.destination_lat  = -31.420083 # Córdoba
      w.destination_lng  = -64.188776
      w.pickup_radius_km = 50
      w.dropoff_radius_km = 50
    end

    tw2 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_locality: "Rosario", destination_locality: "Mendoza"
    ) do |w|
      w.origin_address       = "Av. Pellegrini 1500, Rosario"
      w.origin_admin_area    = "Santa Fe"
      w.destination_address  = "Av. San Martín 1100, Mendoza"
      w.destination_admin_area = "Mendoza"
      w.price_per_km    = 1700.0
      w.max_km          = 900
      w.available_from  = 11.days.from_now
      w.available_to    = 19.days.from_now
      w.active          = true
      w.origin_lat       = -32.946820 # Rosario
      w.origin_lng       = -60.639317
      w.destination_lat  = -32.889458 # Mendoza
      w.destination_lng  = -68.844734
      w.pickup_radius_km = 80
      w.dropoff_radius_km = 80
    end

    tw3 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_locality: "La Plata", destination_locality: "Mar del Plata"
    ) do |w|
      w.origin_address       = "Av. 7 1200, La Plata"
      w.origin_admin_area    = "Buenos Aires"
      w.destination_address  = "Av. Luro 3500, Mar del Plata"
      w.destination_admin_area = "Buenos Aires"
      w.price_per_km    = 1400.0
      w.max_km          = 500
      w.available_from  = 21.days.from_now
      w.available_to    = 29.days.from_now
      w.active          = true
      w.origin_lat       = -34.921450 # La Plata
      w.origin_lng       = -57.954529
      w.destination_lat  = -38.005477 # Mar del Plata
      w.destination_lng  = -57.542611
      w.pickup_radius_km = 30
      w.dropoff_radius_km = 30
    end

    # Cargo weights stay within the seeded vehicle's 5 t capacity so the
    # CargoOffer capacity validation passes; pickup windows overlap the
    # windows their offers target.
    cargo1 = Cargo.find_or_create_by!(
      shipper: shipper, cargo_description: "Pallets de granos"
    ) do |c|
      c.pickup_address       = "Puerto de Buenos Aires"
      c.pickup_locality      = "CABA"
      c.pickup_admin_area    = "Ciudad Autónoma de Buenos Aires"
      c.delivery_address     = "Av. Sabattini 5500, Córdoba"
      c.delivery_locality    = "Córdoba"
      c.delivery_admin_area  = "Córdoba"
      c.pickup_lat           = -34.603722 # CABA
      c.pickup_lng           = -58.381592
      c.delivery_lat         = -31.420083 # Córdoba
      c.delivery_lng         = -64.188776
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
      c.pickup_locality      = "La Plata"
      c.pickup_admin_area    = "Buenos Aires"
      c.delivery_address     = "Av. Luro 3500, Mar del Plata"
      c.delivery_locality    = "Mar del Plata"
      c.delivery_admin_area  = "Buenos Aires"
      c.pickup_lat           = -34.921450 # La Plata
      c.pickup_lng           = -57.954529
      c.delivery_lat         = -38.005477 # Mar del Plata
      c.delivery_lng         = -57.542611
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

# Fulfilment fixtures — one shipment per FSM state, plus Payment rows for
# states that imply escrow.
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
# Payment escrow accompanies pending_payment / in_transit / delivered states
# (US8 — REQ-BE-00033).
FULFILMENT_COMBOS = [
  { status: "accepted",
    tw_from: -70, tw_to: -62,
    origin: "Santa Fe", origin_admin: "Santa Fe",
    dest: "Tucumán", dest_admin: "Tucumán",
    origin_lat: -31.633333, origin_lng: -60.700000,
    dest_lat:   -26.808285, dest_lng:   -65.217590,
    cargo_desc: "Equipos industriales" },
  { status: "pending_payment",
    tw_from: -61, tw_to: -53,
    origin: "Paraná", origin_admin: "Entre Ríos",
    dest: "Salta", dest_admin: "Salta",
    origin_lat: -31.732222, origin_lng: -60.528611,
    dest_lat:   -24.788195, dest_lng:   -65.410344,
    cargo_desc: "Insumos médicos" },
  { status: "in_transit",
    tw_from: -52, tw_to: -44,
    origin: "Corrientes", origin_admin: "Corrientes",
    dest: "Jujuy", dest_admin: "Jujuy",
    origin_lat: -27.469440, origin_lng: -58.830278,
    dest_lat:   -24.184832, dest_lng:   -65.302181,
    cargo_desc: "Maquinaria agrícola" },
  { status: "delivered",
    tw_from: -43, tw_to: -35,
    origin: "Posadas", origin_admin: "Misiones",
    dest: "San Fernando del Valle de Catamarca", dest_admin: "Catamarca",
    origin_lat: -27.367222, origin_lng: -55.896944,
    dest_lat:   -28.468611, dest_lng:   -65.779167,
    cargo_desc: "Autopartes" },
  { status: "cancelled",
    tw_from: -34, tw_to: -26,
    origin: "Resistencia", origin_admin: "Chaco",
    dest: "La Rioja", dest_admin: "La Rioja",
    origin_lat: -27.451100, origin_lng: -58.986622,
    dest_lat:   -29.411778, dest_lng:   -66.855750,
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
        origin_locality:      fx[:origin],
        destination_locality: fx[:dest]
      ) do |w|
        w.origin_address       = "Av. Principal 100, #{fx[:origin]}"
        w.origin_admin_area    = fx[:origin_admin]
        w.destination_address  = "Av. Central 200, #{fx[:dest]}"
        w.destination_admin_area = fx[:dest_admin]
        w.price_per_km    = 1_500.0
        w.max_km          = 1_200
        w.available_from  = fx[:tw_from].days.from_now
        w.available_to    = fx[:tw_to].days.from_now
        w.active          = false
        w.status          = "reserved"
        w.origin_lat      = fx[:origin_lat]
        w.origin_lng      = fx[:origin_lng]
        w.destination_lat = fx[:dest_lat]
        w.destination_lng = fx[:dest_lng]
        w.pickup_radius_km  = 50
        w.dropoff_radius_km = 50
      end

      cargo = Cargo.find_or_create_by!(
        shipper: shipper, cargo_description: fx[:cargo_desc]
      ) do |c|
        c.pickup_address       = "Av. Principal 100, #{fx[:origin]}"
        c.pickup_locality      = fx[:origin]
        c.pickup_admin_area    = fx[:origin_admin]
        c.delivery_address     = "Av. Central 200, #{fx[:dest]}"
        c.delivery_locality    = fx[:dest]
        c.delivery_admin_area  = fx[:dest_admin]
        c.pickup_lat           = fx[:origin_lat]
        c.pickup_lng           = fx[:origin_lng]
        c.delivery_lat         = fx[:dest_lat]
        c.delivery_lng         = fx[:dest_lng]
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

      shipment = Shipment.create!(attrs)

      # Payment escrow row for states that imply payment has been received
      # (US8 — REQ-BE-00033). Skipped for accepted (pre-payment) and
      # cancelled (no payment captured).
      if %w[pending_payment in_transit delivered].include?(fx[:status])
        Payment.find_or_create_by!(shipment: shipment) do |p|
          p.amount_cents = offer.amount_cents
          p.currency     = offer.currency
          p.provider     = "fake"
          p.state        = "escrowed"
          p.escrowed_at  = (offset + 1).days.ago
        end
      end
    end
  end
end
