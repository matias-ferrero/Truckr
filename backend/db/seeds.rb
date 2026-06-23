# frozen_string_literal: true

#
# Truckr — demo seed (clean-slate, curated). Rebuilt 2026-06-22 for the final demo.
#
# Four real personas, a believable marketplace history around them, and one
# clean slot per lifecycle state. Reference "today" is 2026-06-22; every date is
# expressed relative to Time.current so "vigente" stays in the future and
# "pasado" stays in the past whenever the seed is run.
#
# In non-production this seed is DESTRUCTIVE: it wipes every domain record
# (keeping only the ActiveAdmin AdminUser) and rebuilds from scratch, so the
# demo never accumulates stale rows across runs.
#
# Personas (all password "Password123"):
#   carrier  diego.sosa@truckr.test          Diego Sosa            transportista independiente (base Rosario)
#   carrier  operaciones@andinacargo.test    Andina Cargo S.A.     empresa de transporte con flota (base Mendoza)
#   shipper  contacto@granjalaesperanza.test Granja La Esperanza   expedidor agropecuario (granos/frutas)
#   shipper  laura.fernandez@truckr.test     Laura Fernández        expedidora particular (mudanza)
# Admin (ActiveAdmin): admin@example.com / "password"
#
# What the data covers:
#   · Cargas publicadas (open) — una con ventana vigente que matchea (US48/49/50).
#   · Ofertas recibidas (pending) — granja y particular tienen ofertas por aprobar.
#   · Oferta rechazada — alfalfa con oferta cara rechazada; mudanza de oficina con
#     una oferta rechazada y otra aceptada sobre la misma carga.
#   · Envíos vigentes — uno aceptado+escrow listo para iniciar, uno en tránsito,
#     uno aceptado sin pagar (CTA "Pagar").
#   · Envíos entregados (pasados) — seis, con pago en escrow, payout liquidado al
#     transportista y reseñas en ambas direcciones.
#   · Ventanas de transporte vigentes (active) y pasadas (inactive).

require "bigdecimal"

# ── Admin (preserved across the wipe) ────────────────────────────────────────
admin_email    = ENV["SEED_ADMIN_EMAIL"]
admin_password = ENV["SEED_ADMIN_PASSWORD"]

if Rails.env.production?
  if admin_email.blank? || admin_password.blank?
    abort("SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD must be set in production")
  end
else
  admin_email    = admin_email.presence    || "admin@example.com"
  admin_password = admin_password.presence  || "password"
end

AdminUser.find_or_create_by!(email: admin_email) do |u|
  u.password              = admin_password
  u.password_confirmation = admin_password
end

# Production stops here — never wipe or seed demo data on a live database.
if Rails.env.production?
  puts "Production environment: only the AdminUser is ensured; demo data skipped."
  return
end

# ── Clean slate (non-production only) ────────────────────────────────────────
# Children first so FK restrict constraints never trip. AdminUser lives in its
# own table and is intentionally untouched.
Payout.with_discarded.delete_all
Payment.delete_all
Route.delete_all
TrackingEvent.delete_all
Review.delete_all
Shipment.with_discarded.delete_all
CargoOffer.delete_all
Cargo.delete_all
TransportWindow.delete_all
Vehicle.with_discarded.delete_all
Carrier.delete_all
Shipper.delete_all
User.delete_all

# ── Locations (lat/lng as DECIMAL — Haversine in app code, no PostGIS) ────────
LOC = {
  caba:    { addr: "Puerto de Buenos Aires",        loc: "CABA",         admin: "Ciudad Autónoma de Buenos Aires", pin: [ -34.603722, -58.381592 ] },
  cordoba: { addr: "Av. Sabattini 5500",            loc: "Córdoba",      admin: "Córdoba",     pin: [ -31.420083, -64.188776 ] },
  rosario: { addr: "Av. Pellegrini 1500",           loc: "Rosario",      admin: "Santa Fe",    pin: [ -32.946820, -60.639317 ] },
  santafe: { addr: "Bv. Pellegrini 3100",           loc: "Santa Fe",     admin: "Santa Fe",    pin: [ -31.633400, -60.700000 ] },
  mendoza: { addr: "Av. San Martín 1100",           loc: "Mendoza",      admin: "Mendoza",     pin: [ -32.889458, -68.844734 ] },
  laplata: { addr: "Av. 7 1200",                    loc: "La Plata",     admin: "Buenos Aires", pin: [ -34.921450, -57.954529 ] },
  mdq:     { addr: "Av. Colón 2200",                loc: "Mar del Plata", admin: "Buenos Aires", pin: [ -38.005477, -57.542611 ] },
  tucuman: { addr: "Av. Sarmiento 600",             loc: "Tucumán",      admin: "Tucumán",     pin: [ -26.808285, -65.217590 ] }
}.freeze

