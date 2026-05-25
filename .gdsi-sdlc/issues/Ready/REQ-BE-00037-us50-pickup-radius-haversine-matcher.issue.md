---
tag: REQ-BE-00037
title: pickup_radius_km column + Haversine matcher en el US5 scope (US50)
priority: P1
status: ready
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/235
author: Claude Code
github_issue: 235
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr3zA
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:54:23.591952+00:00Z
labels:
- REQ
- BE
- fulfilment
- carrier
- mvp
- us50
- gmaps
sprint: 4
assignee: tcorzo
plan: docs/features/REQ/REQ-BE-00037/REQ-BE-00037-us50-pickup-radius-haversine-matcher.plan.md
---

## Summary

Backend companion para [[REQ-FE-00027]] (US50). Una migración + una validación + una constante de rango + un **filtro Haversine en el scope de matching de US5**:

1. **`transport_windows`** gana `pickup_radius_km` (`INTEGER`, `NOT NULL`).
2. Validación de rango (1–200) en `TransportWindow` con clave i18n.
3. Strong parameter `:pickup_radius_km` en `TransportWindowsController`.
4. **`TransportWindow.scope :within_pickup_radius_of(cargo)`** — Haversine en código Ruby (no SQL espacial) que excluye ventanas cuyo origen está a más de `pickup_radius_km` del `pickup` de la carga. Se compone con el scope de US5 existente.
5. AC explícito: cambiar `pickup_radius_km` (PATCH desde US33) **no toca** ninguna `CargoOffer` en estado `pending` (sin callback, sin cascade — el radio es discoverability, no constraint retroactiva).

Sin PostGIS. Sin GIN/GIST/spatial. **Haversine en código Ruby**, no en SQL. CLAUDE.md "Database policy" es non-negotiable.

## Problem Statement

US50 (FE) entrega el control para que el Carrier defina el radio. Sin la columna persistente, el valor no sobrevive. Sin el filtro Haversine en el scope de matching, el radio existe pero no afecta a US5 — el feature es decorativo. Este issue cierra los dos huecos en un solo PR (acoplados por construcción: la columna y el lugar donde se usa).

El Haversine va en código Ruby por la política SQLite-forever — no hay PostGIS disponible, no se justifica un GIN/spatial index en SQLite. Para los volúmenes del MVP (decenas o centenares de ventanas activas en cualquier momento), filtrar en código tras cargar las filas candidatas del scope base es perfectamente aceptable.

## Expected Behavior

### Migración

```ruby
class AddPickupRadiusKmToTransportWindows < ActiveRecord::Migration[7.1]
  def change
    add_column :transport_windows, :pickup_radius_km, :integer, null: false, default: 10
  end
end
```

- `INTEGER`, `NOT NULL`.
- `default: 10` en la migración es para que las filas existentes (factories en specs, eventualmente seeds) tengan un valor inicial razonable; el frontend de US50 también usa 10 como default UX. **No es duplicación — la migración cubre filas insert-ed antes de que el form siempre mande el valor; el form de FE usa el mismo número por coincidencia explícita.**
- Después de la migración, considerar quitar el `default` y forzar que siempre lo mande el form (decisión de implementación; documentar en el PR).

### Validación

```ruby
PICKUP_RADIUS_KM_MIN = 1
PICKUP_RADIUS_KM_MAX = 200

validates :pickup_radius_km,
  presence: true,
  numericality: {
    only_integer: true,
    greater_than_or_equal_to: PICKUP_RADIUS_KM_MIN,
    less_than_or_equal_to: PICKUP_RADIUS_KM_MAX
  }
```

- Errores con symbolic keys (`:invalid_format`, `:out_of_range`) resueltos en `config/locales/es.yml` y `en.yml`.

### Controller (strong parameters)

- `Api::TransportWindowsController#transport_window_params` agrega `:pickup_radius_km`.
- POST `/api/transport_windows` y PATCH `/api/transport_windows/:id` aceptan el campo.

### Serializer

- `TransportWindowSerializer` (o equivalente) emite `pickup_radius_km` en JSON. FE de US33 lo lee para prepoblar el form.

### Scope Haversine en `TransportWindow`

```ruby
# Filters TransportWindows whose origin is within their own pickup_radius_km
# of the given Cargo's pickup point. Haversine in app code per CLAUDE.md
# "Database policy" — never PostGIS.
scope :within_pickup_radius_of, ->(cargo) do
  pickup_lat = cargo.pickup_lat.to_f
  pickup_lng = cargo.pickup_lng.to_f
  # Load candidates from the cheap pre-filters first (already part of the
  # US5 scope: date overlap, vehicle capacity, ...), then filter in Ruby.
  # SQLite has no PostGIS — that's by design (see CLAUDE.md).
  all.to_a.select do |window|
    distance_km = Truckr::Geo.haversine_km(
      [window.origin_lat.to_f, window.origin_lng.to_f],
      [pickup_lat, pickup_lng]
    )
    distance_km <= window.pickup_radius_km
  end
end
```

