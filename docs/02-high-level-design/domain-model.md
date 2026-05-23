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
│ Carrier           │  │ Cargo              │  │ TrackingEvent      │
│ Shipper           │  │ CargoOffer         │  │ Route              │
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
- `Carrier` 1:N `Vehicle`; `Carrier` 1:N `TransportWindow`; `Shipper` 1:N `Cargo`.
- `Cargo` 1:N `CargoOffer`; `TransportWindow` 1:N `CargoOffer` (one window can receive many offers over its lifetime, but only one `pending` at a time in MVP).
- `CargoOffer` 1:0..1 `Shipment` (an accepted offer produces exactly one shipment).
- `Shipment` 1:N `TrackingEvent`, 1:1 `Route`, **1:N `Payment`** (per-attempt; see § 5.1), 1:0..1 `InsurancePolicy`, 1:0..1 `ArcaInvoice`.

### 1.1 Persona ↔ Model Mapping (derived from the glossary)

> This table is **derived** from `docs/05-appendices/glossary.md`. Do not add entries here without adding them to the glossary first.

| Persona / término del producto (es-AR) | Modelo Rails (en) | Tabla | Bounded context |
|----------------------------------------|-------------------|-------|-----------------|
| Usuario (cuenta de auth)               | `User`            | `users` | Identity |
| Transportista                          | `Carrier`         | `carriers` | Identity |
| Expedidor                              | `Shipper`         | `shippers` | Identity |
| Camión / Vehículo                      | `Vehicle`         | `vehicles` | Identity |
| Ventana de transporte                  | `TransportWindow` | `transport_windows` | Marketplace |
| Carga                                  | `Cargo`           | `cargos` | Marketplace |
| Oferta de carga                        | `CargoOffer`      | `cargo_offers` | Marketplace |
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

**Used by** (cross-context): `TransportWindow.vehicle_id` (the truck offered for that supply slot, Marketplace § 3.1); `CargoOffer.vehicle_id` (the truck transitively pinned by the `TransportWindow` the Shipper targets when offering, Marketplace § 3.3); `Shipment.vehicle_id` (the truck physically performing the move, frozen at acceptance, Fulfilment § 4.1). A Vehicle therefore appears in three relations, one per context — see `erd-overview.puml` for the cross-context wiring.

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

The Marketplace context publishes supply (`TransportWindow`) and demand (`Cargo`) and matches them via `CargoOffer`s authored by the Shipper. Identity (`Carrier`, `Shipper`, `Vehicle`) is referenced by FK; nothing is duplicated.

### 3.1 `TransportWindow` (supply — published by a Carrier)

Key attributes: `carrier_id`, `vehicle_id`, `origin_city`, `origin_lat`, `origin_lng`, `destination_city`, `destination_lat`, `destination_lng`, `start_at`, `end_at`, `available_capacity_kg`, `price_reference`, `pickup_radius_km`, `status` (`open` / `pending_offer` / `reserved` / `closed`).

Cardinalities: `Carrier` 1:N `TransportWindow`; `Vehicle` 1:N `TransportWindow`. Lat / lng pair stored per-end (ADR-010).

**Status transitions** (MVP — Window-locks-on-Offer):

- `open → pending_offer`: a Shipper authors a `CargoOffer` against this Window. Only one pending offer at a time in MVP.
- `pending_offer → open`: the Carrier rejects the `CargoOffer`, or the 48 h expiration fires. Auto-flipped in the same DB transaction as the reject/expire — no manual Carrier step. Window immediately re-appears in other Shippers' search results.
- `pending_offer → reserved`: the Carrier accepts the `CargoOffer`. Window is locked to that Cargo + Vehicle.
- `reserved → closed`: the resulting `Shipment` reaches `delivered` (or `cancelled`); Window is retired.

**Product scope evolution** (post-MVP target, not infra deferral): move to Both-sides-parallel where a Window can hold multiple `pending_offer`s simultaneously and the Carrier picks one. The `pending_offer` state is intentionally named to survive that evolution.

### 3.2 `Cargo` (demand — published by a Shipper)

Key attributes: `shipper_id`, `origin_city`, `origin_lat`, `origin_lng`, `destination_city`, `destination_lat`, `destination_lng`, `pickup_at`, `weight_kg`, `goods_description`, `special_handling`, `status` (`open` / `accepted` / `cancelled`).

Cardinalities: `Shipper` 1:N `Cargo`; `Cargo` 1:N `CargoOffer` (a Cargo may spawn many offers across different Windows — see § 3.3).

**Status transitions**:

