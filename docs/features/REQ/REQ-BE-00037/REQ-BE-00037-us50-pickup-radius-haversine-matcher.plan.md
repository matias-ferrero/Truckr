# REQ-BE-00037: `pickup_radius_km` column + Haversine matcher en el US5 scope (US50)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00037 |
| **Title** | pickup_radius_km column + Haversine matcher en el US5 scope (US50) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Sprint** | 4 |
| **Author** | Claude Code |
| **Depends On** | **Hard:** [[REQ-BE-00036]] (necesita `transport_windows.origin_*` y `cargos.pickup_*` para el Haversine). **Coordinación:** `FIX-BE-00001` (reescribe el endpoint de matching US5 — ahí se compone el nuevo scope). |
| **Decision Doc** | N/A — decisiones cerradas inline en el issue body. |
| **Selected Approach** | Single PR — migración `pickup_radius_km INTEGER NOT NULL DEFAULT 10`, validación de rango con constantes, strong-param, serializer, helper `Truckr::Geo.haversine_km` (nuevo namespace `backend/lib/truckr/`), scope `TransportWindow.within_pickup_radius_of(cargo)` que rompe la lazy chain (devuelve `where(id: ...)` para preservar composability con sort), integración en el endpoint de matching de US5, sin callbacks retroactivos. |

---

## 1. Problem Statement

El issue body (Backlog) tiene el spec completo, AC, decisiones cerradas y razones del diseño — leerlo primero.

Estado al arrancar:
- `transport_windows` no tiene `pickup_radius_km`.
- `backend/lib/truckr/` no existe — primer ocupante de ese namespace. Si se prefiere `backend/app/lib/`, usar ese; el spec del issue dice `backend/lib/truckr/geo.rb` y eso es perfectamente convencional para Rails.
- El endpoint de matching de US5 está en flight (`FIX-BE-00001`) — verificar dónde queda al momento del PR para componer el nuevo scope ahí (probablemente `TransportWindowsController#index` con un param `compatible_with_cargo=:id`, o un service object dedicado).
- `TransportWindow` está bloqueado contra "Phase-2 PostGIS" framing por CLAUDE.md y el cleanup de [[REQ-BE-00036]].
- `CargoOffer` tiene scopes por status (`pending`, etc.) — el spec de no-retroactividad verifica que `PATCH /api/transport_windows/:id` no las mute.

## 2. Solution Design

### 2.1 Estrategia — Haversine en código Ruby, scope no-lazy, sin callbacks

Decisión cerrada (CLAUDE.md «Database policy»): Haversine en Ruby, **nunca** SQL espacial. El scope rompe la chain (devuelve `where(id: ids)`) para preservar el shape `ActiveRecord::Relation` que el callsite necesita para `order(...)` y `limit(...)`.

Orden mecánico:

1. Migración `add_pickup_radius_km_to_transport_windows`.
2. Constantes + validación en `TransportWindow`.
3. Locales (reutilizar `:out_of_range` ya añadido por REQ-BE-00036; sumar `:blank` por presence si falta).
4. Strong param en `TransportWindowsController`.
5. Atributo en `TransportWindowResource`.
6. `Truckr::Geo.haversine_km` en `backend/lib/truckr/geo.rb` + autoloading.
7. `TransportWindow.within_pickup_radius_of(cargo)` (scope no-lazy: carga candidatos pre-filtrados, filtra en Ruby, devuelve `where(id: ids)`).
8. Integración con el endpoint de matching US5 — componer en el callsite (después de los pre-filtros baratos: vehículo, disponibilidad temporal, status open, etc.).
9. Sort por distancia cuando el query param lo pide.
10. Seeds actualizados (radius razonable, e.g. 50).
11. Specs: helper, scope, validations, no-retroactividad, request specs del endpoint US5.
12. Cleanup oportunista del Phase-2 PostGIS comment (idempotente con [[REQ-BE-00036]]).

### 2.2 Migración

```
db/migrate/20260525130000_add_pickup_radius_km_to_transport_windows.rb
```

```ruby
class AddPickupRadiusKmToTransportWindows < ActiveRecord::Migration[7.1]
  def change
    add_column :transport_windows, :pickup_radius_km, :integer, null: false, default: 10
  end
end
```

