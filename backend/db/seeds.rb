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
# FSM (ADR-012, amended 2026-05-30):
#   accepted → in_transit → delivered
#   cancelled is terminal from accepted or in_transit
# Payment escrow accompanies in_transit / delivered states (US8 — REQ-BE-00033).
# accepted + escrowed payment means carrier can start_transit (see US39 fixture B).
FULFILMENT_COMBOS = [
  { status: "accepted",
    tw_from: -70, tw_to: -62,
    origin: "Santa Fe", origin_admin: "Santa Fe",
    dest: "Tucumán", dest_admin: "Tucumán",
    origin_lat: -31.633333, origin_lng: -60.700000,
    dest_lat:   -26.808285, dest_lng:   -65.217590,
    cargo_desc: "Equipos industriales" },
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

      # All shipments start in accepted; payment + status updates applied after
      # so that the escrowed-payment invariant is never violated on create.
      attrs = { cargo_offer: offer, status: "accepted" }
      offset = fx[:tw_from].abs
      case fx[:status]
      when "accepted"
        attrs[:accepted_at] = (offset + 4).days.ago
      when "in_transit"
        attrs[:accepted_at] = (offset + 8).days.ago
      when "delivered"
        attrs[:accepted_at] = (offset + 10).days.ago
      when "cancelled"
        attrs[:accepted_at] = (offset + 4).days.ago
      end

      shipment = Shipment.create!(attrs)

      # Payment escrow row for in_transit / delivered; must exist before
      # advancing status (model validates escrowed payment for those states).
      if %w[in_transit delivered].include?(fx[:status])
        Payment.find_or_create_by!(shipment: shipment) do |p|
          p.amount_cents = offer.amount_cents
          p.currency     = offer.currency
          p.provider     = "fake"
          p.state        = "escrowed"
          p.escrowed_at  = (offset + 6).days.ago
        end

        shipment.update!(picked_up_at: (offset + 4).days.ago, status: "in_transit")

        if fx[:status] == "delivered"
          shipment.update!(delivered_at: (offset + 2).days.ago, status: "delivered")
        end
      end

      if fx[:status] == "cancelled"
        shipment.update!(cancelled_at: (offset + 2).days.ago, status: "cancelled")
      end
    end
  end
end

# US39 ShipmentDetailPage fixtures (REQ-FE-00024) ─────────────────────────────
#
# Two additions:
#   A. Tracking events for each FULFILMENT_COMBOS shipment so the
#      TrackingEventTimeline component has data to render (TC-07 → TC-12).
#   B. One "accepted + escrowed" Shipment — the only seeded combo where
#      AvailableActions emits "start_transit" for the Carrier (TC-04/05/06).
#      State stays `accepted` after payment (ADR-012 amendment 2026-05-30).
#   C. A second carrier/shipper pair for unauthorized-access tests (TC-14).
#
# Event lifecycle specification (authoritative reference for REQ-BE-00038)
# ─────────────────────────────────────────────────────────────────────────
# Every state-mutating action on a Shipment or its Payment must append a
# TrackingEvent so the detail-page timeline gives a complete audit trail.
#
# Trigger                                 Kind emitted          Notes
# ──────────────────────────────────────  ────────────────────  ─────────────
# Shipper accepts a CargoOffer            shipment_accepted     Initial creation
# Shipper pays (payment reaches escrow)   payment_escrowed      Payment service
# Payment attempt fails                   payment_failed        Payment service
# Carrier calls start_transit             shipment_in_transit   FSM: accepted→in_transit
# Carrier calls deliver                   shipment_delivered    FSM: in_transit→delivered
# Any party cancels                       shipment_cancelled    FSM: *→cancelled
# GPS location ping                       gps_update            POST /api/trips/:id/locations
# Staff note                              note                  ActiveAdmin
#
# Current state: REQ-BE-00038 is not yet implemented. Events below are seeded
# manually. status_change (from/to_status) is used for FSM transitions until
# REQ-BE-00038 activates the dedicated kinds above. The TrackingEventTimeline
# component includes a status_change adapter that will be removed once
# REQ-BE-00038 lands and all shipments carry dedicated-kind events.
if defined?(Carrier) && defined?(Shipper) && Carrier.any? && Shipper.any?
  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  # A. Tracking events ────────────────────────────────────────────────────────
  # Complete event history for each FULFILMENT_COMBOS shipment.
  # Timestamps follow the same offset formula used to create the shipments:
  #   offset = tw_from.abs
  #   shipment_accepted  = (offset + N).days.ago  (matches accepted_at)
  #   payment_escrowed   = (offset + 6).days.ago  (matches Payment#escrowed_at)
  #   accepted→in_transit= (offset + 4).days.ago  (matches picked_up_at)
  #   in_transit→delivered=(offset + 2).days.ago  (matches delivered_at)
  #   *→cancelled        = (offset + 2).days.ago  (matches cancelled_at)
  #
  # Idempotency: lifecycle kinds (shipment_accepted, payment_escrowed) are
  # unique per shipment; status_change is unique per from→to pair.
  [
    {
      desc: "Equipos industriales",  # accepted, offset=70, accepted_at=74.days.ago
      events: [
        { kind: "shipment_accepted", days_ago: 74 }
      ]
    },
    {
      desc: "Maquinaria agrícola",   # in_transit, offset=52, accepted_at=60.days.ago
      events: [
        { kind: "shipment_accepted",                                 days_ago: 60 },
        { kind: "payment_escrowed",                                  days_ago: 58 },
        { kind: "status_change", from: "accepted", to: "in_transit", days_ago: 56 }
      ]
    },
    {
      desc: "Autopartes",            # delivered, offset=43, accepted_at=53.days.ago
      events: [
        { kind: "shipment_accepted",                                    days_ago: 53 },
        { kind: "payment_escrowed",                                     days_ago: 49 },
        { kind: "status_change", from: "accepted",   to: "in_transit", days_ago: 47 },
        { kind: "status_change", from: "in_transit", to: "delivered",  days_ago: 45 }
      ]
    },
    {
      desc: "Bebidas y licores",     # cancelled, offset=34, accepted_at=38.days.ago
      events: [
        { kind: "shipment_accepted",                                  days_ago: 38 },
        { kind: "status_change", from: "accepted", to: "cancelled",  days_ago: 36 }
      ]
    }
  ].each do |fx|
    cargo    = Cargo.find_by(cargo_description: fx[:desc])
    next unless cargo
    offer    = CargoOffer.find_by(cargo: cargo)
    next unless offer
    shipment = Shipment.with_discarded.find_by(cargo_offer_id: offer.id)
    next unless shipment

    fx[:events].each do |ev|
      exists =
        if ev[:kind] == "status_change"
          shipment.tracking_events.where(kind: "status_change",
                                         from_status: ev[:from],
                                         to_status:   ev[:to]).exists?
        else
          shipment.tracking_events.where(kind: ev[:kind]).exists?
        end
      next if exists

      attrs = { kind: ev[:kind], recorded_at: ev[:days_ago].days.ago }
      attrs[:from_status] = ev[:from] if ev.key?(:from)
      attrs[:to_status]   = ev[:to]   if ev.key?(:to)
      shipment.tracking_events.create!(attrs)
    end
  end

  # B. Accepted + escrowed fixture (TC-04/05/06) ─────────────────────────────
  # Represents a shipment where payment is escrowed but carrier hasn't started
  # transit yet. AvailableActions emits "start_transit" for this carrier.
  # State stays `accepted` after payment — the escrowed Payment row signals
  # that the carrier can proceed (ADR-012 amendment 2026-05-30).
  if vehicle
    tw_us39 = TransportWindow.find_or_create_by!(
      vehicle: vehicle, origin_locality: "San Luis", destination_locality: "Bahía Blanca"
    ) do |w|
      w.origin_address         = "Av. Illia 750, San Luis"
      w.origin_admin_area      = "San Luis"
      w.destination_address    = "Av. Alem 600, Bahía Blanca"
      w.destination_admin_area = "Buenos Aires"
      w.price_per_km           = 1_600.0
      w.max_km                 = 900
      w.available_from         = 200.days.ago
      w.available_to           = 192.days.ago
      w.active                 = false
      w.status                 = "reserved"
      w.origin_lat             = -33.295553
      w.origin_lng             = -66.335030
      w.destination_lat        = -38.716671
      w.destination_lng        = -62.270833
      w.pickup_radius_km       = 50
      w.dropoff_radius_km      = 50
    end

    cargo_us39 = Cargo.find_or_create_by!(
      shipper: shipper, cargo_description: "Encomiendas urgentes"
    ) do |c|
      c.pickup_address       = "Av. Illia 750, San Luis"
      c.pickup_locality      = "San Luis"
      c.pickup_admin_area    = "San Luis"
      c.delivery_address     = "Av. Alem 600, Bahía Blanca"
      c.delivery_locality    = "Bahía Blanca"
      c.delivery_admin_area  = "Buenos Aires"
      c.pickup_lat           = -33.295553
      c.pickup_lng           = -66.335030
      c.delivery_lat         = -38.716671
      c.delivery_lng         = -62.270833
      c.pickup_window_start  = 198.days.ago
      c.pickup_window_end    = 194.days.ago
      c.weight_kg            = 1_200.0
      c.volume_cm3           = 5_000_000
      c.declared_value_cents = 25_000_000
    end

    offer_us39 = CargoOffer.find_or_create_by!(
      cargo: cargo_us39, carrier: carrier, transport_window: tw_us39
    ) do |co|
      co.amount_cents = 9_500_000
      co.currency     = "ARS"
      co.status       = "accepted"
      co.accepted_at  = 196.days.ago
      co.expires_at   = 201.days.ago
    end

    unless Shipment.with_discarded.exists?(cargo_offer_id: offer_us39.id)
      shipment_us39 = Shipment.create!(
        cargo_offer: offer_us39,
        status:      "accepted",
        accepted_at: 195.days.ago
      )
      Payment.create!(
        shipment:     shipment_us39,
        amount_cents: offer_us39.amount_cents,
        currency:     offer_us39.currency,
        provider:     "fake",
        state:        "escrowed",
        escrowed_at:  194.days.ago
      )
    end

    # Tracking events for the accepted+escrowed shipment (TC-04/05/06).
    if (ship_us39 = Shipment.with_discarded.find_by(cargo_offer_id: offer_us39.id))
      ship_us39.tracking_events.find_or_create_by!(kind: "shipment_accepted") do |te|
        te.recorded_at = 195.days.ago
      end
      ship_us39.tracking_events.find_or_create_by!(kind: "payment_escrowed") do |te|
        te.recorded_at = 194.days.ago
      end
    end
  end

  # C. Second carrier/shipper pair for unauthorized-access test (TC-14) ──────
  carrier2_user = User.find_or_create_by!(email: "carrier2@truckr.test") do |u|
    u.password  = "Password123"
    u.full_name = "Carrier Two"
    u.phone     = "+54 11 5555-3333"
  end
  carrier2_user.update!(phone: "+54 11 5555-3333") if carrier2_user.phone.blank?

  shipper2_user = User.find_or_create_by!(email: "shipper2@truckr.test") do |u|
    u.password  = "Password123"
    u.full_name = "Shipper Two"
    u.phone     = "+54 11 5555-4444"
  end
  shipper2_user.update!(phone: "+54 11 5555-4444") if shipper2_user.phone.blank?

  carrier2 = Carrier.find_or_create_by!(user: carrier2_user) do |c|
    c.legal_name = "Carrier Two Express SRL"
    c.tax_id     = "30#{format('%08d', carrier2_user.id)}9"
    c.base_city  = "Córdoba"
    c.province   = "Córdoba"
  end

  Vehicle.find_or_create_by!(carrier: carrier2) do |v|
    v.plate        = "ZZ#{format('%03d', carrier2_user.id)}YY"
    v.make         = "Iveco"
    v.model        = "Stralis"
    v.max_load_kg  = 7_000.0
    v.vehicle_type = "truck_small"
  end

  Shipper.find_or_create_by!(user: shipper2_user) do |s|
    s.company_name = "Shipper Two Logística S.A."
    s.tax_id       = "20#{format('%08d', shipper2_user.id)}3"
  end
end

# Soft-delete test fixtures (US32) — one vehicle per discard scenario so
# every full-stack test case can be run without creating any data manually.
# Idempotent. All windows use past date ranges with active: false so they
# don't appear in marketplace search and don't trigger the overlap guard
# (which only checks active windows on the same vehicle).
#
# Plate map (carrier1@truckr.test):
#   AA001XX — Case 2 : has active marketplace windows      → discard blocked
#   BB002XX — Case 3 : pending CargoOffer                  → discard blocked
#   CC003XX — Case 4 : Shipment in in_transit              → discard blocked
#   DD004XX — Cases 1/11/12: clean, no commitments         → discard allowed
#   EE005XX — Case 5 : offer expired, no live shipment     → discard allowed
#   FF006XX — Case 6 : accepted offer + delivered Shipment → discard allowed
#   GG007XX — Cases 7/9/10 : already discarded + history   → admin / history
if defined?(Carrier) && defined?(Shipper) && defined?(Vehicle) &&
   Carrier.any? && Shipper.any?

  carrier = Carrier.first
  shipper = Shipper.first

  # ── BB002XX ── pending CargoOffer blocks discard ─────────────────────────
  v_bb = Vehicle.find_or_create_by!(plate: "BB002XX", carrier: carrier) do |v|
    v.make         = "Toyota"
    v.model        = "Hilux"
    v.max_load_kg  = 5_000.0
    v.vehicle_type = "truck_small"
  end

  tw_bb = TransportWindow.find_or_create_by!(
    vehicle: v_bb, origin_locality: "Resistencia", destination_locality: "Formosa"
  ) do |w|
    w.origin_address       = "Ruta 16 km 1, Resistencia"
    w.origin_admin_area    = "Chaco"
    w.origin_lat           = -27.4514
    w.origin_lng           = -58.9867
    w.destination_address  = "Av. 25 de Mayo 500, Formosa"
    w.destination_admin_area = "Formosa"
    w.destination_lat      = -26.1796
    w.destination_lng      = -58.1738
    w.pickup_radius_km     = 50
    w.dropoff_radius_km    = 50
    w.price_per_km         = 1_200.0
    w.max_km               = 400
    w.available_from       = 100.days.ago
    w.available_to         = 92.days.ago
    w.active               = false
  end

  cargo_bb = Cargo.find_or_create_by!(
    shipper: shipper, cargo_description: "Electrodomésticos (BB002XX)"
  ) do |c|
    c.pickup_address       = "Ruta 16 km 100, Resistencia"
    c.pickup_locality      = "Resistencia"
    c.pickup_admin_area    = "Chaco"
    c.pickup_lat           = -27.4514
    c.pickup_lng           = -58.9867
    c.delivery_address     = "Av. 25 de Mayo 500, Formosa"
    c.delivery_locality    = "Formosa"
    c.delivery_admin_area  = "Formosa"
    c.delivery_lat         = -26.1796
    c.delivery_lng         = -58.1738
    c.pickup_window_start  = 98.days.ago
    c.pickup_window_end    = 94.days.ago
    c.weight_kg            = 2_500.0
    c.volume_cm3           = 10_000_000
    c.declared_value_cents = 30_000_000
  end

  CargoOffer.find_or_create_by!(cargo: cargo_bb, carrier: carrier, transport_window: tw_bb) do |co|
    co.amount_cents = 8_000_000
    co.currency     = "ARS"
    co.status       = "pending"
    co.expires_at   = 24.hours.from_now
  end

  # ── CC003XX ── Shipment in in_transit blocks discard ─────────────────────
  v_cc = Vehicle.find_or_create_by!(plate: "CC003XX", carrier: carrier) do |v|
    v.make         = "Iveco"
    v.model        = "Daily"
    v.max_load_kg  = 5_000.0
    v.vehicle_type = "truck_small"
  end

  tw_cc = TransportWindow.find_or_create_by!(
    vehicle: v_cc, origin_locality: "San Juan", destination_locality: "La Rioja"
  ) do |w|
    w.origin_address       = "Av. Rawson 900, San Juan"
    w.origin_admin_area    = "San Juan"
    w.origin_lat           = -31.5388
    w.origin_lng           = -68.5306
    w.destination_address  = "Av. Mota Botello 200, La Rioja"
    w.destination_admin_area = "La Rioja"
    w.destination_lat      = -29.4118
    w.destination_lng      = -66.8558
    w.pickup_radius_km     = 50
    w.dropoff_radius_km    = 50
    w.price_per_km         = 1_300.0
    w.max_km               = 500
    w.available_from       = 90.days.ago
    w.available_to         = 82.days.ago
    w.active               = false
    w.status               = "reserved"
  end

  cargo_cc = Cargo.find_or_create_by!(
    shipper: shipper, cargo_description: "Maquinaria industrial (CC003XX)"
  ) do |c|
    c.pickup_address       = "Av. Rawson 900, San Juan"
    c.pickup_locality      = "San Juan"
    c.pickup_admin_area    = "San Juan"
    c.pickup_lat           = -31.5388
    c.pickup_lng           = -68.5306
    c.delivery_address     = "Av. Mota Botello 200, La Rioja"
    c.delivery_locality    = "La Rioja"
    c.delivery_admin_area  = "La Rioja"
    c.delivery_lat         = -29.4118
    c.delivery_lng         = -66.8558
    c.pickup_window_start  = 88.days.ago
    c.pickup_window_end    = 84.days.ago
    c.weight_kg            = 3_000.0
    c.volume_cm3           = 15_000_000
    c.declared_value_cents = 60_000_000
  end

  offer_cc = CargoOffer.find_or_create_by!(cargo: cargo_cc, carrier: carrier, transport_window: tw_cc) do |co|
    co.amount_cents = 10_000_000
    co.currency     = "ARS"
    co.status       = "accepted"
    co.accepted_at  = 86.days.ago
    co.expires_at   = 91.days.ago
  end

  unless Shipment.with_discarded.exists?(cargo_offer_id: offer_cc.id)
    ship_cc = Shipment.create!(cargo_offer: offer_cc, status: "accepted", accepted_at: 85.days.ago)
    Payment.create!(shipment: ship_cc, amount_cents: offer_cc.amount_cents, currency: offer_cc.currency,
                    provider: "fake", state: "escrowed", escrowed_at: 84.days.ago)
    ship_cc.update!(status: "in_transit", picked_up_at: 83.days.ago)
  end

  # ── DD004XX ── clean vehicle, no commitments (Cases 1 / 11 / 12) ─────────
  Vehicle.find_or_create_by!(plate: "DD004XX", carrier: carrier) do |v|
    v.make         = "Renault"
    v.model        = "Master"
    v.max_load_kg  = 5_000.0
    v.vehicle_type = "truck_small"
  end

  # ── EE005XX ── expired offer, no live shipment → discard allowed (Case 5) ─
  # The offer expired before the shipper accepted it; no Shipment was created.
  # Demonstrates that guard 2 treats expired as terminal (only pending blocks).
  v_ee = Vehicle.find_or_create_by!(plate: "EE005XX", carrier: carrier) do |v|
    v.make         = "Volkswagen"
    v.model        = "Delivery"
    v.max_load_kg  = 5_000.0
    v.vehicle_type = "truck_small"
  end

  tw_ee = TransportWindow.find_or_create_by!(
    vehicle: v_ee, origin_locality: "Neuquén", destination_locality: "Viedma"
  ) do |w|
    w.origin_address       = "Av. Argentina 100, Neuquén"
    w.origin_admin_area    = "Neuquén"
    w.origin_lat           = -38.9517
    w.origin_lng           = -68.0591
    w.destination_address  = "Av. Julio Roca 300, Viedma"
    w.destination_admin_area = "Río Negro"
    w.destination_lat      = -40.8090
    w.destination_lng      = -62.9980
    w.pickup_radius_km     = 50
    w.dropoff_radius_km    = 50
    w.price_per_km         = 1_100.0
    w.max_km               = 300
    w.available_from       = 80.days.ago
    w.available_to         = 72.days.ago
    w.active               = false
  end

  cargo_ee = Cargo.find_or_create_by!(
    shipper: shipper, cargo_description: "Frutas de temporada (EE005XX)"
  ) do |c|
    c.pickup_address       = "Av. Argentina 100, Neuquén"
    c.pickup_locality      = "Neuquén"
    c.pickup_admin_area    = "Neuquén"
    c.pickup_lat           = -38.9517
    c.pickup_lng           = -68.0591
    c.delivery_address     = "Av. Julio Roca 300, Viedma"
    c.delivery_locality    = "Viedma"
    c.delivery_admin_area  = "Río Negro"
    c.delivery_lat         = -40.8090
    c.delivery_lng         = -62.9980
    c.pickup_window_start  = 78.days.ago
    c.pickup_window_end    = 74.days.ago
    c.weight_kg            = 2_000.0
    c.volume_cm3           = 8_000_000
    c.declared_value_cents = 20_000_000
  end

  CargoOffer.find_or_create_by!(cargo: cargo_ee, carrier: carrier, transport_window: tw_ee) do |co|
    co.amount_cents = 6_000_000
    co.currency     = "ARS"
    co.status       = "expired"
    co.expires_at   = 75.days.ago
  end

  # ── FF006XX ── accepted offer + delivered Shipment → discard allowed (Case 6)
  # Demonstrates guard 2: only "pending" offers block discard; "accepted" is
  # fine because the outcome is governed by the Shipment state (guard 3), and
  # "delivered" is terminal.
  v_ff = Vehicle.find_or_create_by!(plate: "FF006XX", carrier: carrier) do |v|
    v.make         = "Ford"
    v.model        = "Cargo 1723"
    v.max_load_kg  = 5_000.0
    v.vehicle_type = "truck_large"
  end

  tw_ff = TransportWindow.find_or_create_by!(
    vehicle: v_ff, origin_locality: "Córdoba", destination_locality: "Santa Fe"
  ) do |w|
    w.origin_address       = "Av. Colón 200, Córdoba"
    w.origin_admin_area    = "Córdoba"
    w.origin_lat           = -31.4201
    w.origin_lng           = -64.1888
    w.destination_address  = "Av. Hipólito Irigoyen 400, Santa Fe"
    w.destination_admin_area = "Santa Fe"
    w.destination_lat      = -31.6333
    w.destination_lng      = -60.7000
    w.pickup_radius_km     = 50
    w.dropoff_radius_km    = 50
    w.price_per_km         = 1_400.0
    w.max_km               = 700
    w.available_from       = 70.days.ago
    w.available_to         = 62.days.ago
    w.active               = false
    w.status               = "reserved"
  end

  cargo_ff = Cargo.find_or_create_by!(
    shipper: shipper, cargo_description: "Autopartes (FF006XX)"
  ) do |c|
    c.pickup_address       = "Av. Colón 200, Córdoba"
    c.pickup_locality      = "Córdoba"
    c.pickup_admin_area    = "Córdoba"
    c.pickup_lat           = -31.4201
    c.pickup_lng           = -64.1888
    c.delivery_address     = "Av. Hipólito Irigoyen 400, Santa Fe"
    c.delivery_locality    = "Santa Fe"
    c.delivery_admin_area  = "Santa Fe"
    c.delivery_lat         = -31.6333
    c.delivery_lng         = -60.7000
    c.pickup_window_start  = 68.days.ago
    c.pickup_window_end    = 64.days.ago
    c.weight_kg            = 3_500.0
    c.volume_cm3           = 12_000_000
    c.declared_value_cents = 80_000_000
  end

  offer_ff = CargoOffer.find_or_create_by!(cargo: cargo_ff, carrier: carrier, transport_window: tw_ff) do |co|
    co.amount_cents = 14_000_000
    co.currency     = "ARS"
    co.status       = "accepted"
    co.accepted_at  = 66.days.ago
    co.expires_at   = 71.days.ago
  end

  unless Shipment.with_discarded.exists?(cargo_offer_id: offer_ff.id)
    ship_ff = Shipment.create!(cargo_offer: offer_ff, status: "accepted", accepted_at: 65.days.ago)
    Payment.create!(shipment: ship_ff, amount_cents: offer_ff.amount_cents, currency: offer_ff.currency,
                    provider: "fake", state: "escrowed", escrowed_at: 64.days.ago)
    ship_ff.update!(status: "in_transit", picked_up_at: 63.days.ago)
    ship_ff.update!(status: "delivered",  delivered_at: 60.days.ago)
  end

  # ── GG007XX ── already discarded (Cases 7 / 9 / 10) ─────────────────────
  # Vehicle that carried a completed Shipment and was later soft-deleted.
  # Its TransportWindow still resolves it via
  #   belongs_to :vehicle, -> { unscope(where: :discarded_at) }
  # Visible in ActiveAdmin (with_discarded) but absent from carrier's fleet UI.
  v_gg = Vehicle.with_discarded.find_or_initialize_by(plate: "GG007XX", carrier: carrier)
  unless v_gg.persisted?
    v_gg.assign_attributes(
      make:         "Mercedes-Benz",
      model:        "Sprinter 515",
      max_load_kg:  5_000.0,
      vehicle_type: "truck_small"
    )
    v_gg.save!
  end

  tw_gg = TransportWindow.find_or_create_by!(
    vehicle: v_gg, origin_locality: "Buenos Aires", destination_locality: "Posadas"
  ) do |w|
    w.origin_address       = "Puerto Madero, Buenos Aires"
    w.origin_admin_area    = "Ciudad Autónoma de Buenos Aires"
    w.origin_lat           = -34.6037
    w.origin_lng           = -58.3816
    w.destination_address  = "Av. San Martín 100, Posadas"
    w.destination_admin_area = "Misiones"
    w.destination_lat      = -27.3672
    w.destination_lng      = -55.8969
    w.pickup_radius_km     = 50
    w.dropoff_radius_km    = 50
    w.price_per_km         = 1_800.0
    w.max_km               = 1_500
    w.available_from       = 60.days.ago
    w.available_to         = 52.days.ago
    w.active               = false
    w.status               = "reserved"
  end

  cargo_gg = Cargo.find_or_create_by!(
    shipper: shipper, cargo_description: "Yerba mate (GG007XX)"
  ) do |c|
    c.pickup_address       = "Puerto Madero, Buenos Aires"
    c.pickup_locality      = "Buenos Aires"
    c.pickup_admin_area    = "Ciudad Autónoma de Buenos Aires"
    c.pickup_lat           = -34.6037
    c.pickup_lng           = -58.3816
    c.delivery_address     = "Av. San Martín 100, Posadas"
    c.delivery_locality    = "Posadas"
    c.delivery_admin_area  = "Misiones"
    c.delivery_lat         = -27.3672
    c.delivery_lng         = -55.8969
    c.pickup_window_start  = 58.days.ago
    c.pickup_window_end    = 54.days.ago
    c.weight_kg            = 4_000.0
    c.volume_cm3           = 20_000_000
    c.declared_value_cents = 100_000_000
  end

  offer_gg = CargoOffer.find_or_create_by!(cargo: cargo_gg, carrier: carrier, transport_window: tw_gg) do |co|
    co.amount_cents = 20_000_000
    co.currency     = "ARS"
    co.status       = "accepted"
    co.accepted_at  = 56.days.ago
    co.expires_at   = 61.days.ago
  end

  unless Shipment.with_discarded.exists?(cargo_offer_id: offer_gg.id)
    ship_gg = Shipment.create!(cargo_offer: offer_gg, status: "accepted", accepted_at: 55.days.ago)
    Payment.create!(shipment: ship_gg, amount_cents: offer_gg.amount_cents, currency: offer_gg.currency,
                    provider: "fake", state: "escrowed", escrowed_at: 54.days.ago)
    ship_gg.update!(status: "in_transit", picked_up_at: 53.days.ago)
    ship_gg.update!(status: "delivered",  delivered_at: 50.days.ago)
  end

  v_gg.update!(discarded_at: 30.days.ago) if v_gg.discarded_at.nil?

  # Tracking events for soft-delete fixture shipments that have had FSM
  # transitions. Complete histories following the same lifecycle spec above.
  [
    { cargo_desc: "Maquinaria industrial (CC003XX)",  # in_transit
      events: [
        { kind: "shipment_accepted",                                 days_ago: 85 },
        { kind: "payment_escrowed",                                  days_ago: 84 },
        { kind: "status_change", from: "accepted", to: "in_transit", days_ago: 83 }
      ]
    },
    { cargo_desc: "Autopartes (FF006XX)",             # delivered
      events: [
        { kind: "shipment_accepted",                                    days_ago: 65 },
        { kind: "payment_escrowed",                                     days_ago: 64 },
        { kind: "status_change", from: "accepted",   to: "in_transit", days_ago: 63 },
        { kind: "status_change", from: "in_transit", to: "delivered",  days_ago: 60 }
      ]
    },
    { cargo_desc: "Yerba mate (GG007XX)",             # delivered
      events: [
        { kind: "shipment_accepted",                                    days_ago: 55 },
        { kind: "payment_escrowed",                                     days_ago: 54 },
        { kind: "status_change", from: "accepted",   to: "in_transit", days_ago: 53 },
        { kind: "status_change", from: "in_transit", to: "delivered",  days_ago: 50 }
      ]
    }
  ].each do |fx|
    cargo    = Cargo.find_by(cargo_description: fx[:cargo_desc])
    next unless cargo
    offer    = CargoOffer.find_by(cargo: cargo)
    next unless offer
    shipment = Shipment.with_discarded.find_by(cargo_offer_id: offer.id)
    next unless shipment

    fx[:events].each do |ev|
      exists =
        if ev[:kind] == "status_change"
          shipment.tracking_events.where(kind: "status_change",
                                         from_status: ev[:from],
                                         to_status:   ev[:to]).exists?
        else
          shipment.tracking_events.where(kind: ev[:kind]).exists?
        end
      next if exists

      attrs = { kind: ev[:kind], recorded_at: ev[:days_ago].days.ago }
      attrs[:from_status] = ev[:from] if ev.key?(:from)
      attrs[:to_status]   = ev[:to]   if ev.key?(:to)
      shipment.tracking_events.create!(attrs)
    end
  end
end

# US30 review fixtures (REQ-BE-00044) ─────────────────────────────────────────
#
# Three dedicated delivered shipments for full-stack manual testing.  All use
# carrier1@truckr.test / shipper1@truckr.test and the main vehicle (AA001XX).
# Windows are past + active: false so they stay off the marketplace search.
#
#   Seed A — "Aceite de girasol (US30 — sin reseña)"
#             Clean: no review yet.  Use for TC1 (happy-path submit), TC2
#             (AC7 reload), TC6 (shipper view), TC7 (rating validation).
#             NOTE: TC1 is destructive — it creates a review.  Re-seed with
#             db:reset to restore a clean state for TC1/TC7.
#
#   Seed B — "Granos de maíz (US30 — sin reseña 2)"
#             Second clean shipment.  Use for TC8 (rating-only, no comment).
#
#   Seed C — "Harina de trigo (US30 — con reseña)"
#             Has a carrier-authored review pre-seeded (rating 4).
#             Use for TC3 (AC7 hydration: form renders read-only on first load).
if defined?(Carrier) && defined?(Shipper) && Carrier.any? && Shipper.any?
  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  if vehicle
    US30_FIXTURES = [
      { seed: :a,
        cargo_desc:   "Aceite de girasol (US30 — sin reseña)",
        tw_from: -18, tw_to: -10,
        origin: "Villa María",  origin_admin: "Córdoba",
        dest:   "San Rafael",   dest_admin:   "Mendoza",
        origin_lat:  -32.409710, origin_lng: -63.238628,
        dest_lat:    -34.617500, dest_lng:   -68.330000,
        review: nil },
      { seed: :b,
        cargo_desc:   "Granos de maíz (US30 — sin reseña 2)",
        tw_from: -25, tw_to: -17,
        origin: "Concordia",     origin_admin: "Entre Ríos",
        dest:   "Gualeguaychú", dest_admin:   "Entre Ríos",
        origin_lat:  -31.392320, origin_lng: -58.024180,
        dest_lat:    -33.007080, dest_lng:   -58.520910,
        review: nil },
      { seed: :c,
        cargo_desc:   "Harina de trigo (US30 — con reseña)",
        tw_from: -32, tw_to: -24,
        origin: "Río Cuarto",   origin_admin: "Córdoba",
        dest:   "General Roca", dest_admin:   "Río Negro",
        origin_lat:  -33.113380, origin_lng: -64.349960,
        dest_lat:    -39.028280, dest_lng:   -67.588010,
        review: { rating: 4, body: "Carga lista a horario, embalaje impecable." } }
    ].freeze

    US30_FIXTURES.each do |fx|
      tw = TransportWindow.find_or_create_by!(
        vehicle:              vehicle,
        origin_locality:      fx[:origin],
        destination_locality: fx[:dest]
      ) do |w|
        w.origin_address         = "Av. Principal 100, #{fx[:origin]}"
        w.origin_admin_area      = fx[:origin_admin]
        w.destination_address    = "Av. Central 200, #{fx[:dest]}"
        w.destination_admin_area = fx[:dest_admin]
        w.price_per_km           = 1_500.0
        w.max_km                 = 1_000
        w.available_from         = fx[:tw_from].days.from_now
        w.available_to           = fx[:tw_to].days.from_now
        w.active                 = false
        w.status                 = "reserved"
        w.origin_lat             = fx[:origin_lat]
        w.origin_lng             = fx[:origin_lng]
        w.destination_lat        = fx[:dest_lat]
        w.destination_lng        = fx[:dest_lng]
        w.pickup_radius_km       = 50
        w.dropoff_radius_km      = 50
      end

      cargo = Cargo.find_or_create_by!(
        shipper:           shipper,
        cargo_description: fx[:cargo_desc]
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
        c.volume_cm3           = 10_000_000
        c.declared_value_cents = 40_000_000
      end

      offer = CargoOffer.find_or_create_by!(
        cargo: cargo, carrier: carrier, transport_window: tw
      ) do |co|
        co.amount_cents = 11_000_000
        co.currency     = "ARS"
        co.status       = "accepted"
        co.accepted_at  = (fx[:tw_from].abs + 5).days.ago
        co.expires_at   = (fx[:tw_from].abs - 2).days.ago
      end

      next if Shipment.with_discarded.exists?(cargo_offer_id: offer.id)

      offset   = fx[:tw_from].abs
      shipment = Shipment.create!(
        cargo_offer: offer,
        status:      "accepted",
        accepted_at: (offset + 10).days.ago
      )

      Payment.find_or_create_by!(shipment: shipment) do |p|
        p.amount_cents = offer.amount_cents
        p.currency     = offer.currency
        p.provider     = "fake"
        p.state        = "escrowed"
        p.escrowed_at  = (offset + 8).days.ago
      end

      shipment.update!(picked_up_at: (offset + 6).days.ago, status: "in_transit")
      shipment.update!(delivered_at: (offset + 4).days.ago, status: "delivered")

      [
        { kind: "shipment_accepted",                                    days_ago: offset + 10 },
        { kind: "payment_escrowed",                                     days_ago: offset + 8  },
        { kind: "status_change", from: "accepted",   to: "in_transit", days_ago: offset + 6  },
        { kind: "status_change", from: "in_transit", to: "delivered",  days_ago: offset + 4  }
      ].each do |ev|
        exists = if ev[:kind] == "status_change"
          shipment.tracking_events.where(
            kind: "status_change",
            from_status: ev[:from], to_status: ev[:to]
          ).exists?
        else
          shipment.tracking_events.where(kind: ev[:kind]).exists?
        end
        next if exists
        attrs = { kind: ev[:kind], recorded_at: ev[:days_ago].days.ago }
        attrs[:from_status] = ev[:from] if ev.key?(:from)
        attrs[:to_status]   = ev[:to]   if ev.key?(:to)
        shipment.tracking_events.create!(attrs)
      end

      next unless fx[:review]
      next if Review.carrier_authored.exists?(shipment: shipment)

      Review.create!(
        shipment:    shipment,
        carrier:     carrier,
        shipper:     shipper,
        rating:      fx[:review][:rating],
        body:        fx[:review][:body],
        authored_by: :carrier_authored
      )
    end
  end
end

# US26 — shipper-authored reviews on carrier #1 (REQ-BE-00043).
# Thirteen delivered shipments so GET /api/carriers/1/reviews paginates (10 + 3).
# Review 13 (idx 12, oldest) has body: nil — covers the body-less card TC.
# Idempotent: keyed by cargo_description; skips when count is already ≥ 13.
if defined?(Review) && defined?(Carrier) && Carrier.exists?(id: 1) &&
   defined?(Shipper) && Shipper.any?
  us26_carrier = Carrier.find(1)
  us26_shipper = Shipper.first
  us26_vehicle = us26_carrier.vehicles.first

  if us26_vehicle && us26_shipper
    US26_TARGET_REVIEWS = 13 unless defined?(US26_TARGET_REVIEWS)
    US26_REVIEW_BODIES = [
      "Entrega puntual y comunicación clara durante todo el viaje.",
      "Cuidó la carga en rutas difíciles; volvería a contratar.",
      "Buen trato y documentación en orden al retirar.",
      "Llegó dentro de la ventana acordada, sin sorpresas.",
      "Vehículo en buen estado y chofer muy profesional.",
      "Resolvió un desvío por clima sin demoras innecesarias.",
      "Excelente seguimiento; siempre supimos dónde estaba el camión.",
      "Embalaje respetado y descarga sin inconvenientes.",
      "Precio acorde al servicio; experiencia recomendable.",
      "Primera vez con este transportista y quedamos conformes.",
      "Cumplió con el peso y volumen pactados sin reclamos.",
      "Muy atento a los horarios de carga en planta.",
      nil  # TC-06: body-less review — verifies card renders without body paragraph
    ].freeze unless defined?(US26_REVIEW_BODIES)

    us26_existing = Review.shipper_authored.where(carrier_id: us26_carrier.id).count
    us26_needed   = US26_TARGET_REVIEWS - us26_existing
    if us26_needed.positive?
      us26_needed.times do |idx|
        idx += us26_existing
        n = idx + 1
        rating = [ 3, 4, 4, 5, 5, 4, 5, 5, 4, 5, 4, 5, 5 ][idx]
        days_ago = idx + 1
        fx = {
          cargo_desc: "US26 — reseña expedidor #{n} (carrier ##{us26_carrier.id})",
          tw_from:  -(40 + idx),
          tw_to:    -(32 + idx),
          origin:   "La Plata",
          origin_admin: "Buenos Aires",
          dest:     "Mar del Plata",
          dest_admin: "Buenos Aires",
          origin_lat:  -34.921450,
          origin_lng:  -57.954530,
          dest_lat:    -38.005477,
          dest_lng:    -57.542610,
          rating: rating,
          body: US26_REVIEW_BODIES[idx],
          days_ago: days_ago
        }

        tw = TransportWindow.find_or_create_by!(
          vehicle:              us26_vehicle,
          origin_locality:      "#{fx[:origin]} #{n}",
          destination_locality: "#{fx[:dest]} #{n}"
        ) do |w|
          w.origin_address         = "Calle #{n} 100, #{fx[:origin]}"
          w.origin_admin_area      = fx[:origin_admin]
          w.destination_address    = "Calle #{n} 200, #{fx[:dest]}"
          w.destination_admin_area = fx[:dest_admin]
          w.price_per_km           = 1_400.0
          w.max_km                 = 800
          w.available_from         = fx[:tw_from].days.from_now
          w.available_to           = fx[:tw_to].days.from_now
          w.active                 = false
          w.status                 = "reserved"
          w.origin_lat             = fx[:origin_lat]
          w.origin_lng             = fx[:origin_lng]
          w.destination_lat        = fx[:dest_lat]
          w.destination_lng        = fx[:dest_lng]
          w.pickup_radius_km       = 40
          w.dropoff_radius_km      = 40
        end

        cargo = Cargo.find_or_create_by!(
          shipper:           us26_shipper,
          cargo_description: fx[:cargo_desc]
        ) do |c|
          c.pickup_address       = "Calle #{n} 100, #{fx[:origin]}"
          c.pickup_locality      = fx[:origin]
          c.pickup_admin_area    = fx[:origin_admin]
          c.delivery_address     = "Calle #{n} 200, #{fx[:dest]}"
          c.delivery_locality    = fx[:dest]
          c.delivery_admin_area  = fx[:dest_admin]
          c.pickup_lat           = fx[:origin_lat]
          c.pickup_lng           = fx[:origin_lng]
          c.delivery_lat         = fx[:dest_lat]
          c.delivery_lng         = fx[:dest_lng]
          c.pickup_window_start  = (fx[:tw_from] - 2).days.from_now
          c.pickup_window_end    = (fx[:tw_to]   + 2).days.from_now
          c.weight_kg            = 1_800.0
          c.volume_cm3           = 8_000_000
          c.declared_value_cents = 25_000_000
        end

        offer = CargoOffer.find_or_create_by!(
          cargo: cargo, carrier: us26_carrier, transport_window: tw
        ) do |co|
          co.amount_cents = 9_500_000
          co.currency     = "ARS"
          co.status       = "accepted"
          co.accepted_at  = (fx[:tw_from].abs + 5).days.ago
          co.expires_at   = (fx[:tw_from].abs - 2).days.ago
        end

        shipment = Shipment.with_discarded.find_by(cargo_offer_id: offer.id)
        unless shipment
          offset = fx[:tw_from].abs
          shipment = Shipment.create!(
            cargo_offer: offer,
            status:      "accepted",
            accepted_at: (offset + 10).days.ago
          )

          Payment.find_or_create_by!(shipment: shipment) do |p|
            p.amount_cents = offer.amount_cents
            p.currency     = offer.currency
            p.provider     = "fake"
            p.state        = "escrowed"
            p.escrowed_at  = (offset + 8).days.ago
          end

          shipment.update!(picked_up_at: (offset + 6).days.ago, status: "in_transit")
          shipment.update!(delivered_at: (offset + 4).days.ago, status: "delivered")
        end

        next if Review.shipper_authored.exists?(shipment: shipment)

        Review.create!(
          shipment:    shipment,
          carrier:     us26_carrier,
          shipper:     us26_shipper,
          rating:      fx[:rating],
          body:        fx[:body],
          authored_by: :shipper_authored,
          created_at:  fx[:days_ago].days.ago,
          updated_at:  fx[:days_ago].days.ago
        )
      end
    end
  end
end

# US54 review fixtures (REQ-BE-00045) ─────────────────────────────────────────
#
# Ten additional carrier-authored reviews on shipper1@truckr.test, each tied to
# its own dedicated delivered shipment.  Together with the Seed-C review from
# the US30 block ("Carga lista a horario, embalaje impecable.", rating 4),
# shipper1 reaches 11 carrier-authored reviews — enough to span two pages
# (10/page, newest-first) and exercise the "Ver más reseñas" pagination button.
# shipper2@truckr.test stays review-free for the empty-state test case.
#
# Avg calculation: 4 + 5+5+5+4+4+4+3+3+2+1 = 40 / 11 = 3.636… → "3.6"
#
# Page layout (newest-first):
#   Page 1 (10): US30-C review (created at seed time, newest) + reseñas 1–9
#   Page 2 (1):  reseña 10 (rating 1, 300 days ago, oldest)
#
# TC mapping:
#   TC-03 — shipper2 profile: empty state, stars empty
#   TC-04 — shipper1 profile: hero shows avg "3.6", count 11
#   TC-05 — individual review cards: rating, date, body visible
#   TC-06 — newest-first: US30-C ("Carga lista a horario…") appears first
#   TC-11 — "Ver más reseñas" button visible (page 1 of 2)
#   TC-12 — clicking "Ver más" loads the single page-2 card (rating 1)
if defined?(Carrier) && defined?(Shipper) && Carrier.any? && Shipper.any?
  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  if vehicle
    US54_REVIEW_FIXTURES = [
      { cargo_desc:      "Semillas de soja (US54 — reseña 1)",
        tw_from: -310, tw_to: -302,
        origin: "Mendoza",      origin_admin: "Mendoza",
        dest:   "Tucumán",      dest_admin:   "Tucumán",
        origin_lat:  -32.889458, origin_lng: -68.844734,
        dest_lat:    -26.808285, dest_lng:   -65.217590,
        rating: 5,
        body:   "Carga perfectamente embalada y lista antes del horario acordado.",
        review_age_days: 30 },

      { cargo_desc:      "Aceitunas en conserva (US54 — reseña 2)",
        tw_from: -318, tw_to: -310,
        origin: "Salta",        origin_admin: "Salta",
        dest:   "Jujuy",        dest_admin:   "Jujuy",
        origin_lat:  -24.782693, origin_lng: -65.423169,
        dest_lat:    -24.184832, dest_lng:   -65.302181,
        rating: 5,
        body:   "Excelente coordinación. El cliente estaba esperando en destino.",
        review_age_days: 60 },

      { cargo_desc:      "Productos lácteos (US54 — reseña 3)",
        tw_from: -326, tw_to: -318,
        origin: "Santa Rosa",   origin_admin: "La Pampa",
        dest:   "Neuquén",      dest_admin:   "Neuquén",
        origin_lat:  -36.617693, origin_lng: -64.283386,
        dest_lat:    -38.951751, dest_lng:   -68.059138,
        rating: 5,
        body:   nil,
        review_age_days: 90 },

      { cargo_desc:      "Hierro en lingotes (US54 — reseña 4)",
        tw_from: -334, tw_to: -326,
        origin: "Bahía Blanca", origin_admin: "Buenos Aires",
        dest:   "Paraná",       dest_admin:   "Entre Ríos",
        origin_lat:  -38.716671, origin_lng: -62.270833,
        dest_lat:    -31.731389, dest_lng:   -60.523056,
        rating: 4,
        body:   "Buena predisposición del expedidor para coordinar horarios.",
        review_age_days: 120 },

      { cargo_desc:      "Vidrio templado (US54 — reseña 5)",
        tw_from: -342, tw_to: -334,
        origin: "San Juan",     origin_admin: "San Juan",
        dest:   "Córdoba",      dest_admin:   "Córdoba",
        origin_lat:  -31.538870, origin_lng: -68.530554,
        dest_lat:    -31.420083, dest_lng:   -64.188776,
        rating: 4,
        body:   "Todo en orden. Documentación completa al momento del retiro.",
        review_age_days: 150 },

      { cargo_desc:      "Muebles de madera (US54 — reseña 6)",
        tw_from: -350, tw_to: -342,
        origin: "Paraná",       origin_admin: "Entre Ríos",
        dest:   "Bahía Blanca", dest_admin:   "Buenos Aires",
        origin_lat:  -31.731389, origin_lng: -60.523056,
        dest_lat:    -38.716671, dest_lng:   -62.270833,
        rating: 4,
        body:   nil,
        review_age_days: 180 },

      { cargo_desc:      "Fertilizantes a granel (US54 — reseña 7)",
        tw_from: -358, tw_to: -350,
        origin: "Formosa",      origin_admin: "Formosa",
        dest:   "Chaco",        dest_admin:   "Chaco",
        origin_lat:  -26.179613, origin_lng: -58.173744,
        dest_lat:    -27.451100, dest_lng:   -58.986622,
        rating: 3,
        body:   "La carga llegó bien pero el despacho se demoró una hora.",
        review_age_days: 210 },

      { cargo_desc:      "Mineral de cobre (US54 — reseña 8)",
        tw_from: -366, tw_to: -358,
        origin: "La Rioja",     origin_admin: "La Rioja",
        dest:   "Catamarca",    dest_admin:   "Catamarca",
        origin_lat:  -29.411778, origin_lng: -66.855750,
        dest_lat:    -28.468611, dest_lng:   -65.779167,
        rating: 3,
        body:   "Aceptable. Algunas cajas sin precinto. A mejorar.",
        review_age_days: 240 },

      { cargo_desc:      "Resinas plásticas (US54 — reseña 9)",
        tw_from: -374, tw_to: -366,
        origin: "Neuquén",      origin_admin: "Neuquén",
        dest:   "Santa Cruz",   dest_admin:   "Santa Cruz",
        origin_lat:  -38.951751, origin_lng: -68.059138,
        dest_lat:    -51.622222, dest_lng:   -69.218056,
        rating: 2,
        body:   "Problemas con el etiquetado. Tuvimos demoras en destino.",
        review_age_days: 270 },

      { cargo_desc:      "Madera de pino (US54 — reseña 10)",
        tw_from: -382, tw_to: -374,
        origin: "Oberá",        origin_admin: "Misiones",
        dest:   "Buenos Aires", dest_admin:   "Ciudad Autónoma de Buenos Aires",
        origin_lat:  -27.484139, origin_lng: -55.122917,
        dest_lat:    -34.603722, dest_lng:   -58.381592,
        rating: 1,
        body:   "Carga incompleta al momento del retiro. No se cumplió con lo acordado.",
        review_age_days: 300 }
    ].freeze

    US54_REVIEW_FIXTURES.each do |fx|
      tw = TransportWindow.find_or_create_by!(
        vehicle:              vehicle,
        origin_locality:      fx[:origin],
        destination_locality: fx[:dest]
      ) do |w|
        w.origin_address         = "Av. Principal 100, #{fx[:origin]}"
        w.origin_admin_area      = fx[:origin_admin]
        w.destination_address    = "Av. Central 200, #{fx[:dest]}"
        w.destination_admin_area = fx[:dest_admin]
        w.price_per_km           = 1_500.0
        w.max_km                 = 1_000
        w.available_from         = fx[:tw_from].days.from_now
        w.available_to           = fx[:tw_to].days.from_now
        w.active                 = false
        w.status                 = "reserved"
        w.origin_lat             = fx[:origin_lat]
        w.origin_lng             = fx[:origin_lng]
        w.destination_lat        = fx[:dest_lat]
        w.destination_lng        = fx[:dest_lng]
        w.pickup_radius_km       = 50
        w.dropoff_radius_km      = 50
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
        c.weight_kg            = 2_000.0
        c.volume_cm3           = 8_000_000
        c.declared_value_cents = 30_000_000
      end

      offer = CargoOffer.find_or_create_by!(
        cargo: cargo, carrier: carrier, transport_window: tw
      ) do |co|
        co.amount_cents = 10_000_000
        co.currency     = "ARS"
        co.status       = "accepted"
        co.accepted_at  = (fx[:tw_from].abs + 5).days.ago
        co.expires_at   = (fx[:tw_from].abs - 2).days.ago
      end

      offset   = fx[:tw_from].abs
      shipment = if Shipment.with_discarded.exists?(cargo_offer_id: offer.id)
        Shipment.with_discarded.find_by!(cargo_offer_id: offer.id)
      else
        s = Shipment.create!(
          cargo_offer: offer,
          status:      "accepted",
          accepted_at: (offset + 10).days.ago
        )
        Payment.find_or_create_by!(shipment: s) do |p|
          p.amount_cents = offer.amount_cents
          p.currency     = offer.currency
          p.provider     = "fake"
          p.state        = "escrowed"
          p.escrowed_at  = (offset + 8).days.ago
        end
        s.update!(picked_up_at: (offset + 6).days.ago, status: "in_transit")
        s.update!(delivered_at: (offset + 4).days.ago, status: "delivered")
        s
      end

      [
        { kind: "shipment_accepted",                                    days_ago: offset + 10 },
        { kind: "payment_escrowed",                                     days_ago: offset + 8  },
        { kind: "status_change", from: "accepted",   to: "in_transit", days_ago: offset + 6  },
        { kind: "status_change", from: "in_transit", to: "delivered",  days_ago: offset + 4  }
      ].each do |ev|
        exists = if ev[:kind] == "status_change"
          shipment.tracking_events.where(
            kind: "status_change",
            from_status: ev[:from], to_status: ev[:to]
          ).exists?
        else
          shipment.tracking_events.where(kind: ev[:kind]).exists?
        end
        next if exists
        attrs = { kind: ev[:kind], recorded_at: ev[:days_ago].days.ago }
        attrs[:from_status] = ev[:from] if ev.key?(:from)
        attrs[:to_status]   = ev[:to]   if ev.key?(:to)
        shipment.tracking_events.create!(attrs)
      end

      next if Review.carrier_authored.exists?(shipment: shipment)

      Review.create!(
        shipment:    shipment,
        carrier:     carrier,
        shipper:     shipper,
        rating:      fx[:rating],
        body:        fx[:body],
        authored_by: :carrier_authored,
        created_at:  fx[:review_age_days].days.ago
      )
    end
  end
end

# US20 review fixtures (REQ-BE-00042) ─────────────────────────────────────────
#
# Three dedicated delivered shipments for full-stack manual testing of the
# Shipper → Carrier review flow.  All use carrier1 / shipper1 / AA001XX.
# Windows are past + active: false so they stay off marketplace search.
#
#   Seed D — "Trigo sarraceno (US20 — sin reseña)"
#             Clean: no review yet.
#             TC-01 (form visible), TC-05 (client validation), TC-06 (happy
#             path with comment — destructive), TC-08 (page reload after
#             submit). Re-seed with `just backend-reset` to restore TC-06/TC-08.
#
#   Seed E — "Cebada cervecera (US20 — sin reseña 2)"
#             Second clean shipment.
#             TC-07 (rating only, no comment — destructive).
#
#   Seed F — "Lino oleaginoso (US20 — con reseña)"
#             Has a shipper-authored review pre-seeded (rating 4, with body).
#             TC-09 (AC7 hydration: form renders read-only on first load).
#
if defined?(Carrier) && defined?(Shipper) && Carrier.any? && Shipper.any?
  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first

  if vehicle
    US20_FIXTURES = [
      { seed: :d,
        cargo_desc:   "Trigo sarraceno (US20 — sin reseña)",
        tw_from: -14, tw_to: -6,
        origin: "Tandil",         origin_admin: "Buenos Aires",
        dest:   "Azul",           dest_admin:   "Buenos Aires",
        origin_lat:  -37.321700,  origin_lng: -59.133200,
        dest_lat:    -36.775900,  dest_lng:   -59.858000,
        review: nil },
      { seed: :e,
        cargo_desc:   "Cebada cervecera (US20 — sin reseña 2)",
        tw_from: -21, tw_to: -13,
        origin: "Zárate",         origin_admin: "Buenos Aires",
        dest:   "Campana",        dest_admin:   "Buenos Aires",
        origin_lat:  -34.098800,  origin_lng: -59.030600,
        dest_lat:    -34.166700,  dest_lng:   -58.950000,
        review: nil },
      { seed: :f,
        cargo_desc:   "Lino oleaginoso (US20 — con reseña)",
        tw_from: -28, tw_to: -20,
        origin: "Necochea",       origin_admin: "Buenos Aires",
        dest:   "Tres Arroyos",   dest_admin:   "Buenos Aires",
        origin_lat:  -38.553900,  origin_lng: -58.737500,
        dest_lat:    -38.376500,  dest_lng:   -60.276300,
        review: { rating: 4, body: "Embalaje perfecto y carga lista antes del horario." } }
    ].freeze

    US20_FIXTURES.each do |fx|
      tw = TransportWindow.find_or_create_by!(
        vehicle:              vehicle,
        origin_locality:      fx[:origin],
        destination_locality: fx[:dest]
      ) do |w|
        w.origin_address         = "Av. Principal 100, #{fx[:origin]}"
        w.origin_admin_area      = fx[:origin_admin]
        w.destination_address    = "Av. Central 200, #{fx[:dest]}"
        w.destination_admin_area = fx[:dest_admin]
        w.price_per_km           = 1_500.0
        w.max_km                 = 1_000
        w.available_from         = fx[:tw_from].days.from_now
        w.available_to           = fx[:tw_to].days.from_now
        w.active                 = false
        w.status                 = "reserved"
        w.origin_lat             = fx[:origin_lat]
        w.origin_lng             = fx[:origin_lng]
        w.destination_lat        = fx[:dest_lat]
        w.destination_lng        = fx[:dest_lng]
        w.pickup_radius_km       = 50
        w.dropoff_radius_km      = 50
      end

      cargo = Cargo.find_or_create_by!(
        shipper:           shipper,
        cargo_description: fx[:cargo_desc]
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
        c.volume_cm3           = 10_000_000
        c.declared_value_cents = 40_000_000
      end

      offer = CargoOffer.find_or_create_by!(
        cargo: cargo, carrier: carrier, transport_window: tw
      ) do |co|
        co.amount_cents = 11_000_000
        co.currency     = "ARS"
        co.status       = "accepted"
        co.accepted_at  = (fx[:tw_from].abs + 5).days.ago
        co.expires_at   = (fx[:tw_from].abs - 2).days.ago
      end

      next if Shipment.with_discarded.exists?(cargo_offer_id: offer.id)

      offset   = fx[:tw_from].abs
      shipment = Shipment.create!(
        cargo_offer: offer,
        status:      "accepted",
        accepted_at: (offset + 10).days.ago
      )

      Payment.find_or_create_by!(shipment: shipment) do |p|
        p.amount_cents = offer.amount_cents
        p.currency     = offer.currency
        p.provider     = "fake"
        p.state        = "escrowed"
        p.escrowed_at  = (offset + 8).days.ago
      end

      shipment.update!(picked_up_at: (offset + 6).days.ago, status: "in_transit")
      shipment.update!(delivered_at: (offset + 4).days.ago, status: "delivered")

      [
        { kind: "shipment_accepted",                                    days_ago: offset + 10 },
        { kind: "payment_escrowed",                                     days_ago: offset + 8  },
        { kind: "status_change", from: "accepted",   to: "in_transit", days_ago: offset + 6  },
        { kind: "status_change", from: "in_transit", to: "delivered",  days_ago: offset + 4  }
      ].each do |ev|
        exists = if ev[:kind] == "status_change"
          shipment.tracking_events.where(
            kind: "status_change",
            from_status: ev[:from], to_status: ev[:to]
          ).exists?
        else
          shipment.tracking_events.where(kind: ev[:kind]).exists?
        end
        next if exists
        attrs = { kind: ev[:kind], recorded_at: ev[:days_ago].days.ago }
        attrs[:from_status] = ev[:from] if ev.key?(:from)
        attrs[:to_status]   = ev[:to]   if ev.key?(:to)
        shipment.tracking_events.create!(attrs)
      end

      next unless fx[:review]
      next if Review.shipper_authored.exists?(shipment: shipment)

      Review.create!(
        shipment:    shipment,
        carrier:     carrier,
        shipper:     shipper,
        rating:      fx[:review][:rating],
        body:        fx[:review][:body],
        authored_by: :shipper_authored
      )
    end
  end
end
