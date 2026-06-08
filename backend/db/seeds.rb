# frozen_string_literal: true

#
# Truckr — curated demo seed (lean). Rebuilt 2026-06-03 for the Sprint 4 demo.
#
# One clean, deterministic slot per demoable feature. Idempotent: re-running
# (db:seed) never duplicates. Runs on `main` AND on the INF-FE-00005
# notifications worktree — notifications are best-effort *live* delivery with no
# table to seed (trigger them on stage via POST /api/dev/notifications/ping).
#
# Credentials (all password "Password123"):
#   carrier1@truckr.test   Carrier One   — the carrier you drive the demo as
#   shipper1@truckr.test   Shipper One   — primary shipper
#   shipper2@truckr.test   Shipper Two   — second shipper (review variety)
# Admin (ActiveAdmin): admin@example.com / "password"
#
# Demo map ── see docs/features/SPRINT-4-PLAN.md
#   Geo matching (US48/49/50) ... shipper1 open cargo "… (demo matching)" → GEO001 window
#   Offers received           ... shipper1 open cargo "… (demo oferta)" has a pending offer
#   US18 start_transit        ... carrier1 shipment that is accepted + escrowed
#   US19 deliver              ... carrier1 shipment that is in_transit
#   US20 create carrier review... shipper1 delivered shipment "… (REVIEW-ME)" (no review yet)
#   US30 create shipper review... carrier1 same delivered shipment (no review yet)
#   US26 view carrier reviews ... carrier1 public profile (4 reviews + avg)
#   US54 view shipper reviews ... shipper1 public profile (3 reviews)
#   US32 vehicle soft-delete  ... carrier1 vehicles:
#                                   GEO001 → blocked (active window)
#                                   OFR002 → blocked (pending offer)
#                                   FLT003 → blocked (active shipment)
#                                   FRE004 / FRE005 → discardable (happy path)
#                                   RET006 → already discarded (hidden from list)

# ── Admin ───────────────────────────────────────────────────────────────────
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

AdminUser.find_or_create_by!(email: admin_email) do |u|
  u.password              = admin_password
  u.password_confirmation = admin_password
end

# ── Coordinates (lat, lng) — DECIMAL(9,6), Haversine in app code (no PostGIS) ─
caba    = [ -34.603722, -58.381592 ]
cordoba = [ -31.420083, -64.188776 ]
rosario = [ -32.946820, -60.639317 ]
mendoza = [ -32.889458, -68.844734 ]
laplata = [ -34.921450, -57.954529 ]
mdq     = [ -38.005477, -57.542611 ]

# ── Identity ────────────────────────────────────────────────────────────────
make_user = lambda do |email, full_name, phone|
  user = User.find_or_create_by!(email: email) do |u|
    u.password  = "Password123"
    u.full_name = full_name
    u.phone     = phone
  end
  user.update!(phone: phone) if user.phone.blank?
  user
end

carrier1_user = make_user.call("carrier1@truckr.test", "Carrier One", "+54 11 5555-1111")
shipper1_user = make_user.call("shipper1@truckr.test", "Shipper One", "+54 11 5555-2222")
shipper2_user = make_user.call("shipper2@truckr.test", "Shipper Two", "+54 11 5555-3333")

carrier1 = Carrier.find_or_create_by!(user: carrier1_user) do |c|
  c.legal_name = "Carrier One Transport SRL"
  c.tax_id     = "30700000011"
  c.base_city  = "Buenos Aires"
  c.province   = "CABA"
end

shipper1 = Shipper.find_or_create_by!(user: shipper1_user) do |s|
  s.company_name = "Shipper One S.A."
  s.tax_id       = "20700000022"
end

shipper2 = Shipper.find_or_create_by!(user: shipper2_user) do |s|
  s.company_name = "Shipper Two S.R.L."
  s.tax_id       = "20700000033"
end

# ── carrier1 fleet — one vehicle per US32 outcome ────────────────────────────
make_vehicle = lambda do |carrier, plate, type, max_load|
  Vehicle.find_or_create_by!(carrier: carrier, plate: plate) do |v|
    v.make         = "Mercedes-Benz"
    v.model        = "Actros"
    v.max_load_kg  = max_load
    v.vehicle_type = type
  end
end