`default: 10` queda en la columna — explicitar en el PR body que el form FE manda el valor explícito (default UX = 10 también, alineado por coincidencia documentada, no por dependencia técnica). No quitar el default post-migración: la columna NOT NULL necesita un valor inicial para registros pre-existentes (factories, seeds) y para PATCH-without-radius edge cases (en cuyo caso queda el valor previo, no el default).

### 2.3 Validación

En `transport_window.rb`:

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

Locales: reutilizar `:blank`, `:not_a_number`, `:not_an_integer`, `:greater_than_or_equal_to`, `:less_than_or_equal_to` (Rails defaults). Sin literales nuevos.

### 2.4 Strong parameters + serializer

- `TransportWindowsController#transport_window_params` ← `:pickup_radius_km`.
- `TransportWindowResource` ← `attributes :pickup_radius_km`.

### 2.5 Helper `Truckr::Geo`

`backend/lib/truckr/geo.rb`:

```ruby
module Truckr
  module Geo
    EARTH_RADIUS_KM = 6371.0

    module_function

    def haversine_km(point_a, point_b)
      lat1, lng1 = point_a
      lat2, lng2 = point_b
      d_lat = to_rad(lat2 - lat1)
      d_lng = to_rad(lng2 - lng1)
      a = Math.sin(d_lat / 2)**2 +
          Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) *
          Math.sin(d_lng / 2)**2
      EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    end

    def to_rad(deg) = deg * Math::PI / 180
  end
end
```

Autoloading: `backend/config/application.rb` ya autocarga `lib/` o hay que agregarlo (`config.autoload_lib(ignore: %w[assets tasks])` en Rails 7.1). Verificar en el plan; si no, agregar la línea.

### 2.6 Scope `within_pickup_radius_of(cargo)`

```ruby
# Filters TransportWindows whose origin is within their own pickup_radius_km
# of the given Cargo's pickup point. Computes Haversine in Ruby — never SQL spatial,
# never PostGIS (CLAUDE.md "Database policy"). Breaks lazy chain by materialising the
# candidate set in memory, then returns a relation scoped by id so the callsite can
# still chain `.order(...)`, `.limit(...)`, etc.
scope :within_pickup_radius_of, ->(cargo) {
  pickup = [cargo.pickup_lat.to_f, cargo.pickup_lng.to_f]
  passing_ids = select(:id, :origin_lat, :origin_lng, :pickup_radius_km).find_each.filter_map { |window|
    distance = Truckr::Geo.haversine_km(
      [window.origin_lat.to_f, window.origin_lng.to_f], pickup
    )
    window.id if distance <= window.pickup_radius_km
  }
  where(id: passing_ids)
}
```

Forma `where(id: ids)` (no `Array`) para preservar la chainability con sort/limit en el callsite. Costo: el `find_each` consume los pre-filtros baratos del scope upstream (overlap temporal, vehículo, status) — confirmar en el callsite que el `within_pickup_radius_of` es el ÚLTIMO de la cadena.

### 2.7 Integración con el endpoint de matching de US5

Esperar a que `FIX-BE-00001` aterrice — modifica el shape del endpoint de matching. **Acción**: coordinar con el autor de `FIX-BE-00001` en el momento de planning; si todavía no aterrizó al abrir este PR, hacer rebase contra su branch.

Punto de inserción (esperado): `Api::TransportWindowsController#index` con `params[:compatible_with_cargo_id]`. Pseudocódigo de composición:

```ruby
scope = TransportWindow.open                                  # status filter
scope = scope.available_between(cargo.pickup_window_start,    # temporal pre-filter
                                cargo.pickup_window_end)
scope = scope.with_capacity_for(cargo)                        # vehicle pre-filter (FIX-BE-00001)
scope = scope.within_pickup_radius_of(cargo)                  # ← NEW (geographic)
scope = scope.order_by_distance_to(cargo) if sort == :distance
```

`order_by_distance_to(cargo)` (opcional acá si simplifica el callsite, o computar inline en el controller):

