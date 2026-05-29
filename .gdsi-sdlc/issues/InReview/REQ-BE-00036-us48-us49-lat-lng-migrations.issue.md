---
tag: REQ-BE-00036
title: Migraciones y validaciones de lat/lng para TransportWindow y Cargo (US48 +
  US49)
priority: P1
status: in_review
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/234
author: Claude Code
github_issue: 234
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr3yI
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:54:09.950688+00:00Z
labels:
- REQ
- BE
- fulfilment
- carrier
- shipper
- mvp
- us48
- us49
- gmaps
sprint: 4
assignee: tcorzo
plan: docs/features/REQ/REQ-BE-00036/REQ-BE-00036-us48-us49-lat-lng-migrations.plan.md
---

## Summary

Backend companion para [[REQ-FE-00025]] (US48) y [[REQ-FE-00026]] (US49). Dos migraciones, dos pares de validaciones, dos updates de `*Controller#permit`:

1. **`transport_windows`** gana `origin_lat`, `origin_lng`, `destination_lat`, `destination_lng` — todas `DECIMAL(9,6)`. `origin_*` `NOT NULL`. `destination_*` nullable (destino es opcional en US9).
2. **`cargos`** gana `pickup_lat`, `pickup_lng`, `delivery_lat`, `delivery_lng` — todas `DECIMAL(9,6)`, **`NOT NULL`** (decisión cerrada: las cuatro son obligatorias en US27/US47).
3. Validaciones de rango (`-90..90` lat, `-180..180` lng) en ambos modelos, con claves i18n.
4. Strong parameters: `TransportWindowsController` y `CargosController` permiten los nuevos campos.

Sin backfill (no hay datos legacy — decisión cerrada en triage 2026-05-24). Sin spatial indexes. Sin PostGIS. Sin "Phase-2 cuando migremos a Postgres" — la política SQLite-forever aplica.

## Problem Statement

US48/US49 son load-bearing FE para US5 (filtrado por distancia/radio), US50 (radio de recogida) y US51 (mapa en detalle de envío). Sin las columnas persistidas, el frontend puede capturar coordenadas pero no hay manera de filtrar/ordenar/renderizar después. Este issue es el desbloqueo BE estricto: migraciones triviales + validaciones + permits.

Combinado en un solo issue (en vez de dos) porque:
- Las migraciones son idénticas en shape — copy/paste del bloque, mismos tipos, mismos rangos.
- Las validaciones son simétricas (rango lat/lng en ambos modelos).
- Los strong-parameter updates son updates de una línea cada uno.
- Hacerlo en dos PRs incurre overhead de coordinación sin beneficio. Si pesa demasiado el PR, se puede splitear al planning.

## Expected Behavior

### Migración 1 — `transport_windows`

```ruby
class AddCoordinatesToTransportWindows < ActiveRecord::Migration[7.1]
  def change
    add_column :transport_windows, :origin_lat, :decimal, precision: 9, scale: 6, null: false
    add_column :transport_windows, :origin_lng, :decimal, precision: 9, scale: 6, null: false
    add_column :transport_windows, :destination_lat, :decimal, precision: 9, scale: 6, null: true
    add_column :transport_windows, :destination_lng, :decimal, precision: 9, scale: 6, null: true
  end
end
```

- `origin_*` `NOT NULL` — toda ventana publicada tiene origen (es un campo obligatorio en US9 desde antes y sigue siéndolo).
- `destination_*` nullable — destino es opcional en US9 (la ventana puede tener destino variable).
- **Sin defaults** porque no hay datos legacy a backfillear (verificar con `bundle exec rails db:reset RAILS_ENV=development` que la tabla está vacía o solo con seeds nuevos).
- **Sin spatial index** — la política SQLite-forever prohíbe GIN/GIST/spatial.

### Migración 2 — `cargos`

```ruby
class AddCoordinatesToCargos < ActiveRecord::Migration[7.1]
  def change
    add_column :cargos, :pickup_lat, :decimal, precision: 9, scale: 6, null: false
    add_column :cargos, :pickup_lng, :decimal, precision: 9, scale: 6, null: false
    add_column :cargos, :delivery_lat, :decimal, precision: 9, scale: 6, null: false
    add_column :cargos, :delivery_lng, :decimal, precision: 9, scale: 6, null: false
  end
end
```

- Las cuatro `NOT NULL` — decisión cerrada (pickup y delivery son ambos obligatorios en US27).
- Mismas reglas: sin spatial index, sin PostGIS.