- El scope **rompe la chainability lazy** (devuelve `Array`, no `ActiveRecord::Relation`) — eso es OK porque es el último filtro en el pipeline y se aplica después de los pre-filtros baratos (overlap de fecha, capacidad del vehículo, etc., ya existentes en el scope de US5).
- Si querés mantener chainability, podés en cambio: cargar candidatos, computar IDs que pasan el filtro, devolver `where(id: passing_ids)`. Decidir según lo que el callsite necesite.

### Helper `Truckr::Geo.haversine_km`

```ruby
# backend/lib/truckr/geo.rb (or similar)
module Truckr
  module Geo
    EARTH_RADIUS_KM = 6371.0

    # Haversine distance in km between two [lat, lng] points.
    # SQLite-forever — used in app code instead of PostGIS.
    def self.haversine_km(point_a, point_b)
      lat1, lng1 = point_a
      lat2, lng2 = point_b
      d_lat = to_rad(lat2 - lat1)
      d_lng = to_rad(lng2 - lng1)
      a = Math.sin(d_lat / 2)**2 +
          Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) *
          Math.sin(d_lng / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      EARTH_RADIUS_KM * c
    end

    def self.to_rad(deg) = deg * Math::PI / 180
  end
end
```

- Pure-function, sin dependencias. Cubrir con specs tabulares (CABA↔Rosario ≈ 280km, CABA↔Mar del Plata ≈ 380km, conocidos a ojo).

### Integración con el scope de US5

- El controller (o servicio) que sirve a US5 (`GET /api/transport_windows?compatible_with_cargo=:cargo_id` o equivalente — verificar lo que existe hoy / lo que entrega [[FIX-BE-00001]]) compone:
  1. Pre-filtros baratos (overlap de fecha, capacidad, status open, vehicle, etc.) en SQL.
  2. `.within_pickup_radius_of(cargo)` para descartar los que están fuera de alcance.
  3. Ordenamiento por distancia (Haversine de nuevo, descendente o ascendente según el ordering pedido).
- AC textual de US5 reza: «se ordena por distancia [...] calculada por Haversine en código de aplicación sobre los pines geocodificados de US48 y US49». Este issue entrega exactamente eso.

### Non-retroactividad (AC5 del FE)

- Cambiar `pickup_radius_km` con PATCH no dispara **ningún** callback que toque `CargoOffer`s en `pending`. **No agregar callbacks** del tipo `after_update :reject_offers_outside_radius`. La AC dice expresamente que el radio es discoverability filter, no constraint retroactiva sobre commitments.
- Spec explícita: una ventana con dos `CargoOffer`s pending; achicar el radio para que una de ellas quede fuera; verificar que **ambas siguen pending** después del PATCH.

## Acceptance Criteria

- [ ] **AC1** — Migración `AddPickupRadiusKmToTransportWindows` agrega la columna `INTEGER NOT NULL` con default razonable. `db:migrate` corre limpio.
- [ ] **AC2** — `TransportWindow` valida presencia y rango 1–200 (constants `PICKUP_RADIUS_KM_MIN` / `PICKUP_RADIUS_KM_MAX`).
- [ ] **AC3** — Strong parameters permiten `:pickup_radius_km`; payload inválido → 422 con symbolic key i18n.
- [ ] **AC4** — Serializer emite `pickup_radius_km`.
- [ ] **AC5** — `Truckr::Geo.haversine_km` existe como pure function; specs tabulares contra distancias conocidas (CABA↔Rosario, CABA↔Mar del Plata) dentro de ±2km de margen de error.
- [ ] **AC6** — `TransportWindow.scope :within_pickup_radius_of(cargo)` filtra ventanas por Haversine en código Ruby; documentado inline que rompe lazy chain.
- [ ] **AC7** — El endpoint de US5 (matching de ventanas compatibles) compone el nuevo scope; respuesta excluye ventanas fuera de radio.
- [ ] **AC8** — El endpoint de US5 ordena por distancia cuando el sort es `distance` (Haversine de nuevo, ascendente).
- [ ] **AC9** — Cambiar `pickup_radius_km` con PATCH NO afecta `CargoOffer`s en `pending` — spec explícita lo verifica.
- [ ] **AC10** — Sin PostGIS. Sin spatial indexes. Sin `EXCLUDE` constraints. Sin `unaccent`. Sin "Phase-2" comments. Cumple la política SQLite-forever.
- [ ] **AC11** — Seeds actualizados: las ventanas semilla tienen un `pickup_radius_km` razonable (e.g. 50km para variedad).
- [ ] **AC12** — RSpec cubre validaciones, scope, helper, no-retroactividad. SimpleCov no baja del baseline.

### Tests requeridos

