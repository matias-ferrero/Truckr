---
tag: REF-BE-00002
title: Rename Quote → CargoOffer y CargoOffer → Cargo en el backend (modelos, tablas,
  AA, specs, seeds)
priority: P1
status: ready
created: '2026-05-19'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/197
author: Claude Code
github_issue: 197
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtNJFs
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-19T16:06:26.966994+00:00Z
labels:
- REF
- BE
- marketplace
- rename
- schema
plan: docs/features/REF/REF-BE-00002/REF-BE-00002-rename-quote-cargooffer-y-cargooffer-cargo-en-backend.plan.md
---

## Summary

Alinear el código del backend con la nueva nomenclatura del dominio decidida 2026-05-19: el modelo `Quote` pasa a llamarse `CargoOffer`, y el modelo `CargoOffer` actual (la publicación del Shipper) pasa a llamarse `Cargo`. La rename ya está aplicada en `docs/02-high-level-design/domain-model.md`, `docs/04-database-diagrams/erd-marketplace.puml`, `docs/05-appendices/glossary.md` y `docs/artifacts/backlog-us.typ`; esta issue trae la `app/`, las migraciones, ActiveAdmin, specs, factories y seeds en línea con el diagrama. Scope: **backend-only** — el frontend todavía no tiene tipos del dominio.

## Problem Statement

PR #134 (REQ-BE-00021, Done) shipó los modelos `Quote`, `CargoOffer`, `Shipment`, `Vehicle`, `TransportWindow` con la vieja nomenclatura. Tras la sesión de grilling del 2026-05-19, el dominio se renombró:

- **`Cargo`** (antes `CargoOffer`) — publicación del Shipper. Lifecycle: `open / accepted / cancelled`. US27.
- **`CargoOffer`** (antes `Quote`) — bid del Shipper contra un `TransportWindow` específico. Lifecycle: `pending / accepted / rejected / expired`. US7.

La rename de docs ya está. La schema real sigue con los nombres viejos, lo que genera divergencia entre el diagrama y el código y bloquea la implementación coherente de US7/US10/US12/US27. Además, PR #193 layered `POST /api/quotes` (controllers + routes) encima de la vieja nomenclatura — esa superficie también se renombra como parte de esta REF, pero **después** de que #193 se resuelva (request-changes → split en dos endpoints).

## Expected Behavior

Post-merge de esta issue:

- `Quote` no existe en código (modelo, tabla, AA, specs, factories, seeds, controllers).
- Existen `Cargo` (publicación) y `CargoOffer` (bid contra Window) como modelos ActiveRecord con sus FSMs respectivos.
- `Shipment` asocia a `CargoOffer` (no a `Quote`); `CargoOffer` asocia a `Cargo` + `TransportWindow`; FKs nombrados consistentemente.
- ActiveAdmin sirve `Cargo` y `CargoOffer` (no `Quote`).
- Schema de la DB en `db/schema.rb` refleja `cargos` y `cargo_offers` (no `quotes`).
- Specs y seeds usan los nuevos nombres; RSpec + rswag verde.
- `Shipment` FSM renombra el estado `quoted → offered`; `TrackingEvent` event-type acompaña.

## Current Behavior

Schema actual (sobre `main`, confirmado vía `grep` 2026-05-19):