# ── Identity helpers ─────────────────────────────────────────────────────────
make_user = lambda do |email:, full_name:, phone:|
  User.create!(
    email:       email,
    password:    "Password123",
    full_name:   full_name,
    phone:       phone,
    verified_at: Time.current
  )
end

# ── Carriers ─────────────────────────────────────────────────────────────────
diego_user = make_user.call(
  email: "diego.sosa@truckr.test", full_name: "Diego Sosa", phone: "+54 341 555-1010"
)
andina_user = make_user.call(
  email: "operaciones@andinacargo.test", full_name: "Andina Cargo S.A.", phone: "+54 261 555-2020"
)

diego = Carrier.create!(
  user:        diego_user,
  legal_name:  "Diego Sosa",
  tax_id:      "20285647318",
  base_city:   "Rosario",
  province:    "Santa Fe",
  description: "Transportista independiente con base en Rosario. Fletes regionales " \
               "por el litoral y el centro del país, trato directo y horarios flexibles."
)

andina = Carrier.create!(
  user:        andina_user,
  legal_name:  "Andina Cargo S.A.",
  tax_id:      "30715648921",
  base_city:   "Mendoza",
  province:    "Mendoza",
  description: "Empresa de transporte de cargas con flota propia y cobertura nacional. " \
               "Especialistas en cargas pesadas, a granel y de gran volumen."
)

# ── Shippers ─────────────────────────────────────────────────────────────────
granja_user = make_user.call(
  email: "contacto@granjalaesperanza.test", full_name: "Granja La Esperanza", phone: "+54 351 555-3030"
)
laura_user = make_user.call(
  email: "laura.fernandez@truckr.test", full_name: "Laura Fernández", phone: "+54 11 5555-4040"
)

granja = Shipper.create!(
  user:            granja_user,
  company_name:    "Granja La Esperanza S.A.",
  tax_id:          "30708112233",
  billing_address: "Ruta Nacional 9 Km 412, Córdoba"
)

# Expedidora particular (persona física en mudanza): sin razón social.
laura = Shipper.create!(
  user:            laura_user,
  company_name:    nil,
  tax_id:          "27356482190",
  billing_address: "Av. Rivadavia 8200, CABA"
)

# ── Fleets ───────────────────────────────────────────────────────────────────
make_vehicle = lambda do |carrier:, plate:, type:, max_load:, make:, model:, year:|
  Vehicle.create!(
    carrier:      carrier,
    plate:        plate,
    vehicle_type: type,
    max_load_kg:  max_load,
    make:         make,
    model:        model,
    year:         year
  )
end

# Diego — owner-operator: una van y un camión chico.
diego_van   = make_vehicle.call(carrier: diego, plate: "AB123CD", type: "van",         max_load: 2_500.0,  make: "Mercedes-Benz", model: "Sprinter", year: 2021)
diego_truck = make_vehicle.call(carrier: diego, plate: "AC456EF", type: "truck_small", max_load: 7_000.0,  make: "Iveco",         model: "Tector",   year: 2019)

# Andina — empresa: flota variada.
andina_semi   = make_vehicle.call(carrier: andina, plate: "AD789GH", type: "semi_trailer", max_load: 30_000.0, make: "Scania",        model: "R450",   year: 2022)
andina_large1 = make_vehicle.call(carrier: andina, plate: "AE012IJ", type: "truck_large",  max_load: 15_000.0, make: "Volvo",         model: "FH",     year: 2020)
andina_large2 = make_vehicle.call(carrier: andina, plate: "AF345KL", type: "truck_large",  max_load: 14_000.0, make: "Mercedes-Benz", model: "Actros", year: 2021)
andina_van    = make_vehicle.call(carrier: andina, plate: "AG678MN", type: "van",          max_load: 3_500.0,  make: "Renault",       model: "Master", year: 2023)

