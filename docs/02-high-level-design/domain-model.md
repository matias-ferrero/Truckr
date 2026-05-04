# Domain Model — Truckr®

## 0. Reading Guide

This is the design artefact that gates the first Identity migrations. It covers:

- The four bounded contexts and how they relate (overview).
- **Identity** at "ready-to-migrate" depth (per-table column / index / FK spec).
- **Marketplace**, **Fulfilment**, **Commerce** at conceptual depth (entities + key attributes + cardinalities).
- The `Shipment` finite-state machine.
- Persona ↔ model mapping derived from the [glossary](../05-appendices/glossary.md).
- Cross-reference between USM / backlog and the entities here.
- An index of the architectural decisions (ADR-007 to ADR-010) that constrain this model.

The full ERD set lives under [`docs/04-database-diagrams/`](../04-database-diagrams/) — `erd-overview.puml` mirrors §1; `erd-identity.puml` mirrors §2; `erd-marketplace.puml`, `erd-fulfilment.puml`, `erd-commerce.puml` mirror §§3-5.

> **Naming rule (hard).** Models, tables and columns are **English**. The personas in product copy stay Spanish (`Transportista`, `Expedidor`). Source of truth for the term ↔ identifier mapping: [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md). If a term is missing, add it there first.

---

## 1. Bounded Contexts Overview

Four contexts. Identity is the owner of accounts; Marketplace publishes supply / demand; Fulfilment runs the contracted shipment; Commerce settles the money and fiscal trail.

```
┌───────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│      Identity     │  │     Marketplace    │  │     Fulfilment     │
│                   │  │                    │  │                    │
│ User              │  │ TransportWindow    │  │ Shipment (FSM)     │
│ Carrier           │  │ CargoOffer         │  │ TrackingEvent      │
│ Shipper           │  │ Quote              │  │ Route              │
│ Vehicle           │  │                    │  │                    │
└───────────────────┘  └────────────────────┘  └────────────────────┘
         ▲                       ▲                       ▲
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                       ┌─────────┴─────────┐
                       │      Commerce     │
                       │                   │
                       │ Payment (escrow)  │
                       │ InsurancePolicy   │
                       │ ArcaInvoice       │
                       └───────────────────┘
```

Cross-context relationships rendered in `erd-overview.puml`. The most important arrows:

- `User` 1:0..1 `Carrier`, 1:0..1 `Shipper` — a user may have either, both, or neither profile (ADR-008).
- `Carrier` 1:N `Vehicle`; `Carrier` 1:N `TransportWindow`; `Shipper` 1:N `CargoOffer`.
- `CargoOffer` 1:N `Quote`; `Carrier` 1:N `Quote` (one carrier can quote many offers).
- `Quote` 1:0..1 `Shipment` (an accepted quote produces exactly one shipment).
- `Shipment` 1:N `TrackingEvent`, 1:1 `Route`, 1:1 `Payment`, 1:0..1 `InsurancePolicy`, 1:0..1 `ArcaInvoice`.

### 1.1 Persona ↔ Model Mapping (derived from the glossary)

> This table is **derived** from `docs/05-appendices/glossary.md`. Do not add entries here without adding them to the glossary first.

| Persona / término del producto (es-AR) | Modelo Rails (en) | Tabla | Bounded context |
|----------------------------------------|-------------------|-------|-----------------|
| Usuario (cuenta de auth)               | `User`            | `users` | Identity |
| Transportista                          | `Carrier`         | `carriers` | Identity |
| Expedidor                              | `Shipper`         | `shippers` | Identity |
| Camión / Vehículo                      | `Vehicle`         | `vehicles` | Identity |
| Ventana de transporte                  | `TransportWindow` | `transport_windows` | Marketplace |
| Carga (oferta)                         | `CargoOffer`      | `cargo_offers` | Marketplace |
| Cotización                             | `Quote`           | `quotes` | Marketplace |
| Envío                                  | `Shipment`        | `shipments` | Fulfilment |
| Evento de tracking                     | `TrackingEvent`   | `tracking_events` | Fulfilment |
| Ruta                                   | `Route`           | `routes` | Fulfilment |
| Pago / Escrow                          | `Payment`         | `payments` | Commerce |
| Seguro                                 | `InsurancePolicy` | `insurance_policies` | Commerce |
| Factura ARCA                           | `ArcaInvoice`     | `arca_invoices` | Commerce |