```ruby
scope :order_by_distance_to, ->(cargo) {
  pickup = [cargo.pickup_lat.to_f, cargo.pickup_lng.to_f]
  sorted = to_a.sort_by { |w|
    Truckr::Geo.haversine_km([w.origin_lat.to_f, w.origin_lng.to_f], pickup)
  }
  where(id: sorted.map(&:id)).order(Arel.sql("CASE id #{sorted.each_with_index.map { |w, i| "WHEN #{w.id} THEN #{i}" }.join(' ')} END"))
}
```

(El `CASE` preserva orden tras el `where(id: ...)`. Alternativa más limpia: devolver el array tras sort — chequear si el callsite necesita paginación; si sí, `where(id: ids).order(CASE...)`. Decisión en implementación según lo que `FIX-BE-00001` deje listo.)

### 2.8 No-retroactividad

**Cero callbacks.** Spec explícita:

```ruby
it "no toca CargoOffers pending al achicar el radio" do
  window = create(:transport_window, pickup_radius_km: 100, origin_lat: ..., origin_lng: ...)
  far_cargo = create(:cargo, pickup_lat: ..., pickup_lng: ...) # a ~80km
  offer = create(:cargo_offer, transport_window: window, cargo: far_cargo, status: :pending)

  expect { window.update!(pickup_radius_km: 5) }.not_to change { offer.reload.status }
end
```

Si alguien por error agrega `after_update :reject_offers_outside_radius`, este spec lo frena.

### 2.9 Cleanup

Eliminar el Phase-2 PostGIS comment en `transport_window.rb` si todavía está (idempotente con [[REQ-BE-00036]]).

## 3. Implementation Tasks

| # | Task | Layer | Files |
|---|------|-------|-------|
| 1 | Migración `add_pickup_radius_km_to_transport_windows` | DB | `backend/db/migrate/20260525130000_add_pickup_radius_km_to_transport_windows.rb` |
| 2 | Constantes + validación en `TransportWindow` | Model | `backend/app/models/transport_window.rb` |
| 3 | Strong param `:pickup_radius_km` | Controller | `backend/app/controllers/api/transport_windows_controller.rb` |
| 4 | Atributo en `TransportWindowResource` | Resource | `backend/app/resources/transport_window_resource.rb` |
| 5 | Helper `Truckr::Geo.haversine_km` | Lib | `backend/lib/truckr/geo.rb` |
| 6 | `config.autoload_lib` si falta | Config | `backend/config/application.rb` |
| 7 | Scope `within_pickup_radius_of` | Model | `backend/app/models/transport_window.rb` |
| 8 | Scope `order_by_distance_to` (o inline en controller) | Model/Controller | `backend/app/models/transport_window.rb` o callsite |
| 9 | Integración en el callsite de US5 (post `FIX-BE-00001`) | Controller/Service | depende de dónde aterrice `FIX-BE-00001` |
| 10 | Factory default `pickup_radius_km { 50 }` | Spec | `backend/spec/factories/transport_windows.rb` |
| 11 | Seeds: `pickup_radius_km` razonable | DB | `backend/db/seeds.rb` |
| 12 | RSpec lib (helper) | Spec | `backend/spec/lib/truckr/geo_spec.rb` |
| 13 | RSpec model (validations + scope) | Spec | `backend/spec/models/transport_window_spec.rb` |
| 14 | RSpec request (endpoint US5 con/sin radio, sort=distance, no-retroactividad) | Spec | `backend/spec/requests/api/transport_windows_spec.rb` (o el endpoint real) |
| 15 | Cleanup Phase-2 PostGIS comment | Model | `backend/app/models/transport_window.rb` |

## 4. Test Strategy

- **`Truckr::Geo.haversine_km` (lib spec)** — tabla:
  - CABA `[-34.6037, -58.3816]` ↔ Rosario `[-32.9468, -60.6393]` ≈ 280 km ± 2.
  - CABA ↔ Mar del Plata `[-38.0055, -57.5426]` ≈ 380 km ± 2.
  - CABA ↔ Mendoza `[-32.8895, -68.8458]` ≈ 985 km ± 5.
  - Mismo punto → 0.
  - Antípoda → ~20 015 km ± 50.
