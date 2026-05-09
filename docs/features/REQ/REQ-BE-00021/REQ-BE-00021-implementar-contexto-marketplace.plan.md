# REQ-BE-00021: Implementar contexto Marketplace — TransportWindow, CargoOffer, Quote

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00021 |
| **Title** | Implementar contexto Marketplace — TransportWindow, CargoOffer, Quote (migraciones + AR) |
| **Priority** | P0 |
| **Status** | READY |
| **Created** | 2026-05-03 |
| **Updated** | 2026-05-09 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00005` (diseño de dominio — mergeado) y `REQ-BE-00020` (Identity: `users`, `carriers`, `shippers`, `vehicles` deben existir antes de aplicar las migraciones de este issue) |
| **Blocks** | `REQ-BE-00022` (Fulfilment: `Shipment.quote_id` FK contra `quotes.id`); `REQ-BE-00006/7/11` (payment / payout / settle); `REQ-FE-00006/7/8`; US4–US12. |
| **Decision Doc** | N/A — single approach prescrito por el issue |
| **Selected Approach** | Migraciones + modelos AR + ActiveAdmin read-only + factories + seeds + specs, alineado con ADR-007/009/010 y `domain-model.md` § 3 (Marketplace). |

> **Reading anchors**: parent design plan `docs/features/REQ/REQ-BE-00005/REQ-BE-00005-disenar-modelo-de-dominio-inicial.plan.md`; domain spec `docs/02-high-level-design/domain-model.md` § 3; glossary `docs/05-appendices/glossary.md`; ADR index `docs/01-technical-vision/technical-vision.md` (ADR-007 PK bigint, ADR-009 soft-delete selectivo, ADR-010 geo Phase 0/1).

---

## 1. Problem Statement

`REQ-BE-00005` cerró el diseño del dominio y `REQ-BE-00020` deja persistido el contexto **Identity** (`users`, `carriers`, `shippers`, `vehicles`). Sin las entidades del **Marketplace** no hay forma de:

- publicar disponibilidad (US9 — `TransportWindow`),
- publicar cargas (US6 — `CargoOffer`),
- emitir / aceptar cotizaciones (US7, US10–US12 — `Quote`),
- iniciar el flujo de pago + escrow (US8 — depende de `Quote.accepted` para crear el `Shipment` que opera Fulfilment).

Este issue implementa esas tres tablas + modelos AR + ActiveAdmin (read-only) + factories + seeds + specs. La invocación de las transiciones de la state machine de `Quote` queda fuera de scope (la disparan `REQ-BE-00007` y US12); este issue solo deja el contrato de transiciones documentado y los predicados disponibles.

### Estado de partida

- `backend/app/models/` solo tiene `ApplicationRecord` y `AdminUser` (de `INF-BE-00003`).
- `backend/db/migrate/` solo tiene las migraciones de Devise/AA (admin).
- `backend/spec/` ya tiene `rspec-rails` configurado (smoke, admin specs).
- `factory_bot_rails` y `faker` NO están en el `Gemfile` todavía — los suma este issue (factories son AC del propio issue).
- `discard` (soft-delete) NO está en el `Gemfile` y NO lo agrega este issue: ADR-009 limita soft-delete a `Shipment`, `Payment`, `ArcaInvoice`. **`quotes`, `transport_windows`, `cargo_offers` son hard-delete.** Decisión cementada en § 6.3.

---

## 2. Solution Design

### 2.1 Approach

Tres migraciones + tres modelos AR + tres registros ActiveAdmin (read-only) + tres factories + extensión de seeds + specs ≥80% sobre los nuevos modelos. Sin endpoints — siguen los issues de feature posteriores.

Orden de escritura recomendado:

1. Gemfile (`factory_bot_rails`, `faker`).
2. Migraciones (en orden FK: `transport_windows` → `cargo_offers` → `quotes`).
3. Modelos AR + asociaciones inversas. `TransportWindow` cuelga de `Vehicle` (no de `Carrier`); `Vehicle has_many :transport_windows, dependent: :destroy` ya queda declarado por `REQ-BE-00020`. Este issue verifica el `inverse_of` y agrega `Carrier has_many :transport_windows, through: :vehicles` para queries cómodas + `Shipper has_many :cargo_offers`.
4. Factories.
5. Seeds.
6. ActiveAdmin resources.
7. RSpec specs (validations, scopes, state-machine predicates).

### 2.2 Key Design Decisions (heredadas, ratificadas)

- **PK**: `bigint` default Rails (ADR-007). Aplica a `transport_windows`, `cargo_offers`, `quotes`.
- **Soft-delete**: NO en este contexto (ADR-009). Las tres tablas son hard-delete. `Quote` cancelado se mantiene con `status='cancelled'` (audit por `status`, no por `discarded_at`).
- **Geo (ADR-010)**: las columnas `origin_zone` / `destination_zone` (TransportWindow) y `pickup_address` / `delivery_address` (CargoOffer) son **strings libres** en Phase 0/1 — coincide con la nota técnica del propio issue. El draft de `domain-model.md` § 3 menciona `origin_lat/lng/...` como campos conceptuales; este issue **NO** los persiste todavía (decisión documentada en § 9 — "ambigüedad resuelta a favor del issue"). PostGIS y columnas lat/lng se introducirán cuando el endpoint de matching los necesite.
- **Naming**: identifiers en inglés (regla dura). Tablas `transport_windows`, `cargo_offers`, `quotes`. Columnas según el issue (no traducir a español).
- **Currency**: solo `ARS` permitido en validations; columna `string` para no atarse.
- **Money**: enteros en centavos (`amount_cents`, `declared_value_cents`) por la convención general; `price_per_km` queda como `decimal(10,2)` por su uso natural ("$/km") y porque el issue lo declara como decimal.
- **State machine de `Quote`**: documentada como constante `Quote::ALLOWED_TRANSITIONS` + método predicate `quote.can_transition_to?(:new_status)`. La invocación (`quote.transition_to!(:new_status)`) queda como un método público en el modelo, pero los **callers** que lo disparan (US12 y `QuotePaymentTimeoutJob` de `REQ-BE-00007`) son issues posteriores. Sin gem (`aasm`/`state_machines`) — coherente con la Decisión F del parent plan.

### 2.3 Out of Scope

- Endpoints REST (`POST /api/quote_requests`, `POST /api/quotes/:id/accept`, etc.) — issues posteriores.
- Disparo real de las transiciones de `Quote` (US12 + `REQ-BE-00007`).
- `QuotePaymentTimeoutJob` — vive en `REQ-BE-00007`.
- Persistencia de lat/lng en `transport_windows` y `cargo_offers` — diferida.
- Optimización del scope `matching` (substring naive cubre MVP/demos).
- Auth / Pundit policies sobre estos modelos.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Crear branch `feature/req-be-00021-marketplace-models` desde `main` | Pending | — |
| 2 | Releer issue, parent plan (`REQ-BE-00005`), `domain-model.md` § 3, glossary, plan de `REQ-BE-00020` para confirmar que `carriers.id` y `shippers.id` están persistidos como `bigint` | Pending | — |
| 3 | Agregar `factory_bot_rails`, `faker` al `Gemfile` (group `:development, :test`); `bundle install` | Pending | `backend/Gemfile`, `backend/Gemfile.lock` |
| 4 | Configurar `FactoryBot::Syntax::Methods` en `spec/rails_helper.rb` (include en RSpec.config) | Pending | `backend/spec/rails_helper.rb` |
| 5 | Generar migración `CreateTransportWindows` con todas las columnas + FKs + índices (ver § 4.1) | Pending | `backend/db/migrate/<ts>_create_transport_windows.rb` |
| 6 | Generar migración `CreateCargoOffers` (ver § 4.2) | Pending | `backend/db/migrate/<ts>_create_cargo_offers.rb` |
| 7 | Generar migración `CreateQuotes` (ver § 4.3) | Pending | `backend/db/migrate/<ts>_create_quotes.rb` |
| 8 | Ejecutar `bin/rails db:migrate`; verificar `db/schema.rb` actualizado | Pending | `backend/db/schema.rb` |
| 9 | Crear `app/models/transport_window.rb` (validations + scopes `active`, `matching(...)`) | Pending | `backend/app/models/transport_window.rb` |
| 10 | Crear `app/models/cargo_offer.rb` (validations) | Pending | `backend/app/models/cargo_offer.rb` |
| 11 | Crear `app/models/quote.rb` con `STATES`, `ALLOWED_TRANSITIONS`, predicates, `transition_to!`, scopes `pending`, `expired`, `accepted` | Pending | `backend/app/models/quote.rb` |
| 12 | Agregar `has_many :transport_windows`, `has_many :quotes` en `Carrier` (lo provee `REQ-BE-00020`); agregar `has_many :cargo_offers` en `Shipper`. **Si `REQ-BE-00020` ya las dejó**, verificar `inverse_of`. Si NO, agregarlas como parte de este issue (declarar la dependencia en el commit) | Pending | `backend/app/models/carrier.rb`, `backend/app/models/shipper.rb` |
| 13 | Crear factories: `transport_window`, `cargo_offer`, `quote` (con traits `:pending`, `:accepted`, `:paid`, `:expired`, `:cancelled` para `Quote`) | Pending | `backend/spec/factories/transport_windows.rb`, `cargo_offers.rb`, `quotes.rb` |
| 14 | Extender `db/seeds.rb` para crear 2 `TransportWindow`, 2 `CargoOffer`, 2 `Quote` (escenario mínimo idempotente) | Pending | `backend/db/seeds.rb` |
| 15 | Registrar los tres modelos en ActiveAdmin **read-only** (`actions :index, :show`) con index/show columns y filtros básicos | Pending | `backend/app/admin/transport_windows.rb`, `cargo_offers.rb`, `quotes.rb` |
| 16 | Specs: `transport_window_spec.rb`, `cargo_offer_spec.rb`, `quote_spec.rb` cubriendo validations, asociaciones, scopes, state-machine docstring + predicates | Pending | `backend/spec/models/transport_window_spec.rb`, `cargo_offer_spec.rb`, `quote_spec.rb` |
| 17 | Correr `bundle exec rspec`, verificar ≥80% coverage sobre los 3 nuevos archivos (informativo — no bloqueante de CI hasta que `simplecov` esté configurado en otro issue) | Pending | — |
| 18 | Correr `bin/rails db:seed` localmente; correr `brakeman` y `bundler-audit` (no introducir regresiones) | Pending | — |
| 19 | Mover issue `Backlog/` → `Ready/`; frontmatter `status: ready`, `plan: <path>` | In Progress (este step) | `.gdsi-sdlc/issues/Ready/REQ-BE-00021-...issue.md` |
| 20 | Commit Conventional `chore(plan): create plan for REQ-BE-00021` | Pending | — |

---

## 4. Code Changes

### 4.1 New file: `backend/db/migrate/<ts>_create_transport_windows.rb`

```ruby
class CreateTransportWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :transport_windows do |t|
      t.references :vehicle,
                   null: false,
                   foreign_key: { to_table: :vehicles, on_delete: :cascade } # FK -> vehicles.id (REQ-BE-00020)
      t.string  :origin_zone,      null: false # free string Phase 0/1 (ADR-010)
      t.string  :destination_zone, null: false
      t.decimal :price_per_km,     null: false, precision: 10, scale: 2
      t.integer :max_km,           null: false
      t.datetime :available_from,  null: false
      t.datetime :available_to,    null: false
      t.boolean :active,           null: false, default: true
      t.timestamps
    end

    add_index :transport_windows, :active
    add_index :transport_windows, [:available_from, :available_to]
    add_index :transport_windows, [:vehicle_id, :available_from, :available_to]
    # Lower-cased indexes for matching scope are nice-to-have; SQLite supports
    # expression indexes since 3.9. Defer to a follow-up if matching becomes
    # a hot path.
  end