The deprecated synonyms `Cliente` and `Productor` are folded into `Expedidor` / `Shipper`. See the deprecated-synonyms section of the glossary for the two narrow contexts in which "cliente" remains valid (ARCA fiscal counter-party, generic "external customer").

---

## 2. Identity (READY TO MIGRATE)

This section is the brief for the first migration. Every table below is specified at the depth a Rails migration needs: column type, nullability, default, index, FK. Validation rules belong in the AR model and are noted in the `Notes` column where relevant.

### 2.1 `users`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | `bigint` | no | — | PK (ADR-007). |
| `email` | `string` (`citext` in Phase 1+ Postgres) | no | — | Unique. Lower-cased on write. |
| `password_digest` | `string` | no | — | `has_secure_password` (bcrypt). Auth itself is out of scope; the column exists so the first auth issue does not have to migrate. |
| `full_name` | `string` | yes | — | Free-form. |
| `phone` | `string` | yes | — | E.164 stored as text. |
| `dni_or_cuit` | `string` | yes | — | Unique when present (partial index). Format validated in AR. |
| `verified_at` | `datetime` | yes | — | Set when email / KYC is confirmed. |
| `created_at` | `datetime` | no | — | Rails default. |
| `updated_at` | `datetime` | no | — | Rails default. |

**Indexes**:

- `users(email)` unique.
- `users(dni_or_cuit)` unique partial: `WHERE dni_or_cuit IS NOT NULL` (works in SQLite ≥ 3.8 and Postgres).

**Role state**: derived from the `carriers` / `shippers` relation rows. **No denormalised flags on `users`** — the relation row IS the source of truth (ADR-008). See "User model accessors" below.

**Invariants** (enforced in AR):

- `email` is canonicalised to lower-case before save.

**Validations**:

- `email` present, format, unique.
- `password_digest` present (set by `has_secure_password`).
- A user without either profile is allowed (in-progress onboarding); product policy may later require at least one profile after a grace period — enforced in service layer, not at the column level.

**User model accessors** (specified here so the migration issue inherits the contract; no AR code in this issue):

```ruby
class User < ApplicationRecord
  has_one :carrier
  has_one :shipper

  scope :carriers, -> { joins(:carrier).distinct }
  scope :shippers, -> { joins(:shipper).distinct }

  def carrier? = carrier.present?
  def shipper? = shipper.present?
end
```

Do **NOT** denormalise these into boolean columns on `users`. The relation row is the canonical state — see ADR-008 "Why not denormalise" for the rationale.

### 2.2 `carriers` (Carrier profile — `Transportista`)

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | `bigint` | no | — | PK. |
| `user_id` | `bigint` | no | — | FK → `users.id`, unique. `dependent: :destroy` from User. |
| `legal_name` | `string` | yes | — | DBA / company name when available. |
| `base_city` | `string` | yes | — | Indexed alongside `province`. |
| `province` | `string` | yes | — | — |
| `rating_avg` | `decimal(3,2)` | no | `0.0` | 0.00–5.00. Recomputed on review. |
| `completed_shipments` | `integer` | no | `0` | Counter cache. |
| `created_at` / `updated_at` | `datetime` | no | — | — |

**Indexes**:

- `carriers(user_id)` unique.
- `carriers(province, base_city)` for geographic listing (ADR-010 — no PostGIS in Phase 0/1).

**Validations**:

- `user_id` presence, uniqueness.
- `rating_avg` between 0 and 5.