### Validaciones en `TransportWindow`

```ruby
validates :origin_lat, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
validates :origin_lng, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
validates :destination_lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
validates :destination_lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
validate :destination_pin_consistency  # si hay destination_text, deben estar los dos, lat+lng; si no hay, ninguno
```

- `destination_pin_consistency` — XOR: o están los tres (text+lat+lng) o ninguno. No se acepta solo el text sin coordenadas.
- Errores con symbolic keys (resueltos en `config/locales/*.yml`): `:invalid_format`, `:out_of_range`, `:inconsistent_with_text`.

### Validaciones en `Cargo`

```ruby
validates :pickup_lat, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
validates :pickup_lng, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
validates :delivery_lat, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
validates :delivery_lng, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
```

- Sin XOR check — las cuatro son obligatorias siempre.
- Mismas symbolic keys i18n.

### Controllers (strong parameters)

- `Api::TransportWindowsController#transport_window_params` agrega `:origin_lat`, `:origin_lng`, `:destination_lat`, `:destination_lng`.
- `Api::CargosController#cargo_params` agrega `:pickup_lat`, `:pickup_lng`, `:delivery_lat`, `:delivery_lng`.
- Si los params faltan o son inválidos → 422 con error response formateado vía el helper existente (typically `RenderableError` o equivalente — verificar el patrón actual en `REQ-BE-00032` `cargos_controller.rb`).

### Serializers

- `TransportWindowSerializer` (o equivalente — verificar el actual) emite `origin_lat`, `origin_lng`, `destination_lat`, `destination_lng` en el JSON. Si el serializer hoy no existe (modelos serializan vía `to_json` default), considerar agregar uno explícito en este PR — es el momento.
- `CargoSerializer` emite las cuatro.
- **Crítico para US51** — el `ShipmentSerializer` (consumido por `GET /api/shipments/:id` de [[REQ-BE-00035]]) debe incluir las coordenadas del `Cargo` asociado (pickup y delivery) — verificar y, si falta, agregarlo en el mismo PR.

### Seeds

- Actualizar `backend/db/seeds.rb` (o equivalente) para que las ventanas y cargas semilla tengan coordenadas plausibles de AR (CABA, Rosario, Mar del Plata, Mendoza). Sin estas, el dev local se rompe al levantar la app.

## Acceptance Criteria

- [ ] **AC1** — Migración `AddCoordinatesToTransportWindows` agrega los 4 campos `DECIMAL(9,6)` (origin obligatorios, destination nullable). `db:migrate` corre limpio.
- [ ] **AC2** — Migración `AddCoordinatesToCargos` agrega los 4 campos `DECIMAL(9,6)` todos `NOT NULL`. `db:migrate` corre limpio.
- [ ] **AC3** — `TransportWindow` valida presencia y rango de origin_lat/origin_lng; rango de destination_lat/lng cuando están presentes; consistencia XOR del destination (text+lat+lng o ninguno).
- [ ] **AC4** — `Cargo` valida presencia y rango de las cuatro coordenadas.
- [ ] **AC5** — Errores de validación usan symbolic keys resueltos en `config/locales/es.yml` y `en.yml` — sin literales hardcodeados.
- [ ] **AC6** — Controllers permiten los nuevos campos en strong parameters; payloads inválidos → 422 con shape esperado por el FE.
- [ ] **AC7** — Serializers de `TransportWindow` y `Cargo` emiten las nuevas columnas en JSON.
- [ ] **AC8** — `ShipmentSerializer` (o el camino que use el detalle de envío) incluye las coordenadas del Cargo asociado, para que [[REQ-FE-00028]] (US51) las consuma.
- [ ] **AC9** — Seeds actualizados con coordenadas plausibles de AR.
- [ ] **AC10** — RSpec cubre las validaciones de `TransportWindow` y `Cargo` (presencia, rango, XOR), y los specs de los controllers cubren el 422 con shape consistente. SimpleCov no baja del baseline actual.
- [ ] **AC11** — Sin spatial indexes. Sin PostGIS. Sin "Phase-2" comments. Sin `unaccent`. Cumple la política SQLite-forever.

### Tests requeridos