end
```

**Notes**:

- **No `carrier_id` column** — Carrier is reachable via `transport_window.vehicle.carrier` (orchestrator decision). Avoids the carrier-match-vehicle invariant that denormalisation would require.
- `t.references :vehicle, foreign_key: { ..., on_delete: :cascade }` resolves the FK against `vehicles.id` (Identity, `REQ-BE-00020`). DB-level cascade matches `Vehicle has_many :transport_windows, dependent: :destroy` declared on the AR side. The `Vehicle#before_destroy :ensure_no_active_commitments` guard (also in `REQ-BE-00020`) blocks the destroy if any of the cascading windows backs a non-terminal `Quote`, so financial/audit rows are never silently orphaned.
- Index strategy: `active` is the discriminator for the `active` scope; the `[available_from, available_to]` composite is for window-overlap searches; the `[vehicle_id, available_from, available_to]` composite supports the `no_vehicle_overlap` validation lookup.
- No soft-delete column — ADR-009.

### 4.2 New file: `backend/db/migrate/<ts>_create_cargo_offers.rb`

```ruby
class CreateCargoOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :cargo_offers do |t|
      t.references :shipper, null: false, foreign_key: true # FK -> shippers.id (REQ-BE-00020)
      t.string  :pickup_address,   null: false # free string Phase 0/1 (ADR-010)
      t.string  :delivery_address, null: false
      t.datetime :pickup_date,     null: false
      t.text    :cargo_description, null: false
      t.decimal :weight_kg,        null: false, precision: 10, scale: 2
      t.integer :volume_cm3,       null: false
      t.integer :declared_value_cents, null: false
      t.timestamps
    end

    add_index :cargo_offers, :pickup_date
  end
end
```