### 2.3 `shippers` (Shipper profile — `Expedidor`)

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | `bigint` | no | — | PK. |
| `user_id` | `bigint` | no | — | FK → `users.id`, unique. `dependent: :destroy`. |
| `company_name` | `string` | yes | — | Optional — individuals also ship. |
| `tax_id` | `string` | yes | — | CUIT for ARCA. Unique partial when present. |
| `billing_address` | `string` | yes | — | Free-form for Phase 0/1; structured in Phase 2. |
| `created_at` / `updated_at` | `datetime` | no | — | — |

**Indexes**:

- `shippers(user_id)` unique.
- `shippers(tax_id)` unique partial: `WHERE tax_id IS NOT NULL`.

**Validations**:

- `user_id` presence, uniqueness.
- `tax_id` format (CUIT check digit) when present.

### 2.4 `vehicles`

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | `bigint` | no | — | PK. |
| `carrier_id` | `bigint` | no | — | FK → `carriers.id`. `dependent: :destroy`. |
| `plate` | `string` | no | — | Argentine plate. Unique. |
| `capacity_kg` | `integer` | no | — | Carrying capacity. |
| `vehicle_type` | `string` | no | `'truck_small'` | Enum (Rails `enum`): `van`, `truck_small`, `truck_large`, `semi_trailer`. Stored as text in SQLite (ADR-002), no native enum type. |
| `gps_enabled` | `boolean` | no | `false` | Marks vehicles whose `TrackingEvent` rows can carry GPS-derived `lat` / `lng`. |
| `created_at` / `updated_at` | `datetime` | no | — | — |

**Indexes**:

- `vehicles(plate)` unique.
- `vehicles(carrier_id)` plain.

**Validations**:

- `plate` presence, uniqueness, format (length 6–8).
- `capacity_kg` > 0.

**Used by** (cross-context): `TransportWindow.vehicle_id` (the truck offered for that supply slot, Marketplace § 3.1); `Quote.vehicle_id` (the truck the Carrier commits when quoting, Marketplace § 3.3); `Shipment.vehicle_id` (the truck physically performing the move, frozen at acceptance, Fulfilment § 4.1). A Vehicle therefore appears in three relations, one per context — see `erd-overview.puml` for the cross-context wiring.

### 2.5 Identity ↔ AdminUser (ActiveAdmin)

`AdminUser` is generated by ActiveAdmin / Devise (see [INF-BE-00003](../features/INF/INF-BE-00003/INF-BE-00003-add-activeadmin.plan.md)) and lives in its own table (`admin_users`). It is **not** a domain user:

- The domain `users` table has no `admin` flag, no `role` enum, and no relation to `admin_users`.
- AdminUser auth uses Devise; domain auth (when it ships) uses `has_secure_password`.
- AdminUser staff have no `Carrier` or `Shipper` profile — they are platform operators.

This separation keeps the domain `User` model free of Devise's `database_authenticatable` columns and lets us evolve domain auth independently.

### 2.6 Naming convention in `app/models/`

Flat namespace (no per-context modules) for now: 13 models is well below the threshold where directory namespacing pays off. Models live directly under `backend/app/models/`. Revisit when the model count crosses ~25, at which point per-context directories (`app/models/identity/`, etc.) become worthwhile.

---

## 3. Marketplace (CONCEPTUAL)

The Marketplace context publishes supply (`TransportWindow`) and demand (`CargoOffer`) and matches them via `Quote`s. Identity (`Carrier`, `Shipper`, `Vehicle`) is referenced by FK; nothing is duplicated.

### 3.1 `TransportWindow` (supply — published by a Carrier)

Key attributes: `carrier_id`, `vehicle_id`, `origin_city`, `origin_lat`, `origin_lng`, `destination_city`, `destination_lat`, `destination_lng`, `start_at`, `end_at`, `available_capacity_kg`, `price_reference`, `status` (`open` / `matched` / `expired` / `cancelled`).

Cardinalities: `Carrier` 1:N `TransportWindow`; `Vehicle` 1:N `TransportWindow`. Lat / lng pair stored per-end (ADR-010).

### 3.2 `CargoOffer` (demand — published by a Shipper)