- `open`: Cargo is published and accepting offers. The Shipper may have zero, one, or many `pending` `CargoOffer`s against compatible Windows; Cargo stays `open` regardless.
- `open → accepted`: a Carrier accepts one of the Cargo's `CargoOffer`s. In the same DB transaction, all sibling `pending` `CargoOffer`s for this Cargo are auto-`rejected`, and their respective Windows auto-flip `pending_offer → open` (see § 3.1).
- `open → cancelled`: the Shipper cancels before any offer is accepted.

### 3.3 `CargoOffer` (Shipper-authored bid against a `TransportWindow`)

Key attributes: `cargo_id`, `transport_window_id` (NOT NULL — Shipper-authored offers always target a specific Window), `carrier_id` (denormalised from the Window for query convenience and FK integrity at accept-time), `vehicle_id` (NOT NULL — transitively pinned by the Window), `price_cents`, `currency` (`ARS` default), `message`, `status` (`pending` / `accepted` / `rejected` / `expired`), `accepted_at`, `expires_at` (48 h from creation).

Cardinalities: `Cargo` 1:N `CargoOffer`; `TransportWindow` 1:N `CargoOffer`; `Carrier` 1:N `CargoOffer`. An `accepted` `CargoOffer` is the trigger that creates a `Shipment` (§ 4.1).

**Invariants** (enforced in AR validation):

- `CargoOffer.vehicle_id` MUST equal `TransportWindow.vehicle_id` (Shipper selects a Window which transitively pins the truck — they cannot author an offer that points at a different truck than the Window advertises).
- `CargoOffer.carrier_id` MUST equal `TransportWindow.carrier_id` (same transitive pin, for the Carrier).
- `CargoOffer.vehicle_id` MUST belong to `CargoOffer.carrier_id` (i.e. `Vehicle.carrier_id == CargoOffer.carrier_id`).
- At most one `pending` `CargoOffer` per `transport_window_id` at any time (MVP Window-locks-on-Offer); enforced by application-layer guard since SQLite has no `EXCLUDE` constraint.

---

## 4. Fulfilment (CONCEPTUAL + FSM)

### 4.1 `Shipment` finite-state machine

Schema (key attributes): `cargo_offer_id` (unique), `carrier_id`, `shipper_id`, `vehicle_id` (NOT NULL — frozen at acceptance, copied from the accepted `CargoOffer.vehicle_id`; this is the truck that physically performs the shipment, immutable for traceability), `status` (see FSM), `pickup_at`, `delivered_at`, `settled_at`, `cancelled_at`, `deleted_at` (soft-delete, ADR-009).

States: `draft → offered → accepted → in_transit → delivered → settled`. Branch: `cancelled`. Modelled by hand (no `aasm` / `state_machines` gem) until the complexity warrants one. Soft-deleted (ADR-009).

| From → To | Guard | Side effect |
|-----------|-------|-------------|
| `draft → offered` | At least one `CargoOffer.status = 'pending'` exists for the linked `Cargo`. | Append `TrackingEvent('offered')`. |
| `offered → accepted` | The Carrier confirms one `CargoOffer` (transitions it to `accepted`). | Append `TrackingEvent('accepted')`. **Copy `CargoOffer.vehicle_id` into `Shipment.vehicle_id`** (frozen from this point on). Sibling pending `CargoOffer`s for the same `Cargo` are auto-rejected; their Windows auto-flip back to `open` (§ 3.1). **No `Payment` row is created at this point** — payment is Shipper-initiated and lives in its own bounded context (see § 5.1). |
| `accepted → in_transit` | The Carrier signals pickup. Predicate: at least one `Payment` for this Shipment is `escrowed` (the Shipper paid). | Append `TrackingEvent('picked_up')`. |
| `in_transit → delivered` | The Carrier signals delivery. | Append `TrackingEvent('delivered')`. |
| `delivered → settled` | Either the Shipper confirms, or N hours elapse without dispute. | Append `TrackingEvent('settled')`. Emit `ArcaInvoice` (asynchronous job). **MVP: no escrow release** — `Payment.status` is terminal at `escrowed`; a real-gateway integration would add `released` and a settlement job here. |
| `{any except settled} → cancelled` | Per-state guard: pre-`accepted` cancellations are free; post-`accepted` may incur fees. | Append `TrackingEvent('cancelled')`. **MVP: no automatic refund** — refund flow is post-MVP; record the cancellation and reconcile out-of-band. |

> **Payment as a predicate, not a state.** The Shipment FSM intentionally does not include a "paid" or "to_pickup" state. Whether a Shipment is payment-ready is a derived predicate: `shipment.payments.escrowed.exists?`. UI surfaces this as a label ("a recoger" once the Shipper has paid; "pendiente de pago" otherwise) but the canonical state stays at `accepted` until pickup. Rationale: keeps the FSM aligned with physical events (pickup, delivery, settlement) and avoids a financial state in a logistics machine. See ADR-012.