**Notes**:

- No `Carrier` FK here — matching happens through `Quote` (per issue + parent plan).
- `weight_kg` is `decimal` to allow fractional kilos; `volume_cm3` is integer.
- `declared_value_cents` is integer cents (project money convention).

### 4.3 New file: `backend/db/migrate/<ts>_create_quotes.rb`

```ruby
class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.references :cargo_offer,      null: false, foreign_key: true
      t.references :carrier,          null: false, foreign_key: true # FK -> carriers.id
      t.references :transport_window, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string  :currency,     null: false, default: "ARS"
      t.string  :status,       null: false, default: "pending"
      t.datetime :expires_at,  null: false
      t.timestamps
    end

    add_index :quotes, :status
    add_index :quotes, :expires_at
    # No unique on (cargo_offer_id, carrier_id) — a carrier may re-quote the
    # same offer after a previous quote was cancelled/expired. Uniqueness lives
    # in the AR validation `validates :cargo_offer_id, uniqueness: { scope: %i[carrier_id], conditions: -> { where(status: %w[pending accepted paid]) } }`
    # so cancelled/expired rows do not block re-quoting.
  end
end
```

**Notes**:

- `transport_window_id` is **NOT NULL** in this MVP — every quote is tied to a published window. The parent `domain-model.md` allows nullable `transport_window_id`; the issue itself lists it without "(nullable)" qualifier and treats it as a required FK. Honoured the issue (decision flagged in § 9).
- `currency` defaults to `ARS`; AR validation restricts to that single value for now.
- `status` defaults to `pending` (entry state).
- No `accepted_at`, `cancelled_at`: `expires_at` covers timeout; transitions are audited via `updated_at` + `TrackingEvent` once `Shipment` exists. `accepted_at` not required by the issue's column list.
- No FK to `Vehicle` on `Quote` — vehicle is pinned at the `TransportWindow` level (`transport_windows.vehicle_id NOT NULL`); reachable from `Quote` via `quote.transport_window.vehicle`. Avoids carrier-match-vehicle denormalisation invariants.

### 4.4 New file: `backend/app/models/transport_window.rb`

```ruby
class TransportWindow < ApplicationRecord
  belongs_to :vehicle, inverse_of: :transport_windows
  has_many :quotes, dependent: :restrict_with_error, inverse_of: :transport_window

  delegate :carrier, to: :vehicle, allow_nil: true   # carrier is reachable, not denormalised

  validates :origin_zone, :destination_zone, presence: true
  validates :price_per_km, numericality: { greater_than: 0 }
  validates :max_km, numericality: { greater_than: 0, only_integer: true }
  validates :available_from, :available_to, presence: true
  validate  :time_window_is_coherent
  validate  :no_vehicle_overlap

  scope :active,  -> { where(active: true) }
  # MVP: case-insensitive substring match on both endpoints.
  # Phase 2: replace with PostGIS / proper geocoded matching (ADR-010).
  scope :matching, ->(origin:, destination:) {
    where("LOWER(origin_zone) LIKE ?", "%#{origin.to_s.downcase}%")
      .where("LOWER(destination_zone) LIKE ?", "%#{destination.to_s.downcase}%")
  }

  private

  def time_window_is_coherent
    return if available_from.blank? || available_to.blank?
    errors.add(:available_to, "must be after available_from") if available_to <= available_from
  end

  # Phase 0/1 guard against double-booking. Two TransportWindows on the same
  # Vehicle whose [available_from, available_to] intervals intersect are not
  # allowed. Race-safe at the application layer only — two parallel inserts can
  # both pass; a Postgres EXCLUDE constraint is the proper fix when we move off
  # SQLite (deferred to Phase 2).
  def no_vehicle_overlap
    return if vehicle_id.blank? || available_from.blank? || available_to.blank?
    overlap = TransportWindow.where(vehicle_id: vehicle_id)
                             .where.not(id: id)
                             .where("available_from < ? AND available_to > ?", available_to, available_from)
    errors.add(:base, "vehicle is already booked in an overlapping window") if overlap.exists?
  end
end
```