Key attributes: `shipper_id`, `origin_city`, `origin_lat`, `origin_lng`, `destination_city`, `destination_lat`, `destination_lng`, `pickup_at`, `weight_kg`, `goods_description`, `special_handling`, `max_price`, `status` (`open` / `quoted` / `accepted` / `cancelled`).

Cardinalities: `Shipper` 1:N `CargoOffer`.

### 3.3 `Quote`

Key attributes: `cargo_offer_id`, `carrier_id`, `vehicle_id` (NOT NULL — the specific truck the Carrier commits when quoting), `transport_window_id` (nullable — a carrier can quote without a window), `price_cents`, `currency` (`ARS` default), `message`, `status` (`pending` / `accepted` / `rejected` / `expired`), `accepted_at`, `expires_at`.

Cardinalities: `CargoOffer` 1:N `Quote`; `Carrier` 1:N `Quote`; `Vehicle` 1:N `Quote`. An `accepted` quote is the trigger that creates a `Shipment` (§ 4.1).

**Invariants**:

- If `transport_window_id` is set, `Quote.vehicle_id` MUST equal `TransportWindow.vehicle_id` (a Carrier cannot quote a window with one truck and commit a different one). Enforced in AR validation.
- `Quote.vehicle_id` MUST belong to `Quote.carrier_id` (i.e. `Vehicle.carrier_id == Quote.carrier_id`). Enforced in AR validation.

---

## 4. Fulfilment (CONCEPTUAL + FSM)

### 4.1 `Shipment` finite-state machine

Schema (key attributes): `quote_id` (unique), `carrier_id`, `shipper_id`, `vehicle_id` (NOT NULL — frozen at acceptance, copied from the accepted `Quote.vehicle_id`; this is the truck that physically performs the shipment, immutable for traceability), `status` (see FSM), `pickup_at`, `delivered_at`, `settled_at`, `cancelled_at`, `deleted_at` (soft-delete, ADR-009).

States: `draft → quoted → accepted → in_transit → delivered → settled`. Branch: `cancelled`. Modelled by hand (no `aasm` / `state_machines` gem) until the complexity warrants one. Soft-deleted (ADR-009).

| From → To | Guard | Side effect |
|-----------|-------|-------------|
| `draft → quoted` | At least one `Quote.status = 'pending'` exists for the linked `CargoOffer`. | Append `TrackingEvent('quoted')`. |
| `quoted → accepted` | The Shipper confirms one `Quote` (transitions it to `accepted`). | Append `TrackingEvent('accepted')`. **Copy `Quote.vehicle_id` into `Shipment.vehicle_id`** (frozen from this point on). Open a `Payment` row in `escrowed` status (Commerce). Other pending quotes for the same offer are auto-rejected. |
| `accepted → in_transit` | The Carrier signals pickup. | Append `TrackingEvent('picked_up')`. |
| `in_transit → delivered` | The Carrier signals delivery. | Append `TrackingEvent('delivered')`. |
| `delivered → settled` | Either the Shipper confirms, or N hours elapse without dispute. | Append `TrackingEvent('settled')`. Release `Payment` from escrow. Emit `ArcaInvoice` (asynchronous job). |
| `{any except settled} → cancelled` | Per-state guard: pre-`accepted` cancellations are free; post-`accepted` may incur fees. | Append `TrackingEvent('cancelled')`. Refund or partially refund `Payment` according to the guard rules. |

**Vehicle reassignment**: NOT supported in Phase 0/1. `Shipment.vehicle_id` is frozen at `quoted → accepted` and never changes. If a Carrier needs to swap trucks (breakdown, scheduling conflict), the only path is to **cancel the Shipment and generate a new Quote** with the replacement Vehicle. Treating mid-flight vehicle swap as a state-change side effect (with its own tracking event, payment implication, and ARCA fiscal impact) is deliberately out of scope; revisit when the operational data demands it.