**Vehicle reassignment**: NOT supported in Phase 0/1. `Shipment.vehicle_id` is frozen at `offered → accepted` and never changes. If a Carrier needs to swap trucks (breakdown, scheduling conflict), the only path is to **cancel the Shipment and have the Shipper author a new `CargoOffer`** against a different Window with the replacement Vehicle. Treating mid-flight vehicle swap as a state-change side effect (with its own tracking event, payment implication, and ARCA fiscal impact) is deliberately out of scope; revisit when the operational data demands it.

Implementation note: every transition lives in a method on `Shipment` (e.g. `Shipment#accept!`, `#cancel!`) that is wrapped in a transaction with the side-effect writes. No domain event bus yet — direct calls suffice for Phase 0/1.

### 4.2 `TrackingEvent` (append-only log)

Key attributes: `shipment_id`, `event_type` (`offered`, `accepted`, `picked_up`, `waypoint`, `position`, `delay`, `delivered`, `settled`, `cancelled`, `exception`), `occurred_at`, `lat`, `lng`, `note`. Hard-deleted only via `Shipment` cascade — and only because `Shipment` is soft-deleted, so `TrackingEvent` rows are functionally retained.

### 4.3 `Route`

Key attributes: `shipment_id` (unique), `polyline` (text), `waypoints_json` (text), `eta`, `provider` (`google` / `here` / `osrm`).

---

## 5. Commerce (CONCEPTUAL)

Soft-delete enabled on `Payment` and `ArcaInvoice` per ADR-009. `InsurancePolicy` is hard-deleted; expired policies remain queryable through their `status` column.

### 5.1 `Payment` (Shipper-initiated charge with escrow semantics)

**Cardinality**: `Shipment` 1:N `Payment` — every "Pagar" click creates a fresh `Payment` row (per-attempt history). At most one row per Shipment is in `pending` or `escrowed` at any time; the rest are `rejected` (terminal). Soft-deleted (discard gem) per ADR-009 — failed attempts are kept for audit.

**Key attributes**: `shipment_id`, `amount_cents` (frozen from `CargoOffer.price` at create), `currency` (default `ARS`), `provider` (`fake` / `mercadopago` / `stripe` / `other`), `provider_reference` (the ID returned by the gateway), `status` (see FSM below), `escrowed_at`, `rejected_at`, `discarded_at` (discard gem).

**FSM (MVP)**:

```
pending --gateway:approved--> escrowed   (terminal)
pending --gateway:rejected--> rejected   (terminal)
pending --shipper:abandon!-> rejected    (Shipper-initiated recovery from a stuck pending)
```

- `escrowed` is **terminal in the MVP**. There is no settlement job and no `released` transition. Once `escrowed`, the Payment unlocks: (a) the Shipper's view of the Carrier's contact info, (b) the Carrier's permission to mark the Shipment `in_transit`. See `domain-model.md` § 4.1.
- `rejected` is terminal. The Shipper retries by creating a new `Payment` row (a new "Pagar" click → `POST /api/shipments/:id/payments`).
- The Shipper can abandon a stuck `pending` row (e.g. tab closed before gateway resolved) via `POST /api/payments/:id/abandon`, transitioning it to `rejected`. This unblocks retry without admin intervention.
- `refunded` and `disputed` states from earlier drafts are **deferred to post-MVP**. Re-introducing them requires a real gateway integration and a settlement / dispute flow — out of scope for the MVP. See ADR-012.

**Gateway abstraction**: a `Payments::Gateway` Ruby interface (`create_intent`, `confirm!`) is implemented in the MVP by `Payments::FakeGateway`, a deterministic in-process implementation whose `outcome` is driven by a UI button (`/dev/fake-payment/:provider_reference`). The fake gateway is **always-on**, including in production — it IS the production gateway for the MVP. Real MercadoPago / Stripe integration becomes a single new implementation of the same interface, no domain change.

### 5.2 `InsurancePolicy`