# ── Builders ─────────────────────────────────────────────────────────────────
make_window = lambda do |vehicle:, from_key:, to_key:, available_from:, available_to:, active:,
                         price: 1_400.0, max_km: 1_500, pickup_radius: 50, dropoff_radius: 50, label: nil|
  o = LOC.fetch(from_key)
  d = LOC.fetch(to_key)
  okey = label ? "#{o[:loc]} (#{label})" : o[:loc]
  dkey = label ? "#{d[:loc]} (#{label})" : d[:loc]

  TransportWindow.create!(
    vehicle:                vehicle,
    origin_address:         "Depósito #{o[:loc]}",
    origin_locality:        okey,
    origin_admin_area:      o[:admin],
    origin_lat:             o[:pin][0],
    origin_lng:             o[:pin][1],
    destination_address:    "Centro de distribución #{d[:loc]}",
    destination_locality:   dkey,
    destination_admin_area: d[:admin],
    destination_lat:        d[:pin][0],
    destination_lng:        d[:pin][1],
    price_per_km:           price,
    max_km:                 max_km,
    available_from:         available_from,
    available_to:           available_to,
    active:                 active,
    pickup_radius_km:       pickup_radius,
    dropoff_radius_km:      dropoff_radius
  )
end

make_cargo = lambda do |shipper:, description:, from_key:, to_key:, pickup_from:, pickup_to:,
                        weight:, distance:, status: "open", value_cents: 80_000_000, volume: 18_000_000|
  o = LOC.fetch(from_key)
  d = LOC.fetch(to_key)
  Cargo.create!(
    shipper:             shipper,
    cargo_description:   description,
    pickup_address:      "#{o[:addr]}, #{o[:loc]}",
    pickup_locality:     o[:loc],
    pickup_admin_area:   o[:admin],
    pickup_lat:          o[:pin][0],
    pickup_lng:          o[:pin][1],
    delivery_address:    "#{d[:addr]}, #{d[:loc]}",
    delivery_locality:   d[:loc],
    delivery_admin_area: d[:admin],
    delivery_lat:        d[:pin][0],
    delivery_lng:        d[:pin][1],
    pickup_window_start: pickup_from,
    pickup_window_end:   pickup_to,
    weight_kg:           weight,
    volume_cm3:          volume,
    declared_value_cents: value_cents,
    distance_km:         distance, # set explicitly → skips the Google Maps Distance API
    status:              status
  )
end

make_offer = lambda do |cargo:, carrier:, window:, amount:, status: "pending",
                        accepted_at: nil, rejected_at: nil, expires_at: nil|
  CargoOffer.create!(
    cargo:            cargo,
    carrier:          carrier,
    transport_window: window,
    amount_cents:     amount,
    currency:         "ARS",
    status:           status,
    accepted_at:      accepted_at,
    rejected_at:      rejected_at,
    expires_at:       expires_at || 72.hours.from_now
  )
end

# Drives a shipment to the requested lifecycle state, keeping the escrowed-payment
# invariant: escrow is created before any status advance.
#   :accepted_unpaid   → accepted, no payment (shipper sees the "Pagar" CTA)
#   :accepted_escrowed → accepted + escrowed payment (carrier can start transit)
#   :in_transit        → escrowed + picked up
#   :delivered         → escrowed + delivered + payout liquidated
build_shipment = lambda do |offer:, mode:, accepted_at:, escrow_at: nil, transit_at: nil, deliver_at: nil, paid_at: nil|
  shipment = Shipment.create!(cargo_offer: offer, status: "accepted", accepted_at: accepted_at)

  unless mode == :accepted_unpaid
    Payment.create!(
      shipment:    shipment,
      amount_cents: offer.amount_cents,
      currency:    offer.currency,
      provider:    "fake",
      state:       "escrowed",
      escrowed_at: escrow_at || accepted_at
    )
  end

  shipment.transition_to!(:in_transit, at: transit_at) if %i[in_transit delivered].include?(mode)
  shipment.transition_to!(:delivered,  at: deliver_at) if mode == :delivered

  if mode == :delivered
    payment    = shipment.payments.find_by(state: "escrowed")
    rate       = BigDecimal("0.15") # platform commission — mirrors Payouts::Create
    gross      = payment.amount_cents
    commission = (gross * rate).ceil
    settled_at = paid_at || deliver_at
    Payout.create!(
      shipment:           shipment,
      payment:            payment,
      gross_amount_cents: gross,
      commission_rate:    rate,
      commission_cents:   commission,
      amount_cents:       gross - commission,
      currency:           payment.currency,
      state:              "paid",
      paid_at:            settled_at
    )
    shipment.update!(settled_at: settled_at)
  end

  shipment