Implementation note: every transition lives in a method on `Shipment` (e.g. `Shipment#accept!`, `#cancel!`) that is wrapped in a transaction with the side-effect writes. No domain event bus yet — direct calls suffice for Phase 0/1.

### 4.2 `TrackingEvent` (append-only log)

Key attributes: `shipment_id`, `event_type` (`quoted`, `accepted`, `picked_up`, `waypoint`, `position`, `delay`, `delivered`, `settled`, `cancelled`, `exception`), `occurred_at`, `lat`, `lng`, `note`. Hard-deleted only via `Shipment` cascade — and only because `Shipment` is soft-deleted, so `TrackingEvent` rows are functionally retained.

### 4.3 `Route`

Key attributes: `shipment_id` (unique), `polyline` (text), `waypoints_json` (text), `eta`, `provider` (`google` / `here` / `osrm`).

---

## 5. Commerce (CONCEPTUAL)

Soft-delete enabled on `Payment` and `ArcaInvoice` per ADR-009. `InsurancePolicy` is hard-deleted; expired policies remain queryable through their `status` column.

### 5.1 `Payment` (escrow)

Key attributes: `shipment_id`, `shipper_id`, `carrier_id`, `amount_cents`, `currency`, `provider` (`mercadopago` / `stripe` / `other`), `provider_reference`, `status` (`pending` / `escrowed` / `released` / `refunded` / `disputed`), `escrowed_at`, `released_at`, `deleted_at` (soft-delete). Soft-deletes preserve dispute / refund traceability.

### 5.2 `InsurancePolicy`

Key attributes: `shipment_id` (unique), `provider`, `policy_number`, `coverage_amount_cents`, `premium_cents`, `status` (`quoted` / `active` / `expired` / `claimed`).

### 5.3 `ArcaInvoice`

Key attributes: `shipment_id`, `shipper_id` (the **fiscal** counter-party — the only valid in-domain use of "cliente" in the deprecated sense; see glossary), `cae` (ARCA authorisation code), `document_type` (`factura_a` / `factura_b` / `factura_c`), `total_cents`, `currency`, `emitted_at`, `status` (`pending` / `emitted` / `rejected`), `deleted_at`. Emission is asynchronous (job, scoped out of this issue).

---

## 6. Cross-Reference USM ↔ Entities

This table maps USM / `backlog-us.typ` user stories to the entities they exercise. The intent is to make it obvious which entity each US is going to touch before the migration is written. US numbering follows `docs/artifacts/backlog-us.typ`.