Key attributes: `shipment_id` (unique), `provider`, `policy_number`, `coverage_amount_cents`, `premium_cents`, `status` (`active` / `expired` / `claimed`).

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
| US4 — Búsqueda de ventanas compatibles con mi carga | `Cargo`, `TransportWindow` | Marketplace |
| US5 — Refinar ventanas compatibles | `Cargo`, `TransportWindow` | Marketplace |
| US6 — Detalles de transportista (perfil público + CTA ofertar) | `Carrier`, `Vehicle`, `TransportWindow`, `Cargo` | Identity / Marketplace |
| US7 — Ofertar retiro de un producto (autoría de `CargoOffer` contra una ventana) | `CargoOffer`, `Cargo`, `TransportWindow` | Marketplace |
| US8 — Realizar pago (expedidor) | `Payment`, `Shipment` | Commerce / Fulfilment |
| US9 — Publicar disponibilidad (transportista) | `TransportWindow`, `Vehicle` | Marketplace |
| US10 — Listado de ofertas para transportistas | `Cargo`, `TransportWindow` | Marketplace |
| US11 — Aceptar viaje | `CargoOffer`, `Shipment` | Marketplace / Fulfilment |
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
| US22 — Verificación de cuenta por email | `User` | Identity |
| US23 — Viajes compuestos (multi-pickup / multi-delivery) | `Shipment`, `Route`, `TrackingEvent` | Fulfilment |
| US24 — Encadenado de pedidos (rutas secuenciales) | `Shipment`, `Route` | Fulfilment |
| US25 — Seguros (cotización por valor y distancia) | `InsurancePolicy`, `Shipment`, `Cargo` | Commerce |
| US26 — Editar y eliminar reseña | (TBD — `Review`) | Identity |
| US27 — Publicar carga (Shipper) | `Cargo`, `Shipper` | Marketplace |

The TBD slots (`Review` US17 / US21 / US26) are intentional gaps — see § 9.

---

## 7. Decisions Index

| Decision | Lives in | Summary |
|----------|----------|---------|
| **ADR-007** | `01-technical-vision/technical-vision.md` | `bigint` PKs (Rails default). UUIDs not justified. |
| **ADR-008** | `01-technical-vision/technical-vision.md` | `User` + `Carrier` / `Shipper` extension tables; role state derived from relation rows (no denormalised flags); scopes / predicates on `User`; `AdminUser` isolated. |
| **ADR-009** | `01-technical-vision/technical-vision.md` | Soft-delete only on `Shipment`, `Payment`, `ArcaInvoice`. Hard-delete elsewhere. |
| **ADR-010** | `01-technical-vision/technical-vision.md` | Lat / lng `DECIMAL(9,6)` columns Phase 0/1; PostGIS Phase 2 alongside Postgres. |
| **ADR-012** | `01-technical-vision/technical-vision.md` | `Payment` model: Shipment 1:N (per-attempt rows), FSM `pending → escrowed \| rejected` (no `released`/`refunded`/`disputed` in MVP), fake gateway always-on in production. |
| **Decision F** (this doc § 4.1) | here | `Shipment` FSM modelled by hand — no `aasm` gem until complexity warrants. |
| **Decision G** (this doc § 2.6) | here | Flat namespace under `app/models/`; revisit at ~25 models. |

---

## 8. ERD Cross-Reference

| Diagram | Scope | Status |
|---------|-------|--------|
| `docs/04-database-diagrams/erd-overview.puml` | All four contexts at high level | Draft v1 |
| `docs/04-database-diagrams/erd-identity.puml` | `users`, `carriers`, `shippers`, `vehicles` (ready-to-migrate) | Draft v1 |
| `docs/04-database-diagrams/erd-marketplace.puml` | `transport_windows`, `cargos`, `cargo_offers` | Draft v1 (conceptual) |
| `docs/04-database-diagrams/erd-fulfilment.puml` | `shipments`, `tracking_events`, `routes` | Draft v1 (conceptual) |
| `docs/04-database-diagrams/erd-commerce.puml` | `payments`, `insurance_policies`, `arca_invoices` | Draft v1 (conceptual) |

---

## 9. What's Next

Out of scope for this issue, but blocked on it:

- **First Identity migrations** — `User`, `Carrier`, `Shipper`, `Vehicle` migrations + AR models + minimal RSpec specs.
- **First real endpoint** — `Api::CargoOffersController#create` once Marketplace entities exist (Shipper authors a `CargoOffer` against a chosen `TransportWindow`).
- **Auth strategy** — `has_secure_password` integration; Pundit policies scoped via `User#carrier?` / `User#shipper?` predicates (which read the `has_one :carrier` / `has_one :shipper` relations — see ADR-008).
- **Review entity** — US17 / US21 (reseñas) are not yet modelled. Adding `Review` (FK `shipment_id`, `author_user_id`, `rating`, `body`, soft-delete?) is a small follow-up issue.
- **`Match`** — the USM mentions matching as a distinct concept; in this draft it is collapsed into `CargoOffer`. Promote to a separate entity only if matching algorithms grow stateful.
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