v_geo   = make_vehicle.call(carrier1, "GEO001", "truck_large", 12_000.0) # active window  → guard 1
v_offer = make_vehicle.call(carrier1, "OFR002", "van",          3_500.0) # pending offer  → guard 2
v_fleet = make_vehicle.call(carrier1, "FLT003", "truck_large", 12_000.0) # live shipments → guard 3
make_vehicle.call(carrier1, "FRE004", "van",          3_500.0)           # discardable
make_vehicle.call(carrier1, "FRE005", "truck_small",  6_000.0)           # discardable
v_gone = make_vehicle.call(carrier1, "RET006", "truck_small", 6_000.0)   # already discarded
v_gone.update!(discarded_at: 30.days.ago) if v_gone.discarded_at.nil?

# ── Geo matching (US48/49/50) ────────────────────────────────────────────────
# Active window with origin/destination pins + pickup radius. No offer on it, so
# it surfaces in the matches view for the cargo below.
TransportWindow.find_or_create_by!(
  vehicle: v_geo, origin_locality: "CABA", destination_locality: "Córdoba"
) do |w|
  w.origin_address         = "Puerto de Buenos Aires, CABA"
  w.origin_admin_area      = "Ciudad Autónoma de Buenos Aires"
  w.origin_lat             = caba[0]
  w.origin_lng             = caba[1]
  w.destination_address    = "Av. Sabattini 5500, Córdoba"
  w.destination_admin_area = "Córdoba"
  w.destination_lat        = cordoba[0]
  w.destination_lng        = cordoba[1]
  w.price_per_km           = 1_500.0
  w.max_km                 = 1_200
  w.available_from         = 1.day.from_now
  w.available_to           = 20.days.from_now
  w.active                 = true
  w.pickup_radius_km       = 60
  w.dropoff_radius_km      = 60
end

# Shipper's open cargo whose pickup pin sits inside the window's pickup radius
# and whose pickup window overlaps the window's availability → exactly one match.
Cargo.find_or_create_by!(
  shipper: shipper1, cargo_description: "Pallets de granos (demo matching)"
) do |c|
  c.pickup_address       = "Puerto de Buenos Aires"
  c.pickup_locality      = "CABA"
  c.pickup_admin_area    = "Ciudad Autónoma de Buenos Aires"
  c.pickup_lat           = caba[0]
  c.pickup_lng           = caba[1]
  c.delivery_address     = "Av. Sabattini 5500, Córdoba"
  c.delivery_locality    = "Córdoba"
  c.delivery_admin_area  = "Córdoba"
  c.delivery_lat         = cordoba[0]
  c.delivery_lng         = cordoba[1]
  c.pickup_window_start  = 3.days.from_now
  c.pickup_window_end    = 15.days.from_now
  c.weight_kg            = 4_000.0
  c.volume_cm3           = 22_000_000
  c.declared_value_cents = 150_000_000
end

# ── Offers received + US32 guard 2 ───────────────────────────────────────────
# Inactive window on v_offer carrying a pending bid from carrier1 on shipper1's
# open cargo. Shipper sees a received offer; the vehicle is blocked from discard
# by the pending commitment (not by an active window).
offer_win = TransportWindow.find_or_create_by!(
  vehicle: v_offer, origin_locality: "Rosario", destination_locality: "Mendoza"
) do |w|
  w.origin_address         = "Av. Pellegrini 1500, Rosario"
  w.origin_admin_area      = "Santa Fe"
  w.origin_lat             = rosario[0]
  w.origin_lng             = rosario[1]
  w.destination_address    = "Av. San Martín 1100, Mendoza"
  w.destination_admin_area = "Mendoza"
  w.destination_lat        = mendoza[0]
  w.destination_lng        = mendoza[1]
  w.price_per_km           = 1_700.0
  w.max_km                 = 900
  w.available_from         = 2.days.from_now
  w.available_to           = 18.days.from_now
  w.active                 = false
  w.pickup_radius_km       = 80
  w.dropoff_radius_km      = 80
end

offer_cargo = Cargo.find_or_create_by!(
  shipper: shipper1, cargo_description: "Materiales de construcción (demo oferta recibida)"
) do |c|
  c.pickup_address       = "Av. Pellegrini 1500, Rosario"
  c.pickup_locality      = "Rosario"
  c.pickup_admin_area    = "Santa Fe"
  c.pickup_lat           = rosario[0]
  c.pickup_lng           = rosario[1]
  c.delivery_address     = "Av. San Martín 1100, Mendoza"
  c.delivery_locality    = "Mendoza"
  c.delivery_admin_area  = "Mendoza"
  c.delivery_lat         = mendoza[0]
  c.delivery_lng         = mendoza[1]
  c.pickup_window_start  = 3.days.from_now
  c.pickup_window_end    = 16.days.from_now
  c.weight_kg            = 3_000.0
  c.volume_cm3           = 14_000_000
  c.declared_value_cents = 90_000_000