### 4.5 New file: `backend/app/models/cargo_offer.rb`

```ruby
class CargoOffer < ApplicationRecord
  belongs_to :shipper, inverse_of: :cargo_offers
  has_many :quotes, dependent: :restrict_with_error, inverse_of: :cargo_offer

  validates :pickup_address, :delivery_address, :cargo_description, presence: true
  validates :weight_kg, numericality: { greater_than: 0 }
  validates :volume_cm3, numericality: { greater_than: 0, only_integer: true }
  validates :declared_value_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :pickup_date, presence: true
end
```

### 4.6 New file: `backend/app/models/quote.rb`

```ruby
class Quote < ApplicationRecord
  # ---------------------------------------------------------------------------
  # State machine — modelled by hand (Decision F of REQ-BE-00005).
  #
  # Diagram:
  #
  #   pending ──► accepted ──► paid
  #     │            │
  #     ├──► expired │
  #     │            └──► cancelled
  #     └──► cancelled
  #
  # Allowed transitions table:
  #
  #   pending   → accepted, expired, cancelled
  #   accepted  → paid, cancelled
  #   paid      → (terminal)
  #   expired   → (terminal)
  #   cancelled → (terminal)
  #
  # Triggers (NOT implemented in this issue — declared here as the contract for
  # downstream callers):
  #   - pending  → accepted: US12 (REQ-BE-00007 / shipper accepts).
  #   - accepted → paid:     REQ-BE-00007 (payment success).
  #   - {pending,accepted} → expired: QuotePaymentTimeoutJob (REQ-BE-00007).
  #   - any → cancelled: shipper / carrier explicit cancel.
  #
  # The transition that signals "ready to be picked up by Fulfilment
  # (REQ-BE-00022)" is `accepted` — that's when Shipment.create!(quote: ...)
  # fires. `paid` does not change Fulfilment state; it only unlocks pickup.
  # ---------------------------------------------------------------------------
  STATES = %w[pending accepted paid expired cancelled].freeze
  TERMINAL_STATES = %w[paid expired cancelled].freeze
  ALLOWED_TRANSITIONS = {
    "pending"   => %w[accepted expired cancelled],
    "accepted"  => %w[paid cancelled],
    "paid"      => [],
    "expired"   => [],
    "cancelled" => []
  }.freeze

  belongs_to :cargo_offer,      inverse_of: :quotes
  belongs_to :carrier,          inverse_of: :quotes
  belongs_to :transport_window, inverse_of: :quotes

  validates :amount_cents, numericality: { greater_than: 0, only_integer: true }
  validates :currency, inclusion: { in: %w[ARS] }
  validates :status,   inclusion: { in: STATES }
  validates :expires_at, presence: true

  scope :pending,   -> { where(status: "pending") }
  scope :accepted,  -> { where(status: "accepted") }
  scope :paid,      -> { where(status: "paid") }
  scope :cancelled, -> { where(status: "cancelled") }
  # `expired` is BOTH a status AND a time-based predicate. Two scopes:
  #   .expired      → rows whose status is the literal "expired"
  #   .past_expiry  → rows whose expires_at has elapsed (regardless of status)
  scope :expired,    -> { where(status: "expired") }
  scope :past_expiry, -> { where("expires_at < ?", Time.current) }

  # Predicate API (used by tests + future transition callers).
  def can_transition_to?(new_status)
    ALLOWED_TRANSITIONS.fetch(status, []).include?(new_status.to_s)
  end

  # Transition entry point. Invocation is the responsibility of US12 and
  # REQ-BE-00007; this method only enforces the table above.
  def transition_to!(new_status)
    new_status = new_status.to_s
    unless can_transition_to?(new_status)
      raise InvalidTransition, "Cannot transition Quote##{id} from #{status.inspect} to #{new_status.inspect}"
    end
    update!(status: new_status)
  end

  class InvalidTransition < StandardError; end
end
```

**Test responsibilities** (§ 5):

- `Quote::STATES`, `TERMINAL_STATES`, `ALLOWED_TRANSITIONS` are present and frozen.
- `can_transition_to?` returns `true` for every allowed pair and `false` for every disallowed pair (matrix-driven test).
- `transition_to!` updates `status` for an allowed transition; raises `InvalidTransition` for a disallowed one.
- Scopes return only the rows they should.

### 4.7 Modified files: `backend/app/models/carrier.rb`, `backend/app/models/shipper.rb`, `backend/app/models/vehicle.rb`

These models live in `REQ-BE-00020`. This plan needs them to expose the inverse associations:

```ruby
# Carrier (transport_windows reached transitively through vehicles):
has_many :transport_windows, through: :vehicles
has_many :quotes,            dependent: :restrict_with_error, inverse_of: :carrier

# Shipper:
has_many :cargo_offers, dependent: :restrict_with_error, inverse_of: :shipper

# Vehicle (declared in 00020, this plan only verifies inverse_of):
has_many :transport_windows, dependent: :destroy, inverse_of: :vehicle
```