- `backend/app/models/quote.rb` — modelo del bid (será `cargo_offer.rb`).
- `backend/app/models/cargo_offer.rb` — modelo de la publicación (será `cargo.rb`).
- `backend/app/models/shipment.rb`, `vehicle.rb`, `transport_window.rb` — referencian asociaciones viejas.
- `backend/app/admin/quotes.rb` y `cargo_offers.rb` — AA con los nombres viejos.
- `backend/db/migrate/20260509120006_create_cargo_offers.rb` y `20260509120007_create_quotes.rb` — migraciones originales, **no se editan en place** (shipearon en `main` por PR #134).
- `backend/db/migrate/20260509120008_create_shipments.rb` — referencia FK `quote_id`.
- `backend/db/seeds.rb` — siembra `Quote` y `CargoOffer` con la semántica vieja.
- `backend/spec/models/{quote,cargo_offer,shipment,vehicle}_spec.rb`, `backend/spec/factories/{quotes,cargo_offers,shipments}.rb`, `backend/spec/requests/admin/crud_spec.rb` — usan los nombres viejos.

## Reproduction Steps

N/A (refactor, no bug). Para auditar la superficie actual:

1. `grep -rn '\bQuote\b\|quote_id\|:quote\b' backend/app backend/db backend/spec backend/config`
2. `grep -rn '\bCargoOffer\b\|cargo_offer_id\|:cargo_offer' backend/app backend/db backend/spec backend/config`
3. `cat backend/db/schema.rb` — tablas `quotes`, `cargo_offers` actuales.

## Impact

**Quién**: equipo de backend; bloquea trabajo coherente sobre US7 (REQ-FE-00015), US8 (REQ-BE-00007/00008/00006), US10 (REQ-FE-00017), US11 (REQ-FE-00018), US12 (REQ-BE-00024). Esos issues ya se reescribieron usando los nombres nuevos en sus AC, por lo que su implementación produce código que no compila contra el schema actual hasta que esta REF aterrice.

**Cómo**:

- **Consistencia**: el código matchea el diagrama y el glosario. Nuevos contributors leen el mismo nombre en docs y en `app/`.
- **Mantenibilidad**: borra una traducción mental "Quote en código = CargoOffer en docs" que rotaría a deuda permanente si no se hace ahora.
- **Riesgos**:
  - Rename pesado (modelos + tablas + FKs + AA + specs + seeds en una sola PR). Hay que orquestar el orden de las `rename_table`/`rename_column` para no romper relaciones intermedias.
  - PR #193 está abierta sobre la nomenclatura vieja. **Esta issue se bloquea en la resolución de #193** (request-changes → split) para evitar conflictos de 3-way.
  - `db/seeds.rb` se reescribe entero — perder semántica accidentalmente es posible. Revisar a mano contra el nuevo dominio.

## Technical Notes

### Modelos

- `backend/app/models/quote.rb` → `backend/app/models/cargo_offer.rb` (clase `CargoOffer`).
- `backend/app/models/cargo_offer.rb` (clase `CargoOffer`) → `backend/app/models/cargo.rb` (clase `Cargo`).
- Actualizar `belongs_to`/`has_many` en:
  - `shipment.rb` — `belongs_to :quote` → `belongs_to :cargo_offer`.
  - `vehicle.rb` — revisar asociaciones (`has_many :cargo_offers` posiblemente referencia a la publicación vieja; semánticamente probablemente debe quedar como `has_many :cargo_offers` apuntando al modelo nuevo del bid — confirmar en el spike de implementación).
  - `transport_window.rb` — `has_many :cargo_offers` ahora apunta al modelo bid (nuevo). La asociación a `Cargo` (publicación) NO existe directamente — `Cargo` y `TransportWindow` están relacionados por el `CargoOffer`.
- `CargoOffer` (nuevo bid) `belongs_to :cargo` y `belongs_to :transport_window`. Es la composición Window+Cargo a nivel DB.

### Migraciones (NO editar las del 2026-05-09)

Nuevas migraciones post-rename, fechadas hoy o cercano:

1. `rename_table :quotes, :cargo_offers_new` (alias temporal — evita colisión).
2. `rename_table :cargo_offers, :cargos`.
3. `rename_table :cargo_offers_new, :cargo_offers`.
4. `rename_column :shipments, :quote_id, :cargo_offer_id`.
5. `rename_column :cargo_offers, :cargo_offer_id, :cargo_id` (la FK que antes apuntaba a la publicación vieja).
6. `add_reference :cargo_offers, :cargo, foreign_key: true` solo si no quedó cubierto por el step 5 (confirmar contra schema actual al implementar — el `cargo_offer_id` viejo en `quotes` puede que no exista; en ese caso este step es un `add_reference` puro).
7. Verificar índices únicos/compuestos en `cargo_offers` (Window + estado pending para enforce del Window-lock).

**Regla**: las migraciones originales del 2026-05-09 quedan en histórico. No se editan en place — `db/schema.rb` se regenera tras correr la suite nueva.

### ActiveAdmin

- `backend/app/admin/quotes.rb` → `backend/app/admin/cargo_offers.rb` (registra `CargoOffer`).
- `backend/app/admin/cargo_offers.rb` → `backend/app/admin/cargos.rb` (registra `Cargo`).
- `backend/app/admin/shipments.rb` — actualizar columnas/filtros que referencian `Quote` y `CargoOffer` viejos.
- `backend/config/routes.rb` — ActiveAdmin auto-mountea las rutas pero el orden de require de los `admin/*.rb` importa; smoke-testear `/admin/cargos`, `/admin/cargo_offers`, `/admin/shipments`.

### Specs + factories

- Renombrar `backend/spec/models/quote_spec.rb` → `cargo_offer_spec.rb`; `backend/spec/models/cargo_offer_spec.rb` → `cargo_spec.rb`.
- Renombrar `backend/spec/factories/quotes.rb` → `cargo_offers.rb`; `backend/spec/factories/cargo_offers.rb` → `cargos.rb`. Actualizar `factory :quote` → `factory :cargo_offer`, `factory :cargo_offer` → `factory :cargo`, y secuencias internas.
- `backend/spec/factories/shipments.rb` — referencias `quote` → `cargo_offer`.
- `backend/spec/requests/admin/crud_spec.rb` — paths admin (`/admin/quotes` → `/admin/cargo_offers`, `/admin/cargo_offers` → `/admin/cargos`) y símbolos.

### Seeds

- `backend/db/seeds.rb` referencia ambos modelos. Reescribir para sembrar:
  - `Cargo`s (publicaciones del Shipper, estado `open`).
  - `CargoOffer`s (bids contra `TransportWindow` específicos, estados `pending` / `accepted` / `rejected` / `expired` representativos).
  - Asegurar que la composición `CargoOffer → Cargo + TransportWindow` se respete y que algún `Cargo` tenga múltiples `pending` bids contra distintas Windows (para que demos cubran el caso parallel-offers).

### API surface (post #193)

Después de que PR #193 se rebaseé sobre la nomenclatura nueva:

- `POST /api/quotes` se split en `POST /api/cargos` + `POST /api/cargos/:id/offers`.
- Controllers renombrados + serializers + request specs.
- Esta REF asume el split ya ocurrido; si #193 aún no resolvió cuando esta issue arranque, hay que coordinar el rebase.

### `Shipment` FSM

- `app/models/shipment.rb` — enum/AASM: estado `quoted` → `offered`.
- `TrackingEvent` — event-type `:quoted` → `:offered` (revisar callsites de `TrackingEvent.create_event!(:quoted, ...)`).
- Migración: `update Shipment.where(state: "quoted").update_all(state: "offered")` antes de borrar el valor viejo del enum.

### ERD

`docs/04-database-diagrams/erd-marketplace.puml` ya refleja la nomenclatura nueva. Esta issue trae el schema AR a línea con el diagrama, no al revés.

### Sequencing

**Bloquea en**: resolución de PR #193. La secuencia más eficiente:

1. Request-changes en #193 → split `POST /api/quotes` en `POST /api/cargos` + `POST /api/cargos/:id/offers` (sobre nomenclatura vieja).
2. #193 mergea con los dos endpoints renombrados a la nueva nomenclatura.
3. Esta issue arranca: rename de modelos + tablas + AA + specs + seeds + FSM en una sola PR.

Doing el rename mientras #193 está abierta crea un conflicto 3-way que no vale los cycles.

### Carve-out

Frontend está actualmente solo en landing-page (no hay modelos ni tipos TypeScript del dominio Quote/CargoOffer/Cargo). Esta REF es **backend-only**. Una futura `REF-FE-*` solo haría falta si el frontend agrega tipos model-shaped antes de que US7 (REQ-FE-00015) aterrice.

## Origin

Continua la sesión de grilling del 2026-05-19 que renombró el dominio. Decisiones bloqueadas registradas en `.gdsi-sdlc/continue.md`. La rename en docs ya está aplicada y commiteada en el mismo PR de docs; esta REF cierra el delta entre docs y código.

## Related

- Docs: `docs/02-high-level-design/domain-model.md` §§ 1, 2.4, 3, 3.1–3.3, 4.1–4.2, 6, 8, 9.
- Docs: `docs/05-appendices/glossary.md` — `Cargo`, `Oferta de carga`; "Cotización" como sinónimo deprecado.
- Docs: `docs/04-database-diagrams/erd-marketplace.puml` — diagrama nuevo.
- Backlog: `docs/artifacts/backlog-us.typ` — US4, US7, US27 reword.
- Issue: `Done/REQ-BE-00021-implementar-modelos-marketplace-transport-window-cargo-offer-quote.issue.md` — origen de la nomenclatura vieja (PR #134); título queda con vocab viejo (footnote en `ISSUES-INDEX.md`).
- PR #193 (`https://github.com/tcorzo/fiuba-gestion-tp/pull/193`) — bloqueante.
- Issue #121 (`https://github.com/tcorzo/fiuba-gestion-tp/issues/121`) — US7; tag asociado REQ-FE-00015.
- Issues que asumen la nomenclatura nueva en sus AC: `Backlog/REQ-FE-00015`, `REQ-FE-00017`, `REQ-FE-00018`, `REQ-BE-00024`, `REQ-BE-00007`, `REQ-BE-00008`, `REQ-BE-00006`, `REQ-BE-00026`, `REQ-BE-00031`, `REQ-FE-00014`, `INF-FE-00003`.
- Issues a filear en paralelo: `REQ-BE-00032` (Cargo + `POST /api/cargos`, US27 BE), `REQ-FE-00022` ("Mis cargas" + form, US27 FE), `INF-BE-00006` (`CargoOfferExpirationJob`).
- Código: `backend/app/models/{quote,cargo_offer,shipment,vehicle,transport_window}.rb`.
- Código: `backend/app/admin/{quotes,cargo_offers,shipments}.rb`.
- Código: `backend/db/migrate/20260509120006_create_cargo_offers.rb`, `20260509120007_create_quotes.rb`, `20260509120008_create_shipments.rb`.
- Código: `backend/db/seeds.rb`, `backend/spec/models/{quote,cargo_offer,shipment,vehicle}_spec.rb`, `backend/spec/factories/{quotes,cargo_offers,shipments}.rb`, `backend/spec/requests/admin/crud_spec.rb`.

## Acceptance Criteria

- [ ] PR #193 mergeada con `POST /api/cargos` + `POST /api/cargos/:id/offers` (no `POST /api/quotes`). Esta issue NO arranca antes.
- [ ] `backend/app/models/quote.rb` eliminado. `backend/app/models/cargo_offer.rb` contiene la clase `CargoOffer` (bid). `backend/app/models/cargo.rb` contiene la clase `Cargo` (publicación).
- [ ] `CargoOffer belongs_to :cargo` y `belongs_to :transport_window` (composición a nivel DB con FKs).
- [ ] `Cargo has_many :cargo_offers`; `TransportWindow has_many :cargo_offers`.
- [ ] `Shipment belongs_to :cargo_offer` (no `:quote`); columna FK `shipments.cargo_offer_id`.
- [ ] `Vehicle` y `TransportWindow` con asociaciones revisadas y alineadas a la nueva semántica.
- [ ] Migraciones nuevas (no edit de las del 2026-05-09): `rename_table :quotes → :cargo_offers`, `rename_table :cargo_offers → :cargos`, `rename_column :shipments.quote_id → :cargo_offer_id`, `rename_column :cargo_offers.cargo_offer_id → :cargo_id` (o `add_reference :cargo_offers, :cargo, foreign_key: true` según schema actual).
- [ ] `db/schema.rb` regenerado: tablas `cargos`, `cargo_offers`, `shipments.cargo_offer_id`. `quotes` no existe.
- [ ] `backend/app/admin/quotes.rb` eliminado; `backend/app/admin/cargo_offers.rb` registra `CargoOffer`; `backend/app/admin/cargos.rb` registra `Cargo`. `shipments.rb` AA actualizado.
- [ ] Smoke manual: `/admin/cargos`, `/admin/cargo_offers`, `/admin/shipments` cargan sin error en dev.
- [ ] `backend/spec/models/cargo_offer_spec.rb` (bid) y `backend/spec/models/cargo_spec.rb` (publicación) existen y cubren validaciones + FSM. `quote_spec.rb` eliminado.
- [ ] `backend/spec/factories/cargo_offers.rb` y `cargos.rb` reflejan la semántica nueva; `quotes.rb` eliminado.
- [ ] `backend/spec/requests/admin/crud_spec.rb` actualizado: paths admin renombrados.
- [ ] `backend/db/seeds.rb` reescrito: siembra `Cargo`s, `CargoOffer`s con composición Window+Cargo, y al menos un caso de múltiples `pending` bids sobre un mismo `Cargo` para demo del parallel-offers.
- [ ] `Shipment` FSM: estado `quoted` renombrado a `offered`. `TrackingEvent` event-type `:quoted` → `:offered` en callsites y data migration.
- [ ] `grep -rn '\bQuote\b\|\bquote\b\|quote_id' backend/app backend/db backend/spec backend/config` no devuelve hits del dominio viejo (excluyendo seguros/insurance-quote vocabulary si aparece).
- [ ] RSpec + rswag + brakeman + bundler-audit + rubocop verdes.
- [ ] PR title: `refactor(domain): rename Quote→CargoOffer y CargoOffer→Cargo`. Body referencia `REF-BE-00002` y `Closes #N` si hay GitHub issue creada.