end

CargoOffer.find_or_create_by!(cargo: offer_cargo, carrier: carrier1, transport_window: offer_win) do |co|
  co.amount_cents = 9_500_000
  co.currency     = "ARS"
  co.status       = "pending"
  co.expires_at   = 24.hours.from_now
end

# ── Fulfilment history + live lifecycle slots ────────────────────────────────
# Each shipment gets a dedicated inactive window + cargo + accepted offer on the
# fleet vehicle (v_fleet). Windows are inactive past ranges so they never clash
# with marketplace search or the no-overlap guard. Escrow precedes any status
# advance so the escrowed-payment invariant always holds. transition_to! emits
# the status_change TrackingEvents that the US39 detail timeline renders.
#
# routes: distinct city pairs keep each window's find_or_create key unique.
routes = [
  [ "Buenos Aires",  caba,    "Rosario",       rosario ],
  [ "Córdoba",       cordoba, "Mendoza",       mendoza ],
  [ "Rosario",       rosario, "Buenos Aires",  caba    ],
  [ "Mendoza",       mendoza, "Córdoba",       cordoba ],
  [ "La Plata",      laplata, "Mar del Plata", mdq     ],
  [ "Córdoba",       cordoba, "La Plata",      laplata ],
  [ "Mar del Plata", mdq,     "Rosario",       rosario ],
  [ "Buenos Aires",  caba,    "La Plata",      laplata ]
]

build_shipment = lambda do |label:, shipper:, idx:, mode:, goods:|
  o_loc, o_pin, d_loc, d_pin = routes[idx]
  base = 45 - idx # distinct positive day anchor; higher idx = more recent

  win_from = (base + 20).days.ago
  win_to   = (base + 10).days.ago

  tw = TransportWindow.find_or_create_by!(
    vehicle: v_fleet, origin_locality: "#{o_loc} (#{label})", destination_locality: "#{d_loc} (#{label})"
  ) do |w|
    w.origin_address         = "Depósito #{o_loc}"
    w.origin_admin_area      = o_loc
    w.origin_lat             = o_pin[0]
    w.origin_lng             = o_pin[1]
    w.destination_address    = "Centro de distribución #{d_loc}"
    w.destination_admin_area = d_loc
    w.destination_lat        = d_pin[0]
    w.destination_lng        = d_pin[1]
    w.price_per_km           = 1_400.0
    w.max_km                 = 1_100
    w.available_from         = win_from
    w.available_to           = win_to
    w.active                 = false
    w.pickup_radius_km       = 50
    w.dropoff_radius_km      = 50
  end

  cargo = Cargo.find_or_create_by!(
    shipper: shipper, cargo_description: "#{goods} (#{label})"
  ) do |c|
    c.pickup_address       = "Depósito #{o_loc}"
    c.pickup_locality      = o_loc
    c.pickup_admin_area    = o_loc
    c.pickup_lat           = o_pin[0]
    c.pickup_lng           = o_pin[1]
    c.delivery_address     = "Centro de distribución #{d_loc}"
    c.delivery_locality    = d_loc
    c.delivery_admin_area  = d_loc
    c.delivery_lat         = d_pin[0]
    c.delivery_lng         = d_pin[1]
    c.pickup_window_start  = win_from
    c.pickup_window_end    = win_to
    c.weight_kg            = 4_000.0
    c.volume_cm3           = 20_000_000
    c.declared_value_cents = 80_000_000
  end

  offer = CargoOffer.find_or_create_by!(cargo: cargo, carrier: carrier1, transport_window: tw) do |co|
    co.amount_cents = 12_000_000
    co.currency     = "ARS"
    co.status       = "accepted"
    co.accepted_at  = (base + 15).days.ago
    co.expires_at   = (base + 9).days.ago
  end

  shipment = Shipment.with_discarded.find_by(cargo_offer_id: offer.id) ||
             Shipment.create!(cargo_offer: offer, status: "accepted", accepted_at: (base + 15).days.ago)

  # accepted_unpaid slots intentionally have no Payment row — they are the
  # precondition for the shipper-payment E2E test (Pagar CTA visible).
  unless mode == :accepted_unpaid
    Payment.find_or_create_by!(shipment: shipment) do |p|
      p.amount_cents = offer.amount_cents
      p.currency     = offer.currency
      p.provider     = "fake"
      p.state        = "escrowed"
      p.escrowed_at  = (base + 8).days.ago
    end
  end

  if %i[in_transit delivered].include?(mode) && shipment.status == "accepted"
    shipment.transition_to!(:in_transit, at: (base + 5).days.ago)
  end
  if mode == :delivered && shipment.status == "in_transit"
    shipment.transition_to!(:delivered, at: (base + 2).days.ago)
  end

  shipment