end

add_review = lambda do |shipment:, author:, rating:, body:|
  if author == :shipper_authored
    Reviews::Create.call(shipment: shipment, authored_by: :shipper_authored, rating: rating,
                         body: body, shipper: shipment.cargo_offer.cargo.shipper)
  else
    Reviews::Create.call(shipment: shipment, authored_by: :carrier_authored, rating: rating,
                         body: body, carrier: shipment.cargo_offer.carrier)
  end
end

# ══ Ventanas de transporte vigentes (active) ═════════════════════════════════
# Disponibilidad publicada en el marketplace. Las que quedan sin oferta son
# matcheables; las que llevan una oferta pending quedan reservadas.
aw_diego_match = make_window.call(vehicle: diego_van,    from_key: :rosario, to_key: :caba,
                                  available_from: 2.days.from_now, available_to: 20.days.from_now,
                                  active: true, price: 1_500.0, pickup_radius: 60, dropoff_radius: 60)
make_window.call(vehicle: andina_semi, from_key: :mendoza, to_key: :caba,
                 available_from: 1.day.from_now, available_to: 28.days.from_now, active: true, price: 1_300.0)
aw_andina_large1 = make_window.call(vehicle: andina_large1, from_key: :cordoba, to_key: :rosario,
                                    available_from: 3.days.from_now, available_to: 22.days.from_now, active: true, price: 1_450.0)
aw_andina_van = make_window.call(vehicle: andina_van, from_key: :mendoza, to_key: :caba,
                                 available_from: 2.days.from_now, available_to: 25.days.from_now, active: true, price: 1_350.0)
make_window.call(vehicle: diego_truck, from_key: :santafe, to_key: :cordoba,
                 available_from: 5.days.from_now, available_to: 24.days.from_now, active: true, price: 1_400.0)

# ══ Cargas publicadas (open) ═════════════════════════════════════════════════
# C1 — granja, sin oferta. Coincide exactamente con la ventana vigente de Diego
#      (mismo origen/destino y solapa el rango) → un único match en US48/49/50.
make_cargo.call(shipper: granja, description: "Pallets de soja a granel para exportación",
                from_key: :rosario, to_key: :caba, pickup_from: 3.days.from_now, pickup_to: 15.days.from_now,
                weight: 2_200.0, distance: 300.0, value_cents: 160_000_000)

# C2 — particular, con OFERTA RECIBIDA (pending) de Andina.
c_mudanza_living = make_cargo.call(shipper: laura, description: "Mudanza: juego de living, mesa y cajas",
                                   from_key: :cordoba, to_key: :rosario, pickup_from: 4.days.from_now, pickup_to: 18.days.from_now,
                                   weight: 1_800.0, distance: 405.0, value_cents: 45_000_000)
make_offer.call(cargo: c_mudanza_living, carrier: andina, window: aw_andina_large1, amount: 6_500_000, status: "pending")

# C3 — granja, con OFERTA RECIBIDA (pending) de Andina.
c_manzanas = make_cargo.call(shipper: granja, description: "Cajones de manzanas y peras",
                             from_key: :mendoza, to_key: :caba, pickup_from: 2.days.from_now, pickup_to: 20.days.from_now,
                             weight: 3_200.0, distance: 1_050.0, value_cents: 70_000_000)
make_offer.call(cargo: c_manzanas, carrier: andina, window: aw_andina_van, amount: 8_900_000, status: "pending")