Coordination note: `REQ-BE-00020` (after the orchestrator's edits) declares `Vehicle has_many :transport_windows, dependent: :destroy` and the `before_destroy :ensure_no_active_commitments` guard. This plan only verifies the `inverse_of: :vehicle` is set and adds the `Carrier has_many :transport_windows, through: :vehicles` shortcut (and the `Carrier has_many :quotes`, `Shipper has_many :cargo_offers` direct relations).

`dependent: :restrict_with_error` on `Carrier#quotes` and `Shipper#cargo_offers` enforces ADR-009: Identity rows cannot be hard-deleted while Marketplace children exist. The `transport_windows` cascade chain (`Vehicle#destroy` → windows die; live-quote guard blocks the destroy upstream) is the only place a chain delete is allowed.

### 4.8 New files: `backend/spec/factories/{transport_windows,cargo_offers,quotes}.rb`

```ruby
# spec/factories/transport_windows.rb
FactoryBot.define do
  factory :transport_window do
    association :vehicle    # auto-creates Carrier → Vehicle chain via the :vehicle factory
    origin_zone      { "Buenos Aires" }
    destination_zone { "Córdoba" }
    price_per_km     { 1500.50 }
    max_km           { 1200 }
    sequence(:available_from) { |n| (n + 1).days.from_now }
    sequence(:available_to)   { |n| (n + 7).days.from_now }
    active           { true }
  end
end

# spec/factories/cargo_offers.rb
FactoryBot.define do
  factory :cargo_offer do
    association :shipper
    pickup_address       { "Av. Corrientes 1234, CABA" }
    delivery_address     { "Av. Colón 500, Córdoba" }
    pickup_date          { 2.days.from_now }
    cargo_description    { "Pallets de electrodomésticos" }
    weight_kg            { 1500.0 }
    volume_cm3           { 4_000_000 }
    declared_value_cents { 5_000_000 }
  end
end

# spec/factories/quotes.rb
FactoryBot.define do
  factory :quote do
    association :cargo_offer
    association :carrier
    association :transport_window
    amount_cents { 2_500_000 }
    currency     { "ARS" }
    status       { "pending" }
    expires_at   { 24.hours.from_now }

    trait(:pending)   { status { "pending" } }
    trait(:accepted)  { status { "accepted" } }
    trait(:paid)      { status { "paid" } }
    trait(:expired)   { status { "expired" } }
    trait(:cancelled) { status { "cancelled" } }
  end
end
```

### 4.9 Modified file: `backend/db/seeds.rb`

Append (after the existing AdminUser block, **only when the dependent Identity rows already exist** — the seed lives idempotent):

```ruby
# --- Marketplace seed (REQ-BE-00021) ----------------------------------------
# Requires that REQ-BE-00020 seeds have created at least one Carrier with one
# Vehicle and at least one Shipper. Skip silently if the seed run is being
# executed before Identity is seeded (defensive — keeps `db:seed` re-runnable
# during incremental development).

if defined?(Carrier) && defined?(Shipper) && Carrier.any? && Shipper.any? && Vehicle.any?
  carrier = Carrier.first
  shipper = Shipper.first
  vehicle = carrier.vehicles.first   # REQ-BE-00020 seeds 1 Vehicle per Carrier

  tw1 = TransportWindow.find_or_create_by!(vehicle:, origin_zone: "Buenos Aires", destination_zone: "Córdoba") do |w|
    w.price_per_km   = 1500.0
    w.max_km         = 1200
    w.available_from = 1.day.from_now
    w.available_to   = 10.days.from_now
    w.active         = true
  end

  tw2 = TransportWindow.find_or_create_by!(vehicle:, origin_zone: "Rosario", destination_zone: "Mendoza") do |w|
    w.price_per_km   = 1700.0
    w.max_km         = 900
    w.available_from = 11.days.from_now   # disjoint from tw1 — no overlap
    w.available_to   = 18.days.from_now
    w.active         = true
  end

  co1 = CargoOffer.find_or_create_by!(shipper:, cargo_description: "Pallets de granos") do |c|
    c.pickup_address       = "Puerto de Buenos Aires"
    c.delivery_address     = "Av. Sabattini 5500, Córdoba"
    c.pickup_date          = 3.days.from_now
    c.weight_kg            = 12_000.0
    c.volume_cm3           = 30_000_000
    c.declared_value_cents = 150_000_000
  end

  co2 = CargoOffer.find_or_create_by!(shipper:, cargo_description: "Materiales de construcción") do |c|
    c.pickup_address       = "Parque industrial Rosario"
    c.delivery_address     = "Godoy Cruz 1200, Mendoza"
    c.pickup_date          = 4.days.from_now
    c.weight_kg            = 8_500.0
    c.volume_cm3           = 18_000_000
    c.declared_value_cents = 90_000_000
  end

  Quote.find_or_create_by!(cargo_offer: co1, carrier:, transport_window: tw1) do |q|
    q.amount_cents = 18_000_000
    q.currency     = "ARS"
    q.status       = "pending"
    q.expires_at   = 24.hours.from_now
  end

  Quote.find_or_create_by!(cargo_offer: co2, carrier:, transport_window: tw2) do |q|
    q.amount_cents = 15_300_000
    q.currency     = "ARS"
    q.status       = "pending"
    q.expires_at   = 24.hours.from_now
  end
end
```

Re-runs are safe: `find_or_create_by!` is keyed on the natural-uniqueness columns; secondary attributes are only set on creation.

### 4.10 New files: `backend/app/admin/{transport_windows,cargo_offers,quotes}.rb`

```ruby
# app/admin/transport_windows.rb
ActiveAdmin.register TransportWindow do
  actions :index, :show
  filter :vehicle
  filter :origin_zone
  filter :destination_zone
  filter :active
  filter :available_from
  filter :available_to

  index do
    selectable_column
    id_column
    column :vehicle
    column(:carrier) { |tw| tw.carrier }   # delegated, read-only
    column :origin_zone
    column :destination_zone
    column :price_per_km
    column :max_km
    column :active
    column :available_from
    column :available_to
    actions
  end

  show do
    attributes_table_for resource do
      row :id
      row :carrier
      row :origin_zone
      row :destination_zone
      row :price_per_km
      row :max_km
      row :active
      row :available_from
      row :available_to
      row :created_at
      row :updated_at
    end
  end
end

# app/admin/cargo_offers.rb
ActiveAdmin.register CargoOffer do
  actions :index, :show
  filter :shipper
  filter :pickup_date
  filter :weight_kg
  index do
    id_column
    column :shipper
    column :pickup_address
    column :delivery_address
    column :pickup_date
    column :weight_kg
    column :volume_cm3
    column :declared_value_cents
    actions
  end
end

# app/admin/quotes.rb
ActiveAdmin.register Quote do
  actions :index, :show
  filter :cargo_offer
  filter :carrier
  filter :status, as: :select, collection: Quote::STATES
  filter :expires_at
  index do
    id_column
    column :cargo_offer
    column :carrier
    column :transport_window
    column :amount_cents
    column :currency
    column :status
    column :expires_at
    actions
  end
end
```

`actions :index, :show` enforces read-only (no `new`/`edit`/`destroy` routes generated). Aligns with the AC and with how `INF-BE-00003` exposed `AdminUser`.

### 4.11 Modified file: `backend/spec/rails_helper.rb`

Add (idempotent — the file already exists from `rspec-rails` install):

```ruby
RSpec.configure do |config|
  # ...existing config...
  config.include FactoryBot::Syntax::Methods
end
```

### 4.12 New files: `backend/spec/models/{transport_window,cargo_offer,quote}_spec.rb`

`transport_window_spec.rb`:

- valid factory builds.
- presence: `origin_zone`, `destination_zone`, `available_from`, `available_to`.
- `price_per_km` > 0; `max_km` > 0.
- `available_to > available_from` (custom validator).
- scope `active` only returns `active: true`.
- scope `matching("Aires", "Cordoba")` returns substring matches case-insensitively; rejects non-matches.
- association `belongs_to :vehicle`; `delegate :carrier, to: :vehicle` returns the vehicle's carrier; `has_many :quotes`.
- **`no_vehicle_overlap` validation**: covers identical, partial, edge-touching (boundary equality), and fully-disjoint window pairs. Two windows on different vehicles with the same time interval MUST be allowed.

`cargo_offer_spec.rb`:

- valid factory; presence of all required strings; numericality of `weight_kg`, `volume_cm3`, `declared_value_cents`.
- `belongs_to :shipper`; `has_many :quotes`.

`quote_spec.rb`:

- valid factory.
- numericality + inclusion validations (`amount_cents > 0`, `currency = "ARS"`, `status ∈ STATES`, `expires_at` present).
- scopes `pending`, `accepted`, `paid`, `cancelled`, `expired`, `past_expiry`.
- **State machine table-driven test** — generate every `(from, to)` pair from `Quote::STATES²` and assert `can_transition_to?` matches `ALLOWED_TRANSITIONS`. This is the contract test for downstream callers.
- `transition_to!` happy path: pending → accepted updates status.
- `transition_to!` rejection: paid → accepted raises `Quote::InvalidTransition`.
- Terminal states reject ALL transitions.

---

## 5. Testing

### 5.1 Automated

```sh
cd backend
bundle exec rspec spec/models/transport_window_spec.rb \
                  spec/models/cargo_offer_spec.rb \
                  spec/models/quote_spec.rb
```

Coverage target ≥80% on `app/models/{transport_window,cargo_offer,quote}.rb`. Until `simplecov` is wired (separate issue), the requirement is satisfied by line-level reading: every public method + every validation + every scope must have at least one example.

### 5.2 Manual

```sh
bin/rails db:migrate
bin/rails db:seed                # idempotent
bin/rails console
# > TransportWindow.active.count   # ≥ 2
# > TransportWindow.matching(origin: "aires", destination: "cordoba").count
# > Quote.pending.count            # ≥ 2
# > q = Quote.pending.first; q.transition_to!("accepted"); q.status # => "accepted"
# > q.transition_to!("paid"); q.status                              # => "paid"
# > q.transition_to!("accepted")                                    # raises InvalidTransition
```

### 5.3 ActiveAdmin smoke

`bin/rails server` → log in to `/admin` → the three new resources render in the side nav with `Index` + `Show` only (no `New` button). No 500s.

---

## 6. Acceptance Criteria

### 6.1 Mirror of issue checklist (verbatim)

- [ ] Migraciones aplicadas para `transport_windows`, `cargo_offers`, `quotes`.
- [ ] Modelos AR con validaciones + asociaciones + scopes documentados.
- [ ] State machine de `Quote` documentada en el modelo (constants + transition table).
- [ ] ActiveAdmin lista los tres modelos read-only.
- [ ] Factories + seeds funcionan.
- [ ] Model specs ≥80% coverage.
- [ ] Identifiers en inglés.

### 6.2 Plan-derived (additive)

- [ ] `Quote::ALLOWED_TRANSITIONS` is `frozen` and matches the table in § 4.6.
- [ ] `Quote#transition_to!` raises `Quote::InvalidTransition` (a `StandardError` subclass, not a generic `RuntimeError`) on invalid transitions.
- [ ] `TransportWindow.matching(origin:, destination:)` is case-insensitive substring match (MVP).
- [ ] **`transport_windows.vehicle_id` is `NOT NULL` with FK `on_delete: :cascade`**. No `carrier_id` column on `transport_windows` (Carrier reachable via `vehicle.carrier`).
- [ ] **`TransportWindow#no_vehicle_overlap` validation rejects intervals that intersect another window on the same Vehicle**, while permitting two windows on different Vehicles with the same interval.
- [ ] `factory_bot_rails` and `faker` are listed in `Gemfile` group `:development, :test`.
- [ ] `db:seed` is idempotent: running it twice does NOT create duplicates.
- [ ] `bundle exec rspec` exits 0 on a fresh `db:test:prepare`.
- [ ] `app/admin/{transport_windows,cargo_offers,quotes}.rb` declare `actions :index, :show` (read-only).
- [ ] No new soft-delete columns introduced (ADR-009 boundary respected).
- [ ] Glossary identifiers used unchanged: `TransportWindow`, `CargoOffer`, `Quote`, `transport_windows`, `cargo_offers`, `quotes`.

### 6.3 Out of scope (deliberate — rejected as ACs)

- Endpoints REST around these models.
- Real invocation of state-machine transitions from controllers / jobs.
- PostGIS / geocoded matching.
- `Quote.vehicle_id` — Vehicle is pinned at the `TransportWindow` level (orchestrator decision); reachable from `Quote` via `quote.transport_window.vehicle`.

---

## 7. Cross-plan coordination contract

This section is the binding interface between this plan and its siblings. Sibling planners (00020 Identity upstream, 00022 Fulfilment downstream) MUST quote the relevant subsection.

### 7.1 Upstream contract (consumed from `REQ-BE-00020` Identity)

| Item | Assumed value | Reasoning |
|------|---------------|-----------|
| `carriers.id` PK type | `bigint` | ADR-007 (Rails default). |
| `shippers.id` PK type | `bigint` | ADR-007. |
| `vehicles.id` PK type | `bigint` | ADR-007. |
| `carriers` soft-delete | **None** (hard-delete) | ADR-009 — soft-delete only on `Shipment`/`Payment`/`ArcaInvoice`. |
| `shippers` soft-delete | **None** (hard-delete) | ADR-009. |
| `vehicles` soft-delete | **None** (hard-delete) | ADR-009. |
| `Carrier has_many :vehicles` | Yes (1:N from day one) | Orchestrator decision; supersedes `REQ-BE-00010`. |
| `Vehicle has_many :transport_windows, dependent: :destroy` | Declared in `REQ-BE-00020` | Cascade chain. |
| `Vehicle#before_destroy :ensure_no_active_commitments` | Declared in `REQ-BE-00020` | Blocks vehicle delete when any of its windows backs a non-terminal `Quote`. |
| `Carrier` / `Shipper` / `Vehicle` AR models | `app/models/{carrier,shipper,vehicle}.rb`, expose `belongs_to :user` (or `:carrier` for Vehicle) | Per `domain-model.md` § 2 + REQ-BE-00020 plan. |
| Inverse associations (`Vehicle#transport_windows` direct, `Carrier#transport_windows, through: :vehicles`, `Carrier#quotes`, `Shipper#cargo_offers`) | Vehicle's direct one is added by 00020; this issue adds the `through` shortcut on `Carrier` and the direct ones on `Carrier`/`Shipper` | See Task 12 of § 3. |

If 00020 deviates from any of the above (e.g. UUIDs instead of bigint, or different model file path), THIS plan must be re-aligned before implementation begins.

### 7.2 Downstream contract (provided to `REQ-BE-00022` Fulfilment)

This is the API surface that `REQ-BE-00022`'s `Shipment` model will consume. Quote it verbatim.

| Item | Value |
|------|-------|
| Final table name | `quotes` |
| `quotes.id` PK type | `bigint` (ADR-007) |
| Soft-delete (`discarded_at`) on `quotes` | **No** (hard-delete; ADR-009). `cancelled` is a `status` value, not a deletion marker. |
| FK from `Shipment` | `shipments.quote_id : bigint NOT NULL UNIQUE` references `quotes.id` |
| `Quote` state values | `pending`, `accepted`, `paid`, `expired`, `cancelled` |
| State that signals "ready to be picked up by Fulfilment" | `accepted` — that is the transition that triggers `Shipment.create!(quote: self)` (or equivalent factory). `paid` is downstream of acceptance and does NOT change Fulfilment state; it only unlocks pickup eligibility (the `accepted → in_transit` Shipment transition). |
| State machine constant | `Quote::ALLOWED_TRANSITIONS` (a frozen `Hash[String → Array[String]]`) |
| Transition method | `Quote#transition_to!(new_status)` — raises `Quote::InvalidTransition` on invalid input |
| Transition predicate | `Quote#can_transition_to?(new_status)` — returns `Boolean` |
| Terminal states | `Quote::TERMINAL_STATES = %w[paid expired cancelled].freeze` |
| `Quote` columns relied on by 00022 | `id`, `cargo_offer_id`, `carrier_id`, `transport_window_id`, `amount_cents`, `currency`, `status`, `expires_at` |
| `Quote` does NOT have | `vehicle_id`, `accepted_at`, `cancelled_at`, `discarded_at` (see § 9) |

`REQ-BE-00022` must NOT call `quote.transition_to!("paid")` from within `Shipment#accept!` — that transition lives in `REQ-BE-00007`. The Fulfilment plan should declare `Shipment.create!(quote:, ...)` against an *already-`accepted`* `Quote` (validation: `quote.status == "accepted"`).

---

## 8. Files Summary

### New Files

| File | Description |
|------|-------------|
| `docs/features/REQ/REQ-BE-00021/REQ-BE-00021-implementar-contexto-marketplace.plan.md` | This plan. |
| `backend/db/migrate/<ts>_create_transport_windows.rb` | Marketplace migration 1/3. |
| `backend/db/migrate/<ts>_create_cargo_offers.rb` | Marketplace migration 2/3. |
| `backend/db/migrate/<ts>_create_quotes.rb` | Marketplace migration 3/3. |
| `backend/app/models/transport_window.rb` | AR model (validations + scopes `active`, `matching`). |
| `backend/app/models/cargo_offer.rb` | AR model. |
| `backend/app/models/quote.rb` | AR model + state-machine docs + `transition_to!`. |
| `backend/app/admin/transport_windows.rb` | ActiveAdmin read-only resource. |
| `backend/app/admin/cargo_offers.rb` | Idem. |
| `backend/app/admin/quotes.rb` | Idem. |
| `backend/spec/factories/transport_windows.rb` | Factory. |
| `backend/spec/factories/cargo_offers.rb` | Factory. |
| `backend/spec/factories/quotes.rb` | Factory + traits per state. |
| `backend/spec/models/transport_window_spec.rb` | Model spec. |
| `backend/spec/models/cargo_offer_spec.rb` | Model spec. |
| `backend/spec/models/quote_spec.rb` | Model spec including matrix-driven state-machine test. |

### Modified Files

| File | Changes |
|------|---------|
| `backend/Gemfile` | Add `factory_bot_rails`, `faker` to `:development, :test`. |
| `backend/Gemfile.lock` | Resolved by `bundle install`. |
| `backend/db/schema.rb` | Updated by `db:migrate` — three new tables. |
| `backend/db/seeds.rb` | Append idempotent Marketplace seed (2 windows, 2 offers, 2 quotes). |
| `backend/spec/rails_helper.rb` | `config.include FactoryBot::Syntax::Methods`. |
| `backend/app/models/carrier.rb` | `has_many :transport_windows`, `has_many :quotes` (touch-back if not added by 00020). |
| `backend/app/models/shipper.rb` | `has_many :cargo_offers` (touch-back if not added by 00020). |
| `.gdsi-sdlc/issues/Backlog/REQ-BE-00021-...issue.md` → `Ready/` | Frontmatter `status: ready`, `plan:` pointer. |

### Out of Scope (deliberate)

| File | Reason |
|------|--------|
| `app/controllers/api/quotes_controller.rb` | Endpoints belong to feature issues. |
| `app/jobs/quote_payment_timeout_job.rb` | Lives in `REQ-BE-00007`. |
| `app/models/shipment.rb` | `REQ-BE-00022`. |

---

## 9. Decisions where the parent plan was ambiguous (flag list)

These are the points where this plan had to choose between the issue's explicit columns and the parent design's (`REQ-BE-00005` / `domain-model.md`) more elaborate post-review schema. The issue won in every case, but the deltas are listed so the orchestrator can decide whether to round-trip them into `domain-model.md`.

1. **`Quote.vehicle_id`** — `domain-model.md` § 3.3 had this post-review NOT NULL. **Resolved by orchestrator: vehicle is pinned at the `TransportWindow` level** (`transport_windows.vehicle_id NOT NULL`); `Quote` does NOT carry a `vehicle_id` column because `quote.transport_window.vehicle` already gives the truck. No denormalised vehicle on `Shipment` either.
2. **`Quote.transport_window_id` nullability** — domain-model says nullable; issue lists it as a regular FK. **This plan migrates it as `NOT NULL`** following the issue. If demos need "quote without a window", relax in a follow-up.
3. **`Quote.amount_cents` vs `price_cents`** — `domain-model.md` § 3.3 uses `price_cents`; the issue uses `amount_cents`. **This plan uses `amount_cents`** (issue wins, project money convention preserved).
4. **`TransportWindow` lat/lng + `vehicle_id`** — domain-model adds them. **`vehicle_id` IS persisted (orchestrator decision)** — every TransportWindow hard-links to a specific Vehicle (a Carrier cannot publish a window for a truck they have not registered). Lat/lng remain deferred per ADR-010 (free strings for Phase 0/1).
5. **`CargoOffer` lat/lng + `goods_description` rename** — domain-model uses different column names. **This plan uses the issue's column names exactly** (`pickup_address`, `delivery_address`, `cargo_description`, `weight_kg`, `volume_cm3`, `declared_value_cents`).
6. **Soft-delete on `quotes`** — neither side wants it (ADR-009). Cancellation is a status, not a tombstone. Confirmed in the downstream contract.
7. **`accepted_at` / `cancelled_at` columns** — not in the issue, not in this plan. Audit relies on `updated_at` + `TrackingEvent` (the latter created by 00022 at the `quoted → accepted` transition of `Shipment`).
8. **State-machine cancellation rules** — both `pending` and `accepted` may transition to `cancelled` (refund / no-op semantics defer to `REQ-BE-00007`). Terminal states (`paid`, `expired`, `cancelled`) reject all transitions.

No contradictions found that block planning. All deltas are additive; the issue's column set is a strict subset of the parent design.

---

## 10. Notes for Implementer

- **Branch off `main`** at the same commit `REQ-BE-00020` branched from, to keep the merge order linear (00020 → 00021 → 00022).
- **Migration order matters**: `transport_windows` and `cargo_offers` must exist before `quotes` (FKs). Generate timestamps in the right sequence.
- **Bundle**: after editing `Gemfile`, run `bundle install` and commit `Gemfile.lock` separately — keeps the diff reviewable.
- **ActiveAdmin Sass**: AA's `app/assets/stylesheets/active_admin.scss` already exists from `INF-BE-00003`. No new asset wiring needed.
- **No-op specs are OK** — but `pending` examples are not. Every example in `quote_spec.rb` must execute; the matrix-driven test catches regressions in `ALLOWED_TRANSITIONS` for free.
- **CHANGELOG**: this issue is internal; the user-facing CHANGELOG entry comes with the first feature issue that exposes these models via API. Do NOT add a CHANGELOG entry here.
- **Conventional Commit** for the implementation PR: `feat(marketplace): add TransportWindow, CargoOffer, Quote with state machine`. The plan-creation commit (this step) uses `chore(plan): create plan for REQ-BE-00021` per the orchestrator's instruction.
- **PR**: when the implementation PR is opened (separate from this plan commit), use `gh pr create --assignee @me`.