- [ ] RSpec model — `TransportWindow` valida presence y rango de `pickup_radius_km` (rechaza 0, 201, decimales, strings).
- [ ] RSpec lib — `Truckr::Geo.haversine_km` cubre distancias conocidas (CABA↔Rosario ≈ 280km ±2; CABA↔Mar del Plata ≈ 380km ±2; mismo punto = 0; antipoda = ~20015km).
- [ ] RSpec model — `TransportWindow.within_pickup_radius_of(cargo)` incluye ventanas dentro del radio, excluye las afuera.
- [ ] RSpec request — `GET /api/transport_windows?compatible_with_cargo=:cargo_id` (o el endpoint real) compone el filtro; payload con cargo en CABA y ventana en Salta con radio 50 → ventana excluida.
- [ ] RSpec request — mismo endpoint con `sort=distance` → ordena por distancia ascendente.
- [ ] RSpec request — PATCH `/api/transport_windows/:id` cambia el `pickup_radius_km`; los `CargoOffer`s `pending` asociados siguen `pending`.

## Technical Notes

**Por qué Haversine en código y no en SQL** — CLAUDE.md "Database policy" lo dice explícitamente: lat/lng como `DECIMAL(9,6)`, "Within N km" queries via Haversine en application code o external API call — **never PostGIS**. No discutir esto en el PR; es decisión arquitectónica cerrada (2026-05-11).

**Por qué romper la lazy chain** — SQLite no permite computar Haversine en SQL puro (sin extensión). Las alternativas son:
1. Computar en Ruby tras cargar candidatos → simple, costo aceptable para volúmenes MVP.
2. Encodear Haversine como SQL con `SIN`/`COS` (SQLite los soporta vía extensión `sqlite-math`) → fragmento crítico, harder to test, harder to maintain.

Opción 1 gana. Si el volumen explota más allá del MVP (no debería, este producto no va a market), se puede reconsiderar; pero CLAUDE.md también prohíbe el framing "Phase-2 cuando crezcamos".

**Pre-filtros baratos primero** — el scope `.within_pickup_radius_of` carga el set candidato de un scope ya pre-filtrado (date overlap, vehículo, status), no de todo `TransportWindow.all`. Eso es lo que mantiene el costo del Haystack-en-Ruby aceptable. Verificar en el codereview que el callsite efectivamente compone los pre-filtros antes.

**Sin callbacks retroactivos** — no `after_update :reject_offers_outside_radius`. Explícitamente. La spec de AC9 te va a frenar si por error agregás uno.

**Cleanup oportunista** — si `transport_window.rb` todavía tiene el comment `# Phase 2: replace with PostGIS / proper geocoded matching (ADR-010)`, eliminarlo en este PR. Si ya lo eliminó [[REQ-BE-00036]] (que también lo toca), no es problema. Idempotente.

**Lenguaje** — todo el código en inglés. Strings de error vía symbolic keys + `config/locales/es.yml` / `en.yml`. Cero literales en español en controllers, models, scopes, helpers.

## Related

- US50 en `docs/artifacts/backlog-us.typ:729-747`.
- US5 (filtrado con radio) en `docs/artifacts/backlog-us.typ:109-128`.
- Glossary: «Radio de recogida» (`docs/05-appendices/glossary.md`).
- CLAUDE.md: «Database policy» — SQLite-forever, Haversine en app code, never PostGIS.
- Cliente FE: [[REQ-FE-00027]] (US50 — input + draggable circle).
- Sibling BE: [[REQ-BE-00036]] (US48/US49 — lat/lng en `transport_windows` + `cargos`).
- Eventual cliente del helper: [[FIX-BE-00001]] / endpoint de matching de US5.

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(fulfilment): ...` o `feat(matching): ...`), sin `[REQ-BE-00037]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Bloqueado por [[REQ-BE-00036]]** — el filtro Haversine necesita `origin_lat`/`origin_lng` en `transport_windows` y `pickup_lat`/`pickup_lng` en `cargos`. No abrir PR hasta que [[REQ-BE-00036]] esté mergeado (o branchear desde su branch).
- **Coordinar con [[FIX-BE-00001]]** — si el endpoint de matching de US5 está en cambio, alinear sobre dónde componer el nuevo scope.
- **Pre-PR check** (CLAUDE.md): `just lint`, `just backend-test` (SimpleCov no baja del baseline).

## Decisiones cerradas en triage (2026-05-24)

| Tema | Decisión |
|---|---|
| Anchor del radio | Pin publicado del `TransportWindow.origin_*`. **Nunca** GPS en vivo del Carrier. |
| Rango y default | 1–200 km. Default 10 (alineado con el FE; document en el PR). |
| Computación de distancia | Haversine en código Ruby. **Nunca** PostGIS. CLAUDE.md lo prohíbe. |
| Non-retroactividad | Cambiar el radio NO cancela ni rechaza `CargoOffer`s pending. Sin callbacks. |
| Lazy chain del scope | OK romperla — devolver `Array` o `where(id: ...)` según lo que el callsite necesite. |
| `transport_window.rb` Phase-2 comment | Eliminar acá si no lo eliminó [[REQ-BE-00036]] antes. |