# ══ Ofertas rechazadas ═══════════════════════════════════════════════════════
# C4 — granja: una oferta cara de Diego que la granja rechazó. La carga sigue open.
c_alfalfa = make_cargo.call(shipper: granja, description: "Fardos de alfalfa",
                            from_key: :cordoba, to_key: :mendoza, pickup_from: 2.days.ago, pickup_to: 20.days.from_now,
                            weight: 6_500.0, distance: 610.0, value_cents: 40_000_000)
iw_alfalfa = make_window.call(vehicle: diego_truck, from_key: :cordoba, to_key: :mendoza,
                              available_from: 8.days.ago, available_to: 1.day.ago, active: false, label: "alfalfa")
make_offer.call(cargo: c_alfalfa, carrier: diego, window: iw_alfalfa, amount: 11_000_000,
                status: "rejected", rejected_at: 2.days.ago)

# ══ Envíos vigentes ══════════════════════════════════════════════════════════
# C5 — particular, mudanza de oficina: Diego ofertó caro y fue rechazado; Andina
#      ofertó y fue aceptada → envío EN TRÁNSITO ahora mismo.
c_oficina = make_cargo.call(shipper: laura, description: "Mudanza de oficina: escritorios y sillas",
                            from_key: :caba, to_key: :laplata, pickup_from: 2.days.ago, pickup_to: 10.days.from_now,
                            weight: 2_500.0, distance: 60.0, status: "accepted", value_cents: 55_000_000)
iw_oficina_rej = make_window.call(vehicle: diego_van, from_key: :caba, to_key: :laplata,
                                  available_from: 8.days.ago, available_to: 1.day.ago, active: false, label: "oficina-rej")
make_offer.call(cargo: c_oficina, carrier: diego, window: iw_oficina_rej, amount: 7_800_000,
                status: "rejected", rejected_at: 3.days.ago)
iw_oficina_acc = make_window.call(vehicle: andina_large2, from_key: :caba, to_key: :laplata,
                                  available_from: 8.days.ago, available_to: 1.day.ago, active: false, label: "oficina-acc")
offer_oficina = make_offer.call(cargo: c_oficina, carrier: andina, window: iw_oficina_acc, amount: 5_200_000,
                                status: "accepted", accepted_at: 2.days.ago, expires_at: 1.day.ago)
build_shipment.call(offer: offer_oficina, mode: :in_transit, accepted_at: 2.days.ago,
                    escrow_at: 2.days.ago, transit_at: 1.day.ago)

# C6 — granja: aceptado + escrow, listo para que Andina inicie el viaje.
c_balanceado = make_cargo.call(shipper: granja, description: "Alimento balanceado para ganado",
                               from_key: :santafe, to_key: :cordoba, pickup_from: 2.days.ago, pickup_to: 9.days.from_now,
                               weight: 5_000.0, distance: 350.0, status: "accepted", value_cents: 60_000_000)
iw_balanceado = make_window.call(vehicle: andina_large1, from_key: :santafe, to_key: :cordoba,
                                 available_from: 8.days.ago, available_to: 1.day.ago, active: false, label: "balanceado")
offer_balanceado = make_offer.call(cargo: c_balanceado, carrier: andina, window: iw_balanceado, amount: 9_500_000,
                                   status: "accepted", accepted_at: 1.day.ago, expires_at: 8.days.from_now)
build_shipment.call(offer: offer_balanceado, mode: :accepted_escrowed, accepted_at: 1.day.ago, escrow_at: 1.day.ago)

# C7 — granja: aceptado SIN pagar → la granja ve el CTA "Pagar".
c_maiz = make_cargo.call(shipper: granja, description: "Semillas de maíz en bolsas",
                         from_key: :rosario, to_key: :cordoba, pickup_from: 2.days.ago, pickup_to: 8.days.from_now,
                         weight: 4_000.0, distance: 400.0, status: "accepted", value_cents: 50_000_000)
iw_maiz = make_window.call(vehicle: diego_truck, from_key: :rosario, to_key: :cordoba,
                           available_from: 8.days.ago, available_to: 1.day.ago, active: false, label: "maiz")