- [ ] RSpec model — `TransportWindow` valida origin presence/range, destination range cuando presente, XOR del destination.
- [ ] RSpec model — `Cargo` valida las cuatro coordenadas (presence + range).
- [ ] RSpec request — `POST /api/transport_windows` con payload sin coordenadas → 422 con shape `{ errors: { origin_lat: ["..."], ... } }`.
- [ ] RSpec request — `POST /api/cargos` con payload sin alguna coordenada → 422.
- [ ] RSpec request — `GET /api/transport_windows/:id` incluye las coordenadas en la respuesta.
- [ ] RSpec request — `GET /api/cargos/:id` incluye las cuatro coordenadas.
- [ ] RSpec request — `GET /api/shipments/:id` incluye las coordenadas del Cargo asociado (pickup + delivery) en el payload.

## Technical Notes

**Migración irreversible-en-la-práctica** — `add_column ... null: false` falla si la tabla tiene filas existentes sin valor. En este momento las tablas están vacías (dev/test) y no hay producción. Si por alguna razón llega una fila en CI sin coordenadas (vía factories desactualizadas), la migración va a explotar — actualizar todas las factories en el mismo PR.

**Factories** — actualizar `transport_window_factory.rb` y `cargo_factory.rb` para emitir coordenadas plausibles por defecto (e.g. Faker::Address.latitude/longitude rangos de AR). Sin esto, todos los specs existentes se rompen.

**SQLite-forever** — re-leer la sección "Database policy" de CLAUDE.md antes de escribir un solo comment sobre PostGIS o spatial. **No agregues** comentarios del tipo "Phase 2 will use GIST". Si encontrás el comentario viejo `# Phase 2: replace with PostGIS / proper geocoded matching (ADR-010)` en `transport_window.rb`, este es el momento de eliminarlo (es exactamente el cleanup que el handoff de Tomás flagged).

**Sin defaults sobre datos legacy** — no hay datos legacy. Verificar con `Rails.env.development? && TransportWindow.where(origin_lat: nil).any?` antes de correr el deploy a un eventual entorno compartido; debería devolver `false`.

**Sin reverse-geocode server-side** — decisión cerrada en triage 2026-05-24. El backend NO llama a Google Geocoding API para validar que las coordenadas correspondan a una dirección argentina. La restricción AR-only es UI-only (`componentRestrictions: { country: 'ar' }` en el frontend).

**Lenguaje** — todo el código en inglés. Strings de error vía symbolic keys + `config/locales/es.yml` / `en.yml`. Cero literales en español en controllers o models.

## Related

- US48 en `docs/artifacts/backlog-us.typ:688-707`.
- US49 en `docs/artifacts/backlog-us.typ:709-727`.
- Glossary: «Ventana de transporte» y «Carga» (`docs/05-appendices/glossary.md`).
- CLAUDE.md: «Database policy (UTMOST importance)» — SQLite-forever, Haversine en app code, no PostGIS.
- Cliente FE: [[REQ-FE-00025]] (US48 — picker compartido).
- Cliente FE: [[REQ-FE-00026]] (US49 — picker para Cargo).
- Sibling BE: [[REQ-BE-00037]] (US50 — `pickup_radius_km` + Haversine matcher en el US5 scope).
- Cleanup oportunista: `backend/app/models/transport_window.rb` — eliminar el comment Phase-2 PostGIS si todavía está.

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(fulfilment): ...` o `feat(geo): ...`), sin `[REQ-BE-00036]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Coordinar con [[REQ-FE-00025]] / [[REQ-FE-00026]]** — el shape del payload JSON (snake_case, columnas planas, no objetos anidados) es el contrato. Documentar en el PR.
- **Cleanup oportunista** — eliminar el comment Phase-2 PostGIS en `transport_window.rb` (si todavía está). Si lo dejás, el siguiente reviewer lo va a flagear igual.
- **Pre-PR check** (CLAUDE.md): `just lint`, `just backend-test` (SimpleCov no baja del baseline).

## Decisiones cerradas en triage (2026-05-24)

| Tema | Decisión |
|---|---|
| Datos legacy | No hay. Columnas `NOT NULL` directo (`destination_*` nullable porque destino es opcional en US9). |
| Tipo de columna | `DECIMAL(9,6)`. **Nunca** PostGIS, **nunca** spatial index, **nunca** "Phase-2" framing. |
| Validación AR | UI-only via `componentRestrictions: { country: 'ar' }` en el FE. No bounding box server-side. No reverse-geocode. |
| Scope del issue | Combina US48 + US49 BE (migraciones simétricas). Splitear solo si el PR explota. |
| `transport_window.rb` Phase-2 comment | Eliminar en este PR (cleanup oportunista flagged en handoff). |