| US | Entity / entities | Bounded context |
|----|-------------------|-----------------|
| US1 — Registro de cuenta (expedidor o transportista) | `User`, `Carrier`, `Shipper` | Identity |
| US2 — Login | `User` | Identity |
| US3 — Edición de perfil (expedidor o transportista) | `User`, `Carrier`, `Shipper` | Identity |
| US4 — Búsqueda de transportistas | `Carrier`, `TransportWindow` | Marketplace |
| US5 — Visualizar detalles de transportista | `Carrier`, `Vehicle` | Identity / Marketplace |
| US6 — Publicar oferta (cargo) | `CargoOffer` | Marketplace |
| US7 — Recibir y comparar cotizaciones | `Quote`, `CargoOffer` | Marketplace |
| US8 — Realizar pago (expedidor) | `Payment`, `Shipment` | Commerce / Fulfilment |
| US9 — Publicar disponibilidad (transportista) | `TransportWindow`, `Vehicle` | Marketplace |
| US10 — Listado de ofertas para transportistas | `CargoOffer`, `TransportWindow` | Marketplace |
| US11 — Aceptar viaje | `Quote`, `Shipment` | Marketplace / Fulfilment |
| US12 — Registrar vehículo | `Vehicle`, `Carrier` | Identity |
| US13 — Notificaciones de estado | `TrackingEvent`, `Shipment` | Fulfilment |
| US14 — Historial de viajes | `Shipment` | Fulfilment |
| US15 — Marcar producto recogido | `Shipment`, `TrackingEvent` | Fulfilment |
| US16 — Marcar producto entregado | `Shipment`, `TrackingEvent` | Fulfilment |
| US17 — Reseñas | (TBD — `Review` — not yet modelled, see § 9 What's Next) | Identity |
| US18 — Tracking GPS en vivo | `TrackingEvent`, `Vehicle` | Fulfilment |
| US19 — Viajes encadenados | `Shipment`, `Route` | Fulfilment |
| US20 — Seguro | `InsurancePolicy`, `Shipment` | Commerce |
| US21 — Editar reseñas | (TBD — `Review`) | Identity |

The two TBD slots (`Review` US17 / US21) are intentional gaps — see § 9.

---

## 7. Decisions Index

| Decision | Lives in | Summary |
|----------|----------|---------|
| **ADR-007** | `01-technical-vision/technical-vision.md` | `bigint` PKs (Rails default). UUIDs not justified. |
| **ADR-008** | `01-technical-vision/technical-vision.md` | `User` + `Carrier` / `Shipper` extension tables; role state derived from relation rows (no denormalised flags); scopes / predicates on `User`; `AdminUser` isolated. |
| **ADR-009** | `01-technical-vision/technical-vision.md` | Soft-delete only on `Shipment`, `Payment`, `ArcaInvoice`. Hard-delete elsewhere. |
| **ADR-010** | `01-technical-vision/technical-vision.md` | Lat / lng `DECIMAL(9,6)` columns Phase 0/1; PostGIS Phase 2 alongside Postgres. |
| **Decision F** (this doc § 4.1) | here | `Shipment` FSM modelled by hand — no `aasm` gem until complexity warrants. |
| **Decision G** (this doc § 2.6) | here | Flat namespace under `app/models/`; revisit at ~25 models. |

---

## 8. ERD Cross-Reference

| Diagram | Scope | Status |
|---------|-------|--------|
| `docs/04-database-diagrams/erd-overview.puml` | All four contexts at high level | Draft v1 |
| `docs/04-database-diagrams/erd-identity.puml` | `users`, `carriers`, `shippers`, `vehicles` (ready-to-migrate) | Draft v1 |
| `docs/04-database-diagrams/erd-marketplace.puml` | `transport_windows`, `cargo_offers`, `quotes` | Draft v1 (conceptual) |
| `docs/04-database-diagrams/erd-fulfilment.puml` | `shipments`, `tracking_events`, `routes` | Draft v1 (conceptual) |
| `docs/04-database-diagrams/erd-commerce.puml` | `payments`, `insurance_policies`, `arca_invoices` | Draft v1 (conceptual) |

---

## 9. What's Next

Out of scope for this issue, but blocked on it:

- **First Identity migrations** — `User`, `Carrier`, `Shipper`, `Vehicle` migrations + AR models + minimal RSpec specs.
- **First real endpoint** — `Api::QuoteRequestsController#create` once Marketplace entities exist.
- **Auth strategy** — `has_secure_password` integration; Pundit policies scoped via `User#carrier?` / `User#shipper?` predicates (which read the `has_one :carrier` / `has_one :shipper` relations — see ADR-008).
- **Review entity** — US17 / US21 (reseñas) are not yet modelled. Adding `Review` (FK `shipment_id`, `author_user_id`, `rating`, `body`, soft-delete?) is a small follow-up issue.
- **`Match`** — the USM mentions matching as a distinct concept; in this draft it is collapsed into `Quote`. Promote to a separate entity only if matching algorithms grow stateful.
- **`Shipment` chained trips (US19)** — viajes encadenados may need a `ShipmentChain` aggregate. Punted to Phase 2.
- **PostGIS migration** — Phase 2 trigger (ADR-010).

---

## Document Information

| Attribute | Value |
|-----------|-------|
| Version | 1.0 |
| Created | 2026-05-03 |
| Issue | REQ-BE-00005 |
| Author | Claude Code |
| Scope | Truckr® domain model — Identity ready-to-migrate; Marketplace / Fulfilment / Commerce conceptual. |