offer_maiz = make_offer.call(cargo: c_maiz, carrier: diego, window: iw_maiz, amount: 7_400_000,
                             status: "accepted", accepted_at: 12.hours.ago, expires_at: 8.days.from_now)
build_shipment.call(offer: offer_maiz, mode: :accepted_unpaid, accepted_at: 12.hours.ago)

# ══ Envíos entregados (pasados) + payouts + reseñas ══════════════════════════
# Cada uno: ventana pasada (inactive) + carga accepted + oferta accepted + pago
# en escrow + entrega + payout liquidado al transportista + reseñas bidireccionales.
history = [
  { label: "H1", shipper: granja, carrier: andina, vehicle: andina_large2, from: :cordoba, to: :rosario,
    goods: "Trigo en big bags", weight: 12_000.0, dist: 405.0, amount: 18_000_000, days: 10,
    s_rating: 5, c_rating: 5,
    s_body: "Excelente servicio, el camión llegó en horario y la carga sin un rasguño.",
    c_body: "Carga bien preparada y documentación completa. Volvería a trabajar con ellos." },
  { label: "H2", shipper: granja, carrier: diego, vehicle: diego_truck, from: :santafe, to: :rosario,
    goods: "Verdura fresca en cajones", weight: 5_000.0, dist: 160.0, amount: 6_800_000, days: 18,
    s_rating: 4, c_rating: 5,
    s_body: "Muy buen trato de Diego, entrega puntual. La cadena de frío se mantuvo.",
    c_body: "Todo en orden en el origen. Carga liviana y rápida de acomodar." },
  { label: "H3", shipper: laura, carrier: andina, vehicle: andina_van, from: :mendoza, to: :caba,
    goods: "Mudanza casa familiar", weight: 3_400.0, dist: 1_050.0, amount: 14_500_000, days: 25,
    s_rating: 5, c_rating: 4,
    s_body: "Trasladaron toda la casa con muchísimo cuidado. Súper recomendables.",
    c_body: "Mudanza prolija, cliente puntual con el acceso al departamento." },
  { label: "H4", shipper: laura, carrier: diego, vehicle: diego_truck, from: :cordoba, to: :rosario,
    goods: "Electrodomésticos y muebles", weight: 3_000.0, dist: 405.0, amount: 5_900_000, days: 32,
    s_rating: 4, c_rating: 5,
    s_body: "Buen servicio, llegó cuando dijo. Embalaje del lavarropas impecable.",
    c_body: "Coordinación clara por mensaje, sin sorpresas en el destino." },
  { label: "H5", shipper: granja, carrier: andina, vehicle: andina_semi, from: :rosario, to: :caba,
    goods: "Soja a granel", weight: 28_000.0, dist: 300.0, amount: 24_000_000, days: 40,
    s_rating: 5, c_rating: 5,
    s_body: "Carga a granel sin pérdidas, pesaje exacto en destino. Profesionales.",
    c_body: "Operación de carga ágil en planta. Excelente coordinación logística." },
  { label: "H6", shipper: granja, carrier: diego, vehicle: diego_truck, from: :tucuman, to: :cordoba,
    goods: "Cítricos (limones y naranjas)", weight: 6_000.0, dist: 560.0, amount: 9_200_000, days: 47,
    s_rating: 4, c_rating: 4,
    s_body: "Entrega correcta, fruta en buen estado tras un viaje largo.",
    c_body: "Carga bien estibada. Un par de horas de demora en la carga inicial." }
]

history.each do |h|
  win = make_window.call(vehicle: h[:vehicle], from_key: h[:from], to_key: h[:to],
                         available_from: (h[:days] + 8).days.ago, available_to: (h[:days] + 1).days.ago,
                         active: false, label: h[:label])
  cargo = make_cargo.call(shipper: h[:shipper], description: "#{h[:goods]} (#{h[:label]})",
                          from_key: h[:from], to_key: h[:to],
                          pickup_from: (h[:days] + 8).days.ago, pickup_to: (h[:days] + 1).days.ago,
                          weight: h[:weight], distance: h[:dist], status: "accepted")
  offer = make_offer.call(cargo: cargo, carrier: h[:carrier], window: win, amount: h[:amount],
                          status: "accepted", accepted_at: (h[:days] + 6).days.ago, expires_at: (h[:days] + 1).days.ago)
  shipment = build_shipment.call(offer: offer, mode: :delivered,
                                 accepted_at: (h[:days] + 6).days.ago,
                                 escrow_at:   (h[:days] + 5).days.ago,
                                 transit_at:  (h[:days] + 4).days.ago,
                                 deliver_at:  (h[:days] + 1).days.ago,
                                 paid_at:     h[:days].days.ago)
  add_review.call(shipment: shipment, author: :shipper_authored, rating: h[:s_rating], body: h[:s_body])
  add_review.call(shipment: shipment, author: :carrier_authored, rating: h[:c_rating], body: h[:c_body])