- **`TransportWindow` validations** — rechaza 0, 201, -1, 12.5, `"abc"`. Acepta 1 y 200.
- **Scope `within_pickup_radius_of`** — ventana CABA con radius 50 + cargo CABA → incluida. Ventana CABA radius 50 + cargo Rosario → excluida. Combina con scope `open` y temporal correctamente (preserva relation shape).
- **Request `GET /api/transport_windows?compatible_with_cargo_id=:id`** — cargo CABA + ventana CABA radius 50 → respuesta incluye la ventana. Cargo CABA + ventana Salta radius 50 → no incluye. Param `sort=distance` → orden ascendente por distancia.
- **No-retroactividad** — `PATCH .../:id` baja `pickup_radius_km` de 100 a 5; offers `pending` siguen `pending`.

`just backend-test` y `just lint` limpios.

## 5. Risks & Decision Points

- **Coordinación con `FIX-BE-00001`** (en flight) — este PR depende del endpoint de matching que `FIX-BE-00001` está reformando. **Decision needed**: ¿esperar a que `FIX-BE-00001` mergee y rebasear, o branchear desde su branch ahora? Recomendación: esperar el merge, rebasear; el orden secuencial reduce conflicts. Si el sprint apura, branchear desde `FIX-BE-00001`'s branch y rebasear a main post-merge.
- **`backend/lib/` autoloading** — Rails 7.1 requiere `config.autoload_lib` explícito. Si no está, autoload falla en runtime. Verificar y agregar si falta.
- **Costo del Haversine en código** — el scope materializa los IDs candidatos. Para volúmenes MVP (decenas/centenares de ventanas activas) es trivial. Si el volumen crece — **no se reconsidera**: SQLite-forever, no hay Phase-2. CLAUDE.md.
- **`order_by_distance_to` no chainable nativamente** — el `CASE id WHEN ... END` preserva orden pero es feo. Alternativa: el callsite del controller hace `to_a` después del filter, y aplica pagination en Ruby. Decidir en implementación según volumen esperado por respuesta (paginado o no).
- **Default `10` en la migración** — quirky pero correcto: la column NOT NULL necesita default para registros pre-form (factories, seeds, eventual PATCH parcial). El form FE también usa 10 por coincidencia documentada. Discrepa con el FE = bug.

## 6. Out of Scope

- Geolocalización en vivo del Carrier (decisión cerrada: anchor es el pin publicado de la ventana, no GPS en vivo).
- Callbacks retroactivos sobre `CargoOffer` (decisión cerrada — el radio es discoverability, no constraint retroactiva).
- Spatial indexes (CLAUDE.md).
- Cualquier UI — vive en [[REQ-FE-00027]].

## 7. Acceptance Criteria

Re-lectura del issue body Backlog AC1–AC12. Verificación local antes del PR:

- [ ] AC1 — `db:migrate` corre limpio sobre DB vacía y sobre DB con seeds existentes (el default cubre).
- [ ] AC2 — Specs de validación pasan.
- [ ] AC3 — Request spec de POST/PATCH inválido devuelve 422.
- [ ] AC4 — GET emite `pickup_radius_km`.
- [ ] AC5 — Helper spec con distancias conocidas dentro de ±2km (±5km Mendoza).
- [ ] AC6 — Scope spec verifica filter y composability.
- [ ] AC7 — Request spec del endpoint US5 verifica que el filtro radio excluye ventanas fuera de alcance.
- [ ] AC8 — `sort=distance` → respuesta ordenada ascendente.
- [ ] AC9 — Spec de no-retroactividad pasa.
- [ ] AC10 — `git diff` no introduce PostGIS / GIST / `unaccent` / Phase-2 / EXCLUDE.
- [ ] AC11 — `db:seed` corre limpio.
- [ ] AC12 — SimpleCov no baja del baseline.

## 8. Related

- Issue body: `.gdsi-sdlc/issues/Backlog/REQ-BE-00037-us50-pickup-radius-haversine-matcher.issue.md`.
- US50: `docs/artifacts/backlog-us.typ:729-747`.
- US5: `docs/artifacts/backlog-us.typ:109-128`.
- Glossary: `docs/05-appendices/glossary.md` — «Radio de recogida».
- CLAUDE.md «Database policy» — fundamento del «Haversine en código, never PostGIS».
- BE dep: [[REQ-BE-00036]].
- FE cliente: [[REQ-FE-00027]].
- Coordinación: `FIX-BE-00001` (matching endpoint en flight).