end

add_review = lambda do |shipment, author, rating, body|
  return if Review.exists?(shipment: shipment, authored_by: author)

  Review.create!(
    shipment:    shipment,
    carrier:     shipment.cargo_offer.carrier,
    shipper:     shipment.cargo_offer.cargo.shipper,
    rating:      rating,
    body:        body,
    authored_by: author
  )
end

# Four delivered + fully reviewed shipments — populate the public review lists
# and rating averages (US26 carrier profile, US54 shipper profile).
history = [
  { label: "H1", shipper: shipper1, goods: "Electrodomésticos",     idx: 0, s_rate: 5, c_rate: 5 },
  { label: "H2", shipper: shipper1, goods: "Insumos agropecuarios", idx: 1, s_rate: 4, c_rate: 5 },
  { label: "H3", shipper: shipper1, goods: "Mobiliario de oficina", idx: 2, s_rate: 5, c_rate: 4 },
  { label: "H4", shipper: shipper2, goods: "Bebidas embotelladas",  idx: 3, s_rate: 4, c_rate: 5 }
]

history.each do |h|
  s = build_shipment.call(label: h[:label], shipper: h[:shipper], idx: h[:idx], mode: :delivered, goods: h[:goods])
  add_review.call(s, :shipper_authored, h[:s_rate], "Entrega puntual y carga en perfecto estado.")
  add_review.call(s, :carrier_authored, h[:c_rate], "Documentación lista y horarios respetados.")
end

# Delivered, NOT yet reviewed — leave both directions open so the carrier review
# (US20, shipper → carrier) and shipper review (US30, carrier → shipper) can be
# created live on stage from the same shipment.
build_shipment.call(label: "REVIEW-ME", shipper: shipper1, idx: 4, mode: :delivered, goods: "Maquinaria liviana")

# Accepted + escrowed → carrier can start_transit live (US18).
build_shipment.call(label: "START-ME", shipper: shipper1, idx: 5, mode: :accepted_escrowed, goods: "Repuestos automotrices")

# In transit → carrier can confirm delivery live (US19).
build_shipment.call(label: "DELIVER-ME", shipper: shipper2, idx: 6, mode: :in_transit, goods: "Productos refrigerados")

# Accepted, no payment → Pagar CTA visible in ShipperShipmentsPage for E2E (US8).
# Seeded on shipper1 so shipper-payment.spec.ts can click it without extra login.
build_shipment.call(label: "PAY-ME", shipper: shipper1, idx: 7, mode: :accepted_unpaid, goods: "Insumos médicos")

# ── Summary ──────────────────────────────────────────────────────────────────
puts <<~SUMMARY
  ── Truckr demo seed ─────────────────────────────────────────────
  Users      : #{User.count} (carriers #{Carrier.count}, shippers #{Shipper.count})
  Vehicles   : #{Vehicle.with_discarded.count} (#{Vehicle.count} active, #{Vehicle.discarded.count} discarded)
  Cargos     : #{Cargo.count}   CargoOffers: #{CargoOffer.count}
  Shipments  : #{Shipment.count} (#{Shipment.where(status: 'accepted').count} accepted, #{Shipment.where(status: 'in_transit').count} in_transit, #{Shipment.where(status: 'delivered').count} delivered)
  Payments   : #{Payment.count}   Reviews: #{Review.count}
  Logins     : carrier1@ / shipper1@ / shipper2@truckr.test  (Password123)
  Admin      : #{admin_email}
  ─────────────────────────────────────────────────────────────────
SUMMARY
