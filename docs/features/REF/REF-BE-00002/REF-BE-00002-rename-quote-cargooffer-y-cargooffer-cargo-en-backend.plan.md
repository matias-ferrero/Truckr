# REF-BE-00002: Rename `Quote → CargoOffer` y `CargoOffer → Cargo` en el backend

| Field | Value |
|-------|-------|
| **Tag** | REF-BE-00002 |
| **Title** | Rename Quote → CargoOffer y CargoOffer → Cargo en el backend (modelos, tablas, AA, specs, seeds) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-19 |
| **Updated** | 2026-05-19 |
| **Author** | Claude Code |
| **Depends On** | PR #193 merge resolution (split `POST /api/quotes` → `POST /api/cargos` + `POST /api/cargos/:id/offers`) |
| **Decision Doc** | N/A — single mechanical approach, no architectural alternatives |
| **Selected Approach** | N/A |

---

## 1. Problem Statement

PR #134 (REQ-BE-00021, Done) shipó AR models `Quote`, `CargoOffer`, `Shipment`, `Vehicle`, `TransportWindow` con la nomenclatura vieja del marketplace. Tras la sesión de grilling del 2026-05-19, el dominio se renombró: el bid del Shipper pasa de `Quote` a `CargoOffer`, y la publicación pasa de `CargoOffer` a `Cargo`. Las docs (`domain-model.md`, `glossary.md`, ERD, `backlog-us.typ`) ya reflejan los nombres nuevos. La schema real del backend sigue con los nombres viejos. Resultado: 7+ issues de Backlog (REQ-FE-00015/17/18, REQ-BE-00024/07/08/06) están reescritos con AC que asumen `CargoOffer` = bid y `Cargo` = publicación, y al implementarlos producirían código que no compila contra `db/schema.rb`.

Esta REF cierra ese delta en una sola PR: rename mecánico de modelos, migrations de rename (no edit in place de las migrations originales), AA, specs, factories, seeds, y el FSM `Shipment.quoted → Shipment.offered`.

---

## 2. Solution Design

### Approach

Rename mecánico en una sola PR backend-only, ejecutado en este orden:

1. **Migrations primero** — generar nuevas migrations de `rename_table` + `rename_column` que dejen la schema con los nombres nuevos (`cargos`, `cargo_offers` con la semántica nueva). Las migrations originales del 2026-05-09 quedan intactas (history immutable: shippearon en `main` por PR #134).
2. **Modelos** — renombrar archivos y clases AR. Actualizar `belongs_to`/`has_many` en `Shipment`, `Carrier`, `Shipper`, `TransportWindow`, `Vehicle`.
3. **ActiveAdmin** — renombrar archivos y `permit_params` / filtros / columnas.
4. **Specs + factories** — renombrar archivos, factory names, secuencias, traits.
5. **Seeds** — reescribir contra la semántica nueva (publicaciones + bids con composición Window+Cargo, incluyendo caso parallel-offers).
6. **FSM `Shipment.quoted → Shipment.offered`** — enum + ALLOWED_TRANSITIONS + CHECK constraint + factory trait + TrackingEvent default + data migration en una migration separada.

### Migration sequencing (sub-decision)

Hay dos formas de hacer el swap de nombres sin colisión:

- **(A) Triple-rename con alias temporal**: `rename_table :quotes, :cargo_offers_tmp` → `rename_table :cargo_offers, :cargos` → `rename_table :cargo_offers_tmp, :cargo_offers`. 3 statements en una migration. Simple, atómico.
- **(B) Rename en migrations separadas**: una migration por rename. Más reversible.

Elegimos **(A)**: una sola migration de schema-swap. Más fácil de razonar y la transacción de DDL de SQLite los aplica atómicamente (SQLite soporta DDL transaccional desde la 3.x).

### FSM rename: `quoted → offered`

El estado intermedio del `Shipment` se renombra por consistencia léxica con el dominio renombrado (decisión locked, continue.md "Open threads"). Implica:

- `Shipment::STATUSES`: reemplazar `"quoted"` por `"offered"`.
- `ALLOWED_TRANSITIONS`: rename de la key y del set fuente.
- CHECK constraint en `shipments.status`: drop + recreate con `'offered'` en lugar de `'quoted'`.
- Data migration: `UPDATE shipments SET status = 'offered' WHERE status = 'quoted'`.
- `TrackingEvent`: `from_status`/`to_status` son strings libres, no enum constrained — pero el factory default y los specs los pinean. Update factory `to_status { "offered" }`, y emit data migration sobre `tracking_events` (en la misma migration).
- Spec rename en `shipment_spec.rb` (ALLOWED_TRANSITIONS matrix, lifecycle tests).
- Factory `shipments.rb` trait `:quoted` → `:offered`.

### What does NOT change

- `Vehicle` no tiene FK directa a Quote/CargoOffer. `#ensure_no_active_commitments` referencia Quote vía la cadena `transport_windows.quotes.active` — esa cadena se renombra mecánicamente a `transport_windows.cargo_offers.active` cuando se actualicen las asociaciones.
- `TransportWindow.status` enum (`open / pending_offer / reserved / closed`) NO existe todavía como columna — solo hay flag booleano `active`. Esta REF NO lo agrega; la implementación de US7/US27 lo hará.
- Routes (`config/routes.rb`) no se tocan — no hay endpoints API de Quote/CargoOffer/Shipment en `main`. PR #193 los introducirá con los nombres nuevos.
- Frontend está en landing-page-only — no hay tipos TS del dominio. Out of scope.

### Sequencing constraint

Esta issue **bloquea en la resolución de PR #193**. Razón: #193 layered `POST /api/quotes` (controller + routes + request specs) sobre la nomenclatura vieja. Doing el rename mientras #193 está abierta crearía un 3-way conflict entre (a) main, (b) #193, (c) este branch. Ruta correcta:

1. Request-changes en #193 → split en `POST /api/cargos` + `POST /api/cargos/:id/offers` (sobre nomenclatura vieja sigue aceptable porque los archivos no van a colisionar — paths nuevos, files nuevos).
2. #193 mergea.
3. Esta REF arranca y renombra los modelos + tablas + AA + specs + seeds + FSM. Los controllers nuevos de #193 ya están con los nombres correctos, así que esta REF solo tiene que ajustar referencias internas a `CargoOffer` (la nueva clase) — sin colisión.

Si #193 termina cerrándose (no split-and-merge) y se reabre desde cero, esta REF puede arrancar inmediatamente — no hay nada que conflict en `main`.

---

## 3. Implementation Tasks

| #  | Task                                                                                                       | Status  | Files                                                                                                            |
|----|------------------------------------------------------------------------------------------------------------|---------|------------------------------------------------------------------------------------------------------------------|
| 1  | Crear migration `rename_marketplace_tables` (triple-rename atómico)                                        | Pending | `backend/db/migrate/<TS>_rename_marketplace_tables.rb` (new)                                                     |
| 2  | Crear migration `rename_shipment_quote_fk` (`shipments.quote_id → cargo_offer_id` + rename FK constraint)  | Pending | `backend/db/migrate/<TS+1>_rename_shipment_quote_fk.rb` (new)                                                     |
| 3  | Crear migration `rename_shipment_quoted_state` (enum + CHECK + data migration en `shipments` + `tracking_events`) | Pending | `backend/db/migrate/<TS+2>_rename_shipment_quoted_state.rb` (new)                                                |
| 4  | Renombrar `app/models/quote.rb` → `app/models/cargo_offer.rb` (class `CargoOffer` con la lógica del bid)   | Pending | `backend/app/models/quote.rb` (delete), `backend/app/models/cargo_offer.rb` (replace contents)                   |
| 5  | Renombrar `app/models/cargo_offer.rb` (viejo) → `app/models/cargo.rb` (class `Cargo` con la lógica de la publicación) | Pending | `backend/app/models/cargo.rb` (new, ex-contents of old cargo_offer.rb)                                          |
| 6  | Actualizar asociaciones en `Shipment`, `Carrier`, `Shipper`, `TransportWindow`, `Vehicle`                  | Pending | `backend/app/models/{shipment,carrier,shipper,transport_window,vehicle}.rb`                                      |
| 7  | Renombrar `app/admin/quotes.rb` → `app/admin/cargo_offers.rb` (registra `CargoOffer`)                      | Pending | `backend/app/admin/quotes.rb` (delete), `backend/app/admin/cargo_offers.rb` (replace contents)                   |
| 8  | Renombrar `app/admin/cargo_offers.rb` (viejo) → `app/admin/cargos.rb` (registra `Cargo`)                   | Pending | `backend/app/admin/cargos.rb` (new)                                                                              |
| 9  | Actualizar `app/admin/shipments.rb` (permit_params, filtros, index, show, form)                            | Pending | `backend/app/admin/shipments.rb`                                                                                 |
| 10 | Renombrar `spec/models/quote_spec.rb` → `spec/models/cargo_offer_spec.rb`                                  | Pending | `backend/spec/models/quote_spec.rb` (delete), `backend/spec/models/cargo_offer_spec.rb` (replace)                |
| 11 | Renombrar `spec/models/cargo_offer_spec.rb` (viejo) → `spec/models/cargo_spec.rb`                          | Pending | `backend/spec/models/cargo_spec.rb` (new)                                                                        |
| 12 | Actualizar `spec/models/shipment_spec.rb` (associations + STATUSES `quoted→offered` + ALLOWED_TRANSITIONS) | Pending | `backend/spec/models/shipment_spec.rb`                                                                           |
| 13 | Renombrar `spec/factories/quotes.rb` → `spec/factories/cargo_offers.rb`                                    | Pending | `backend/spec/factories/quotes.rb` (delete), `backend/spec/factories/cargo_offers.rb` (replace)                  |
| 14 | Renombrar `spec/factories/cargo_offers.rb` (viejo) → `spec/factories/cargos.rb`                            | Pending | `backend/spec/factories/cargos.rb` (new)                                                                         |
| 15 | Actualizar `spec/factories/shipments.rb` (`association :quote → :cargo_offer`, trait `:quoted → :offered`) | Pending | `backend/spec/factories/shipments.rb`                                                                            |
| 16 | Actualizar `spec/factories/tracking_events.rb` (`to_status "quoted" → "offered"`)                          | Pending | `backend/spec/factories/tracking_events.rb`                                                                      |
| 17 | Actualizar `spec/requests/admin/crud_spec.rb` (paths admin + factory symbols)                              | Pending | `backend/spec/requests/admin/crud_spec.rb`                                                                       |
| 18 | Reescribir `db/seeds.rb` (Cargo publicaciones + CargoOffer bids con composición Window+Cargo + caso parallel-offers) | Pending | `backend/db/seeds.rb`                                                                                            |
| 19 | Correr `bin/rails db:migrate` en dev y verificar `db/schema.rb` regenerado (`cargos`, `cargo_offers`, `shipments.cargo_offer_id`, CHECK con `'offered'`) | Pending | `backend/db/schema.rb` (regen)                                                                                   |
| 20 | Correr `bundle exec rspec` y verificar verde                                                               | Pending | —                                                                                                                |
| 21 | Smoke manual `/admin/cargos`, `/admin/cargo_offers`, `/admin/shipments` en dev                             | Pending | —                                                                                                                |
| 22 | `grep -rn '\bQuote\b\|quote_id\|:quote\b\|"quoted"\|:quoted\b' backend/{app,db,spec,config}` → cero hits del dominio viejo | Pending | —                                                                                                                |
| 23 | `bundle exec rubocop`, `bundle exec brakeman`, `bundle exec bundle-audit` verdes                           | Pending | —                                                                                                                |

---

## 4. Code Changes

### 4.1 Migration: `rename_marketplace_tables`

**Purpose**: Swap nombres de tabla atómicamente. `quotes` pasa a ser `cargo_offers` (nuevo bid); el viejo `cargo_offers` pasa a ser `cargos` (publicación).

```ruby
class RenameMarketplaceTables < ActiveRecord::Migration[8.0]
  def change
    # Triple-rename con alias para evitar colisión:
    # 1) sacar el nombre 'cargo_offers' del medio
    rename_table :cargo_offers, :cargos
    # 2) Quote pasa a ocupar 'cargo_offers'
    rename_table :quotes, :cargo_offers
    # Re-nombrar índices y FK constraints si Rails no los renombró automáticamente.
    # Verificar post-migrate: `\d cargo_offers` en sqlite muestra los índices con nombres viejos.
    rename_index :cargo_offers, "index_quotes_on_status", "index_cargo_offers_on_status" if index_name_exists?(:cargo_offers, "index_quotes_on_status")
    rename_index :cargo_offers, "index_quotes_on_expires_at", "index_cargo_offers_on_expires_at" if index_name_exists?(:cargo_offers, "index_quotes_on_expires_at")
  end
end
```

### 4.2 Migration: `rename_shipment_quote_fk`

**Purpose**: Renombrar la FK `shipments.quote_id → cargo_offer_id` y su índice único.

```ruby
class RenameShipmentQuoteFk < ActiveRecord::Migration[8.0]
  def change
    rename_column :shipments, :quote_id, :cargo_offer_id
    # rename_column en Rails 8 + SQLite también renombra el índice asociado en la mayoría de casos;
    # si no, hacer rename_index explícito:
    rename_index :shipments, "index_shipments_on_quote_id", "index_shipments_on_cargo_offer_id" if index_name_exists?(:shipments, "index_shipments_on_quote_id")
  end
end
```

### 4.3 Migration: `rename_shipment_quoted_state`

**Purpose**: Renombrar el estado `quoted → offered` en el enum `Shipment.status`, su CHECK constraint, y la columna `to_status`/`from_status` de TrackingEvent.

```ruby
class RenameShipmentQuotedState < ActiveRecord::Migration[8.0]
  def up
    # 1) Drop CHECK viejo (SQLite no soporta DROP CONSTRAINT directo; usar remove_check_constraint si está en el namespace de Rails)
    remove_check_constraint :shipments, name: "shipments_status_check" if check_constraint_exists?(:shipments, name: "shipments_status_check")

    # 2) Data migration: shipments
    execute "UPDATE shipments SET status = 'offered' WHERE status = 'quoted'"

    # 3) Data migration: tracking_events (from_status y to_status son strings libres)
    execute "UPDATE tracking_events SET from_status = 'offered' WHERE from_status = 'quoted'"
    execute "UPDATE tracking_events SET to_status = 'offered' WHERE to_status = 'quoted'"

    # 4) Recrear CHECK con el set nuevo de estados
    add_check_constraint :shipments,
      "status IN ('draft','offered','accepted','in_transit','delivered','settled','cancelled')",
      name: "shipments_status_check"
  end

  def down
    remove_check_constraint :shipments, name: "shipments_status_check"
    execute "UPDATE tracking_events SET to_status = 'quoted' WHERE to_status = 'offered'"
    execute "UPDATE tracking_events SET from_status = 'quoted' WHERE from_status = 'offered'"
    execute "UPDATE shipments SET status = 'quoted' WHERE status = 'offered'"
    add_check_constraint :shipments,
      "status IN ('draft','quoted','accepted','in_transit','delivered','settled','cancelled')",
      name: "shipments_status_check"
  end

  private

  def check_constraint_exists?(table, name:)
    connection.check_constraints(table).any? { |c| c.options[:name] == name }
  end
end
```

> **Note on SQLite CHECK constraints**: SQLite re-creates the table on certain `ALTER`s; Rails 8's `add_check_constraint` / `remove_check_constraint` handle the rebuild. Verificar en dev que el resultado en `schema.rb` tenga el CHECK con `'offered'`. Si el helper `check_constraint_exists?` falla (privacy de API entre versiones de Rails), reemplazar por un `begin/rescue` o por una consulta a `sqlite_master`.

### 4.4 `app/models/cargo_offer.rb` (nuevo — ex-`quote.rb`)

**Purpose**: Class `CargoOffer` con la lógica del bid (validations, FSM `pending/accepted/paid/expired/cancelled`, scopes, `transition_to!`).

Translaciones literales del archivo viejo `quote.rb`:

- `class Quote` → `class CargoOffer`
- `belongs_to :cargo_offer` → `belongs_to :cargo` (apunta a la publicación nueva)
- `belongs_to :carrier` se conserva
- `belongs_to :transport_window` se conserva
- `has_one :shipment` se conserva (la FK ya quedó `shipments.cargo_offer_id` en la migration 4.2)
- `Quote::STATES` → `CargoOffer::STATES` (mismos valores)
- `Quote::ALLOWED_TRANSITIONS` → `CargoOffer::ALLOWED_TRANSITIONS`
- Ransack: `ransackable_attributes` reemplaza `cargo_offer_id` por `cargo_id`; `ransackable_associations` reemplaza `cargo_offer` por `cargo`

### 4.5 `app/models/cargo.rb` (nuevo — ex-`cargo_offer.rb`)

**Purpose**: Class `Cargo` con la lógica de la publicación del Shipper.

Translaciones literales del archivo viejo `cargo_offer.rb`:

- `class CargoOffer` → `class Cargo`
- `belongs_to :shipper` se conserva
- `has_many :quotes` → `has_many :cargo_offers` (apunta al nuevo bid)
- Validations se conservan tal cual (todas son de campos de la publicación: pickup_address, delivery_address, weight_kg, etc.)
- Ransack: `ransackable_associations` reemplaza `quotes` por `cargo_offers`

> **Out of scope para esta REF**: el FSM `Cargo.status` (`open / accepted / cancelled`) NO se agrega acá — lo agregará la implementación de US27 (`REQ-BE-00032`). Esta REF solo renombra el modelo existente sin cambiar su shape lógica.

### 4.6 `app/models/shipment.rb` — edits in place

**Purpose**: Apuntar a `CargoOffer` (nuevo) en lugar de `Quote`; renombrar estado `quoted → offered`.

Cambios:

```ruby
# antes
belongs_to :quote, inverse_of: :shipment
validates :quote_id, presence: true, uniqueness: true
# después
belongs_to :cargo_offer, inverse_of: :shipment
validates :cargo_offer_id, presence: true, uniqueness: true

# antes
STATUSES = %w[draft quoted accepted in_transit delivered settled cancelled].freeze
ALLOWED_TRANSITIONS = {
  draft: %i[quoted],
  quoted: %i[accepted cancelled],
  ...
}.freeze
# después
STATUSES = %w[draft offered accepted in_transit delivered settled cancelled].freeze
ALLOWED_TRANSITIONS = {
  draft: %i[offered],
  offered: %i[accepted cancelled],
  ...
}.freeze

# enum :status, STATUSES.index_with(&:itself), prefix: true
# Después del rename, los predicados se llamarán status_offered? (no status_quoted?). Revisar callsites — el grep del Explore agent encontró solo el spec, ningún callsite productivo de status_quoted?
```

Ransackable: reemplazar `quote_id` por `cargo_offer_id` en `ransackable_attributes`.

### 4.7 `app/models/carrier.rb`, `shipper.rb`, `transport_window.rb`, `vehicle.rb` — edits in place

| File | Cambio |
|------|--------|
| `carrier.rb` | `has_many :quotes` → `has_many :cargo_offers, inverse_of: :carrier` |
| `shipper.rb` | `has_many :cargo_offers` → `has_many :cargos, inverse_of: :shipper` (apunta al nuevo `Cargo`) |
| `transport_window.rb` | `has_many :quotes` → `has_many :cargo_offers, inverse_of: :transport_window`; ransackable association `quotes` → `cargo_offers` |
| `vehicle.rb` | `#ensure_no_active_commitments`: la chain `transport_windows.flat_map(&:quotes).select(&:active?)` → `transport_windows.flat_map(&:cargo_offers).select(&:active?)` (ajustar a la nueva cadena exacta cuando se implemente) |

### 4.8 `app/admin/cargo_offers.rb` (nuevo — ex-`quotes.rb`)

**Purpose**: Registra `CargoOffer` en ActiveAdmin.

Cambios respecto al archivo viejo:

- `ActiveAdmin.register Quote` → `ActiveAdmin.register CargoOffer`
- `permit_params`: `cargo_offer_id` → `cargo_id`
- Filter `cargo_offer` → `cargo`
- Index/show/form column `cargo_offer` → `cargo`
- Status dropdown sigue usando `CargoOffer::STATES` (antes `Quote::STATES`)

### 4.9 `app/admin/cargos.rb` (nuevo — ex-`cargo_offers.rb`)

**Purpose**: Registra `Cargo` en ActiveAdmin.

Cambios:

- `ActiveAdmin.register CargoOffer` → `ActiveAdmin.register Cargo`
- `permit_params` y filtros sin cambio (todos son atributos de la publicación)

### 4.10 `app/admin/shipments.rb` — edits in place

```ruby
# permit_params
permit_params :quote_id → :cargo_offer_id

# filters
filter :quote → filter :cargo_offer

# index
column :quote_id → column :cargo_offer_id (or column :cargo_offer)

# show / form
... :quote ... → ... :cargo_offer ...
```

### 4.11 `db/seeds.rb` — rewrite

**Purpose**: Sembrar `Cargo` (publicaciones del Shipper, estado `open`) y `CargoOffer` (bids contra `TransportWindow`, estados `pending/accepted/paid/expired/cancelled`), incluyendo caso parallel-offers.

```ruby
# Estructura (pseudo-código):
# - 1 AdminUser
# - 2 Carriers (con 1 Vehicle + 2 TransportWindows cada uno)
# - 2 Shippers
# - Por cada Shipper: 2 Cargos (publicaciones — pickup/delivery addresses + payload).
# - Para uno de los Cargos del Shipper 1: 3 CargoOffers contra 3 TransportWindows distintos (1 pending, 1 pending, 1 pending) — DEMO del parallel-offers.
# - Para los otros Cargos: 1 CargoOffer en estado representativo (pending, accepted, paid).
# - Shipments: 1 por estado de Shipment::STATUSES, usando CargoOffers `paid` cuando aplique.
```

> Cada `CargoOffer` debe satisfacer la composición `belongs_to :cargo, belongs_to :transport_window, belongs_to :carrier` (carrier inferido del Window).

### 4.12 `spec/factories/cargo_offers.rb` (nuevo — ex-`quotes.rb`)

```ruby
FactoryBot.define do
  factory :cargo_offer do
    cargo
    carrier
    transport_window
    amount_cents { 2_500_000 }
    currency { "ARS" }
    status { "pending" }
    expires_at { 24.hours.from_now }

    trait(:pending)    { status { "pending" } }
    trait(:accepted)   { status { "accepted" } }
    trait(:paid)       { status { "paid" } }
    trait(:expired)    { status { "expired" } }
    trait(:cancelled)  { status { "cancelled" } }
  end
end
```

### 4.13 `spec/factories/cargos.rb` (nuevo — ex-`cargo_offers.rb`)

```ruby
FactoryBot.define do
  factory :cargo do
    shipper
    pickup_address { "Av. Corrientes 1000, CABA" }
    delivery_address { "Av. Colón 500, Córdoba" }
    pickup_date { 2.days.from_now.to_date }
    cargo_description { "Pallets de mercadería general" }
    weight_kg { 1500.0 }
    volume_cm3 { 4_000_000 }
    declared_value_cents { 5_000_000 }
  end
end
```

### 4.14 `spec/factories/shipments.rb` — edits in place

```ruby
# antes
association :quote
# después
association :cargo_offer

# trait :quoted → trait :offered
```

### 4.15 `spec/factories/tracking_events.rb` — edits in place

```ruby
# antes
to_status { "quoted" }
# después
to_status { "offered" }
```

### 4.16 `spec/models/cargo_offer_spec.rb` (nuevo — ex-`quote_spec.rb`)

Las 7 ejemplos del spec viejo se traducen literalmente:

- `factory: build(:quote)` → `build(:cargo_offer)`
- Constants: `Quote::STATES` → `CargoOffer::STATES`
- Associations: `belongs_to(:cargo_offer)` → `belongs_to(:cargo)`; el resto se conserva
- Scopes y matriz de `#can_transition_to?` / `#transition_to!`: cambio de nombre de clase, sin cambio semántico

### 4.17 `spec/models/cargo_spec.rb` (nuevo — ex-`cargo_offer_spec.rb`)

Spec del modelo `Cargo`: validations + factory build. Sin FSM (el FSM lo agrega US27).

### 4.18 `spec/models/shipment_spec.rb` — edits in place

Cambios:

- `quote` factory association → `cargo_offer`
- `STATUSES` expected: reemplazar `"quoted"` por `"offered"`
- `ALLOWED_TRANSITIONS` matriz: keys y values con `:quoted` → `:offered`
- Tests de transition: nombre del estado
- Tests de validations: `validates :quote_id` → `validates :cargo_offer_id`

### 4.19 `spec/requests/admin/crud_spec.rb` — edits in place

- Paths admin: `/admin/quotes` → `/admin/cargo_offers`; `/admin/cargo_offers` → `/admin/cargos`
- Factory symbols: `:quote` → `:cargo_offer`; `:cargo_offer` → `:cargo`

---

## 5. Testing

### Unit Tests

- `CargoOffer` (bid): validations (amount, currency, status, expires_at), `STATES`/`TERMINAL_STATES`/`ALLOWED_TRANSITIONS`, scopes (`.pending`, `.accepted`, `.paid`, `.cancelled`, `.expired`, `.past_expiry`), `#can_transition_to?`, `#transition_to!` (válida + inválida + idempotencia).
- `Cargo` (publicación): validations (pickup_address, delivery_address, cargo_description, weight_kg, volume_cm3, declared_value_cents, pickup_date), factory build.
- `Shipment`: associations `belongs_to :cargo_offer`; `STATUSES` incluye `"offered"` y NO `"quoted"`; `ALLOWED_TRANSITIONS` con `:offered`; `#transition_to!(:offered, ...)` desde `:draft` permitido; `transition_to!(:quoted, ...)` raises (estado inexistente).
- `Carrier`, `Shipper`, `TransportWindow`, `Vehicle`: re-run de specs existentes con asociaciones renombradas.

### Integration Tests

- `spec/requests/admin/crud_spec.rb`: CRUD por `/admin/cargo_offers`, `/admin/cargos`, `/admin/shipments` con factories renombradas. Las 3 rutas devuelven 200 en index, show, new/edit.

### Data Migration Tests

- Test manual: seed un `Shipment` en estado `"quoted"` directamente vía SQL, correr la migration `RenameShipmentQuotedState`, verificar que pasó a `"offered"` y que un `TrackingEvent` con `to_status: "quoted"` también se actualizó.
- Test rollback: `bin/rails db:rollback STEP=1` revierte la migration (estado vuelve a `"quoted"`); luego re-migrate.

### Manual Smoke

- `bin/rails s` en dev, login como admin, navegar a:
  - `/admin/cargos` → lista publicaciones; crear/editar/borrar una funciona.
  - `/admin/cargo_offers` → lista bids; cada uno muestra su `cargo`, `carrier`, `transport_window`.
  - `/admin/shipments` → lista envíos; cada uno muestra su `cargo_offer_id`.
- `bin/rails db:seed`: corre sin errores y produce los 2 Cargos del Shipper 1 con 3 CargoOffers parallel.

---

## 6. Acceptance Criteria

- [ ] PR #193 mergeada (o cerrada y rebatcheada) con endpoints renombrados — esta issue NO arranca antes.
- [ ] Migration `RenameMarketplaceTables` aplicada: `quotes` ya no existe; `cargo_offers` contiene los registros del viejo `Quote`; `cargos` contiene los registros del viejo `CargoOffer`.
- [ ] Migration `RenameShipmentQuoteFk` aplicada: columna `shipments.cargo_offer_id` reemplaza a `quote_id`; índice único renombrado; FK constraint renombrada.
- [ ] Migration `RenameShipmentQuotedState` aplicada: CHECK constraint en `shipments.status` lista `'offered'` (no `'quoted'`); registros existentes con `status='quoted'` migrados a `'offered'`; `tracking_events.from_status`/`to_status` `'quoted'` → `'offered'`.
- [ ] `db/schema.rb` regenerado: tablas `cargos`, `cargo_offers`, `shipments` (con `cargo_offer_id`); CHECK con `'offered'`.
- [ ] `app/models/quote.rb` eliminado; `app/models/cargo_offer.rb` contiene la clase `CargoOffer` (bid); `app/models/cargo.rb` contiene la clase `Cargo` (publicación).
- [ ] `CargoOffer belongs_to :cargo, belongs_to :carrier, belongs_to :transport_window, has_one :shipment`.
- [ ] `Cargo belongs_to :shipper, has_many :cargo_offers`.
- [ ] `Shipment belongs_to :cargo_offer`; valida `cargo_offer_id` presente y único.
- [ ] `Carrier has_many :cargo_offers`; `Shipper has_many :cargos`; `TransportWindow has_many :cargo_offers`.
- [ ] `Shipment::STATUSES = %w[draft offered accepted in_transit delivered settled cancelled]`; `ALLOWED_TRANSITIONS` con `:offered`; sin referencias a `:quoted`/`"quoted"` en el modelo o ALLOWED_TRANSITIONS.
- [ ] `app/admin/quotes.rb` eliminado; `app/admin/cargo_offers.rb` registra `CargoOffer`; `app/admin/cargos.rb` registra `Cargo`. `app/admin/shipments.rb` usa `cargo_offer_id` y filter `:cargo_offer`.
- [ ] Smoke manual: `/admin/cargos`, `/admin/cargo_offers`, `/admin/shipments` cargan 200; create/edit/destroy funcionan vía AA.
- [ ] `spec/models/cargo_offer_spec.rb` (bid) y `spec/models/cargo_spec.rb` (publicación) existen y pasan; `quote_spec.rb` eliminado.
- [ ] `spec/factories/cargo_offers.rb` y `cargos.rb` reflejan la nueva semántica; `quotes.rb` eliminado. Factory `:cargo_offer` (bid) tiene traits `:pending/:accepted/:paid/:expired/:cancelled`. Factory `:cargo` tiene los attrs de publicación.
- [ ] `spec/factories/shipments.rb`: `association :cargo_offer`; trait `:offered` (no `:quoted`).
- [ ] `spec/factories/tracking_events.rb`: default `to_status { "offered" }`.
- [ ] `spec/requests/admin/crud_spec.rb`: paths `/admin/cargo_offers` y `/admin/cargos` testeados; sin referencias a `/admin/quotes`.
- [ ] `db/seeds.rb` reescrito: siembra ≥2 `Cargo`s, ≥4 `CargoOffer`s con composición Window+Cargo, al menos un `Cargo` con 3 `CargoOffer`s pending en paralelo (demo del caso parallel-offers).
- [ ] `grep -rn '\bQuote\b\|quote_id\|:quote\b\|\bquoted\b\|:quoted\b' backend/{app,db,spec,config} | grep -v 'db/migrate/2026050912000[67]_'` devuelve cero hits (excluyendo las migrations originales 2026-05-09 que mantienen el vocab viejo por immutabilidad histórica).
- [ ] `bundle exec rspec` verde.
- [ ] `bundle exec rubocop` verde.
- [ ] `bundle exec brakeman -q` sin nuevos findings.
- [ ] `bundle exec bundle-audit check --update` verde.
- [ ] PR title: `refactor(domain): rename Quote→CargoOffer y CargoOffer→Cargo`. Body referencia `REF-BE-00002` y (si existe issue GH asociada) `Closes #N`. PR creado con `--assignee @me` per memory.
- [ ] `ISSUES-INDEX.md` se actualiza al mergear: status `NEW` → `DONE` para `REF-BE-00002`, footnote en `Done/REQ-BE-00021` (título-stale) ya quedó en el commit previo.

---

## 7. Files Summary

### New Files

| File                                                                                       | Description                                                          |
|--------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| `backend/db/migrate/<TS>_rename_marketplace_tables.rb`                                     | Triple-rename `quotes ↔ cargo_offers ↔ cargos`                       |
| `backend/db/migrate/<TS+1>_rename_shipment_quote_fk.rb`                                    | `shipments.quote_id → cargo_offer_id` + índice                        |
| `backend/db/migrate/<TS+2>_rename_shipment_quoted_state.rb`                                | CHECK + data migration `quoted → offered`                             |
| `backend/app/models/cargo.rb`                                                              | Modelo `Cargo` (publicación, ex-CargoOffer)                          |
| `backend/app/admin/cargos.rb`                                                              | AA register `Cargo`                                                  |
| `backend/spec/models/cargo_spec.rb`                                                        | Spec del modelo `Cargo`                                              |
| `backend/spec/factories/cargos.rb`                                                         | Factory `:cargo`                                                     |

### Modified Files (file renames count como modificación)

| File                                              | Changes                                                                                                   |
|---------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `backend/app/models/cargo_offer.rb`               | **Contenido reemplazado** por la lógica del bid (ex-`quote.rb`). Clase `CargoOffer` con `belongs_to :cargo`.|
| `backend/app/models/quote.rb`                     | **Eliminado** (su contenido vivió en `cargo_offer.rb`).                                                    |
| `backend/app/models/shipment.rb`                  | `belongs_to :quote → :cargo_offer`; STATUSES + ALLOWED_TRANSITIONS `quoted → offered`; ransackable.        |
| `backend/app/models/carrier.rb`                   | `has_many :quotes → :cargo_offers`.                                                                       |
| `backend/app/models/shipper.rb`                   | `has_many :cargo_offers → :cargos`.                                                                       |
| `backend/app/models/transport_window.rb`          | `has_many :quotes → :cargo_offers`; ransackable.                                                          |
| `backend/app/models/vehicle.rb`                   | `#ensure_no_active_commitments` chain updated.                                                            |
| `backend/app/admin/cargo_offers.rb`               | **Contenido reemplazado** por register `CargoOffer` (ex-`quotes.rb`).                                     |
| `backend/app/admin/quotes.rb`                     | **Eliminado**.                                                                                            |
| `backend/app/admin/shipments.rb`                  | `quote_id → cargo_offer_id`, filter `:cargo_offer`.                                                       |
| `backend/spec/models/cargo_offer_spec.rb`         | **Contenido reemplazado** (ex-`quote_spec.rb`).                                                           |
| `backend/spec/models/quote_spec.rb`               | **Eliminado**.                                                                                            |
| `backend/spec/models/shipment_spec.rb`            | Associations + STATUSES + ALLOWED_TRANSITIONS updates.                                                    |
| `backend/spec/factories/cargo_offers.rb`          | **Contenido reemplazado** (ex-`quotes.rb`).                                                               |
| `backend/spec/factories/quotes.rb`                | **Eliminado**.                                                                                            |
| `backend/spec/factories/shipments.rb`             | `association :quote → :cargo_offer`; trait `:quoted → :offered`.                                          |
| `backend/spec/factories/tracking_events.rb`       | `to_status "quoted" → "offered"`.                                                                         |
| `backend/spec/requests/admin/crud_spec.rb`        | Paths admin renombrados + factory symbols.                                                                |
| `backend/db/seeds.rb`                             | Reescrito para sembrar `Cargo` + `CargoOffer` con composición; incluye caso parallel-offers.              |
| `backend/db/schema.rb`                            | Regenerado automáticamente por las 3 migrations.                                                          |

### Files NOT touched (deliberately)

| File                                                          | Reason                                                                                              |
|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| `backend/db/migrate/20260509120006_create_cargo_offers.rb`    | Migration histórica, immutable (shipped en `main` por PR #134).                                     |
| `backend/db/migrate/20260509120007_create_quotes.rb`          | Idem.                                                                                               |
| `backend/db/migrate/20260509120008_create_shipments.rb`       | Idem; el FK rename lo hace la nueva migration (sección 4.2).                                        |
| `backend/config/routes.rb`                                    | No hay rutas API para Quote/CargoOffer/Shipment en `main`. PR #193 las introducirá con nombres OK.  |
| `backend/app/controllers/api/*`                               | No existen controllers para estos resources en `main`.                                              |
| `backend/app/resources/`                                      | Directorio vacío.                                                                                   |
| `frontend/**`                                                 | Frontend en landing-page-only, sin tipos del dominio. Out of scope.                                 |
| `docs/**`                                                     | Docs ya renombradas en commit anterior (rename pass del 2026-05-19).                                |
| `.gdsi-sdlc/issues/Done/REQ-BE-00021-*.issue.md`              | Histórico immutable; footnote en `ISSUES-INDEX.md` cubre la stale title.                            |