end

# ── Entregado SIN reseñar (el más reciente) ──────────────────────────────────
# Entrega liquidada de la granja con Andina, sin reseñas en ninguna dirección:
# deja vivo el formulario "Dejá tu reseña" en ambos perfiles para la demo de
# US20 (expedidor → transportista) y US30 (transportista → expedidor). Por ser
# la entrega con actividad más reciente, encabeza el listado de envíos.
rm_window = make_window.call(vehicle: andina_van, from_key: :laplata, to_key: :mdq,
                             available_from: 13.days.ago, available_to: 6.days.ago, active: false, label: "RM")
rm_cargo = make_cargo.call(shipper: granja, description: "Maquinaria agrícola (RM)",
                           from_key: :laplata, to_key: :mdq, pickup_from: 13.days.ago, pickup_to: 6.days.ago,
                           weight: 3_000.0, distance: 390.0, status: "accepted", value_cents: 95_000_000)
rm_offer = make_offer.call(cargo: rm_cargo, carrier: andina, window: rm_window, amount: 8_400_000,
                           status: "accepted", accepted_at: 11.days.ago, expires_at: 6.days.ago)
build_shipment.call(offer: rm_offer, mode: :delivered, accepted_at: 11.days.ago,
                    escrow_at: 10.days.ago, transit_at: 8.days.ago, deliver_at: 5.days.ago, paid_at: 4.days.ago)

# ── Denormalised carrier counters (resources compute ratings from reviews; the
#    completed_shipments column is read directly, so keep it truthful). ────────
[ diego, andina ].each do |carrier|
  delivered = Shipment.status_delivered
                      .joins(cargo_offer: {})
                      .where(cargo_offers: { carrier_id: carrier.id })
                      .count
  carrier.update!(
    completed_shipments: delivered,
    reviews_count:       carrier.shipper_reviews_count,
    rating_avg:          carrier.shipper_rating_avg || 0
  )
end

# ── Summary ──────────────────────────────────────────────────────────────────
puts <<~SUMMARY
  ── Truckr demo seed (rebuilt 2026-06-22) ────────────────────────
  Users      : #{User.count}  (carriers #{Carrier.count}, shippers #{Shipper.count})
  Vehicles   : #{Vehicle.count}
  Windows    : #{TransportWindow.count}  (#{TransportWindow.active.count} vigentes, #{TransportWindow.where(active: false).count} pasadas)
  Cargos     : #{Cargo.count}  (#{Cargo.where(status: 'open').count} open, #{Cargo.where(status: 'accepted').count} accepted)
  CargoOffers: #{CargoOffer.count}  (#{CargoOffer.pending.count} pending, #{CargoOffer.accepted.count} accepted, #{CargoOffer.rejected.count} rejected)
  Shipments  : #{Shipment.count}  (#{Shipment.where(status: 'accepted').count} accepted, #{Shipment.where(status: 'in_transit').count} in_transit, #{Shipment.where(status: 'delivered').count} delivered)
  Payments   : #{Payment.count}   Payouts: #{Payout.count}   Reviews: #{Review.count}
  ─────────────────────────────────────────────────────────────────
  Logins (Password123):
    carrier  diego.sosa@truckr.test           — transportista independiente
    carrier  operaciones@andinacargo.test     — empresa de transporte (flota)
    shipper  contacto@granjalaesperanza.test  — granja / agro
    shipper  laura.fernandez@truckr.test      — mudanza (particular)
  Admin: #{admin_email}
  ─────────────────────────────────────────────────────────────────
SUMMARY
