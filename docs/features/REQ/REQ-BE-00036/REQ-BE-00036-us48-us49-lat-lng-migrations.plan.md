# REQ-BE-00036: Migraciones y validaciones de lat/lng para `TransportWindow` y `Cargo` (US48 + US49)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00036 |
| **Title** | Migraciones y validaciones de lat/lng para TransportWindow y Cargo (US48 + US49) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Sprint** | 4 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00021` (`TransportWindow` model + controller). `REQ-BE-00032` (`Cargo` model + `CargosController`). No code dep on `FIX-BE-00001` (parallel-safe — both touch `transport_window.rb`; coordinate rebase). |
| **Decision Doc** | N/A — decisiones cerradas inline en `.gdsi-sdlc/issues/Backlog/REQ-BE-00036-...issue.md` y mirror en `docs/05-appendices/glossary.md`. |
| **Selected Approach** | Single PR — dos migraciones simétricas, validaciones presence+range con symbolic keys, strong-params updates, serializer (Alba) emite las nuevas columnas, factories+seeds actualizados, cleanup oportunista del Phase-2 PostGIS comment en `transport_window.rb`. |

---

## 1. Problem Statement

El issue body (Backlog) contiene el spec completo, AC, y decisiones cerradas — leerlo primero. Este plan es el "cómo".

Estado al arrancar:
- `TransportWindow` (`backend/app/models/transport_window.rb`) tiene `origin_zone`/`destination_zone` (strings + diacritic-normalized scope). Mantiene el comment `# Phase 2: replace with PostGIS / proper geocoded matching (ADR-010)` — viola CLAUDE.md «Database policy» y debe eliminarse acá.
- `Cargo` (`backend/app/models/cargo.rb`) tiene `pickup_address`/`delivery_address` (strings) + `pickup_zone`/`delivery_zone`. No tiene coords.
- `Api::TransportWindowsController#transport_window_params` permite zones + temporal/precio attrs; no coords.
- `Api::CargosController#cargo_params` permite address+zone+window+payload; no coords.
- `TransportWindowResource` (Alba) y `CargoResource` (Alba) no emiten coords (no existen aún).
- `ShipmentResource` (REQ-BE-00035, en flight) **no emite** las coords del Cargo asociado — confirmado en recon. Hay que sumarlas acá (issue AC8 — fold-in, no nuevo TAG).
- No hay `backend/lib/truckr/` namespace todavía (lo crea `REQ-BE-00037`).
- Factories `transport_windows.rb` y `cargos.rb` no emiten coords.
- `seeds.rb` existe pero no tiene coords.

Las dos features FE (US48/US49) están bloqueadas hasta que las columnas existan y los serializers las emitan. US51 también depende de que `ShipmentResource` incluya pickup/delivery del Cargo asociado.

## 2. Solution Design

### 2.1 Estrategia — un PR, dos migraciones simétricas

Combinar US48+US49 BE en un PR (decisión cerrada en triage): migraciones triviales, validaciones simétricas, strong-params one-liners. Splitear sólo si el diff explota más allá de ~400 líneas.

Orden mecánico dentro del PR (commit por capa, no por user story):

1. Migraciones — `transport_windows` (4 cols, `origin_*` NOT NULL, `destination_*` nullable) + `cargos` (4 cols, todas NOT NULL).
2. Modelos — validaciones presence+range con symbolic keys; `Cargo` sin XOR (todas obligatorias); `TransportWindow` con XOR `destination_pin_consistency`.
3. Locales — `config/locales/es.yml` + `en.yml`: `out_of_range`, `inconsistent_with_text` (las que falten — reutilizar `:invalid_format`/`:blank` existentes).
4. Controllers — strong params en `TransportWindowsController` y `CargosController`.
5. Resources (Alba) — `TransportWindowResource`, `CargoResource`, `ShipmentResource` (detail expansion del cargo block en REQ-BE-00035).
6. Factories — `transport_windows.rb` y `cargos.rb` emiten coords plausibles de AR (Faker o constantes — preferir constantes inline para determinismo).
7. Seeds — coords plausibles AR (CABA / Rosario / Mar del Plata / Mendoza).
8. Cleanup — eliminar el comment Phase-2 PostGIS en `transport_window.rb`.

### 2.2 Migraciones

Sample, naming `{YYYYMMDDHHMMSS}_{snake}.rb` consistente con `20260524000000_update_shipment_statuses_for_payment_flow.rb`:

```
db/migrate/20260525120000_add_coordinates_to_transport_windows.rb
db/migrate/20260525120001_add_coordinates_to_cargos.rb
```

Cuerpo exacto en el issue body (sección "Expected Behavior → Migración 1/2"). Confirmar antes de migrar que `db/schema.rb` no tenga filas legacy (`Rails.env.development? && TransportWindow.count == 0` o `db:reset` previo).

**Sin spatial indexes. Sin defaults sobre `transport_windows.origin_*` ni sobre `cargos.*_lat/lng`** (NOT NULL puro — el form siempre los manda). Sin "Phase-2" comments.

### 2.3 Validaciones

`TransportWindow`:

```ruby
LAT_RANGE = -90..90
LNG_RANGE = -180..180

validates :origin_lat, presence: true,
                       numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
validates :origin_lng, presence: true,
                       numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
validates :destination_lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 },
                            allow_nil: true
validates :destination_lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 },
                            allow_nil: true
validate :destination_pin_consistency

def destination_pin_consistency
  present = [destination_zone, destination_lat, destination_lng].map(&:present?)
  return if present.all? || present.none?
  errors.add(:destination_lat, :inconsistent_with_text) if destination_lat.blank? && destination_zone.present?
  errors.add(:destination_lng, :inconsistent_with_text) if destination_lng.blank? && destination_zone.present?
end
```

Nota: `FIX-BE-00001` hace `destination_zone` nullable. Coordinar rebase — el XOR se reescribe como «si CUALQUIERA de los tres (text+lat+lng) está presente, los TRES deben estarlo».

`Cargo`:

```ruby
%i[pickup_lat delivery_lat].each do |attr|
  validates attr, presence: true,
                  numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
end
%i[pickup_lng delivery_lng].each do |attr|
  validates attr, presence: true,
                  numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
end
```

### 2.4 Locales

`config/locales/es.yml` y `en.yml` — añadir bajo `activerecord.errors.models.transport_window.attributes.*` y `cargo.attributes.*`:

```yaml
es:
  activerecord:
    errors:
      messages:
        out_of_range: "fuera de rango"
        inconsistent_with_text: "debe estar presente cuando hay dirección de destino"
```

Reutilizar `:blank` y `:not_a_number` (Rails defaults). Cero literales hardcodeados.

### 2.5 Strong parameters

`TransportWindowsController#transport_window_params` — agregar `:origin_lat, :origin_lng, :destination_lat, :destination_lng`.

`CargosController#cargo_params` — agregar `:pickup_lat, :pickup_lng, :delivery_lat, :delivery_lng`.

### 2.6 Resources (Alba)

- `TransportWindowResource` — `attributes :origin_lat, :origin_lng, :destination_lat, :destination_lng` (a continuación de los zone fields).
- **Emisión de lat/lng del `Cargo` (pickup/delivery) en `CargoResource` y en el bloque `cargo` del `ShipmentResource`:** propiedad de [[REQ-BE-00035]] — ver `docs/features/REQ/REQ-BE-00035/REQ-BE-00035-envios-index-endpoints.plan.md` (sección de ShipmentResource / CargoResource) para el contrato de emisión de cargo lat/lng. Este plan no duplica ni contradice ese contrato; cualquier ajuste al shape JSON del Cargo se decide allí.

JSON shape del `TransportWindowResource` — columnas planas snake_case, no objetos anidados (confirmar contrato con [[REQ-FE-00025]] en el PR body):

```json
{
  "id": 1,
  "origin_zone": "CABA",
  "origin_lat": -34.603722,
  "origin_lng": -58.381592,
  "destination_zone": null,
  "destination_lat": null,
  "destination_lng": null
}
```

### 2.7 Factories

`spec/factories/transport_windows.rb`:

```ruby
origin_lat { -34.603722 }   # CABA
origin_lng { -58.381592 }
destination_lat { nil }
destination_lng { nil }
```

`spec/factories/cargos.rb`:

```ruby
pickup_lat { -34.603722 }      # CABA pickup
pickup_lng { -58.381592 }
delivery_lat { -32.946820 }    # Rosario delivery
delivery_lng { -60.639317 }
```

Constantes inline (no Faker) para determinismo en specs.

### 2.8 Seeds

`backend/db/seeds.rb` — cualquier `TransportWindow.create!` y `Cargo.create!` existente recibe coords de AR. Mantener correlación con el `*_zone` que ya esté seteado (CABA si zona dice "CABA", etc.). Sin esto, `db:seed` revienta con la validación NOT NULL.

### 2.9 Cleanup oportunista

Eliminar de `backend/app/models/transport_window.rb` el bloque:

```ruby
# Phase 2: replace with PostGIS / proper geocoded matching (ADR-010)
```

Idempotente — si `REQ-BE-00037` lo elimina primero, este PR ve diff vacío. CLAUDE.md "Database policy" lo prohíbe explícitamente.

## 3. Implementation Tasks

| # | Task | Layer | Files |
|---|------|-------|-------|
| 1 | Migración `add_coordinates_to_transport_windows` | DB | `backend/db/migrate/20260525120000_add_coordinates_to_transport_windows.rb` |
| 2 | Migración `add_coordinates_to_cargos` | DB | `backend/db/migrate/20260525120001_add_coordinates_to_cargos.rb` |
| 3 | Validaciones + `destination_pin_consistency` en `TransportWindow` | Model | `backend/app/models/transport_window.rb` |
| 4 | Validaciones lat/lng en `Cargo` | Model | `backend/app/models/cargo.rb` |
| 5 | Locales `out_of_range` + `inconsistent_with_text` | i18n | `backend/config/locales/es.yml`, `en.yml` |
| 6 | Strong params en `TransportWindowsController` | Controller | `backend/app/controllers/api/transport_windows_controller.rb` |
| 7 | Strong params en `CargosController` | Controller | `backend/app/controllers/api/cargos_controller.rb` |
| 8 | Atributos en `TransportWindowResource` | Resource | `backend/app/resources/transport_window_resource.rb` |
| 9 | Atributos en `CargoResource` | Resource | `backend/app/resources/cargo_resource.rb` |
| 10 | Emisión de cargo lat/lng en `ShipmentResource` — **propiedad de [[REQ-BE-00035]]**, ver su plan. La emisión de lat/lng del `TransportWindow` vive en la tarea #8 de este plan. | Resource | (sin archivo en este PR) |
| 11 | Factories con coords default | Spec | `backend/spec/factories/transport_windows.rb`, `cargos.rb` |
| 12 | Seeds actualizados | DB | `backend/db/seeds.rb` |
| 13 | Cleanup Phase-2 PostGIS comment | Model | `backend/app/models/transport_window.rb` |
| 14 | RSpec model specs (validations + XOR) | Spec | `backend/spec/models/transport_window_spec.rb`, `cargo_spec.rb` |
| 15 | RSpec request specs (422 shape, GET payload) | Spec | `backend/spec/requests/api/transport_windows_spec.rb`, `cargos_spec.rb`, `shipments_spec.rb` |

## 4. Test Strategy

Cobertura exigida — SimpleCov no baja del baseline actual; los tests específicos de RSpec listados en el issue body (`### Tests requeridos`) son el mínimo. Notas:

- **Model spec `TransportWindow`** — happy path (origen seteado, destino nulo OK), rango (`-91`, `91`, `-181`, `181` fallan), XOR (text+lat sin lng falla; los tres presentes OK; los tres ausentes OK).
- **Model spec `Cargo`** — las cuatro presence + range. Sin XOR.
- **Request spec `POST /api/transport_windows`** — payload sin `origin_lat` → 422 con `{ errors: { origin_lat: [...] } }` (shape consistente con resto de la API; verificar el formatter existente — `RenderableError` o equivalente). Payload con destino parcial (text sin coords) → 422 sobre `destination_lat`/`destination_lng`.
- **Request spec `POST /api/cargos`** — payload sin `delivery_lng` → 422.
- **Request spec `GET /api/transport_windows/:id`** — payload incluye los 4 campos.
- **Request spec `GET /api/cargos/:id`** — payload incluye los 4 campos.
- **Request spec `GET /api/shipments/:id`** (la detail expansion de REQ-BE-00035) — `cargo.pickup_lat`, `cargo.pickup_lng`, `cargo.delivery_lat`, `cargo.delivery_lng` presentes. Si REQ-BE-00035 mergea antes, este spec lo extiende; si después, REQ-BE-00035 lo absorbe.

`just backend-test` (RSpec + SimpleCov) y `just lint` (prek) deben pasar limpio antes del PR.

## 5. Risks & Decision Points

- **Coordinación con REQ-BE-00035 (ShipmentResource detail)** — riesgo de doble edit / merge conflict. **Decision needed from user**: ¿se hace primero REQ-BE-00035 y este PR lo extiende, o ambos PRs avanzan en paralelo con coordinación verbal? Recomendación: que REQ-BE-00035 mergee primero y este PR sólo añada los 4 atributos lat/lng al bloque `cargo`. Si no es posible, hacer rebase y resolver el conflict.
- **Coordinación con FIX-BE-00001 (`destination_zone` nullable)** — ambos PRs tocan `transport_window.rb`. Si FIX-BE-00001 mergea primero, el XOR `destination_pin_consistency` se reescribe trivialmente para reflejar que `destination_zone` también es nullable. Si este mergea primero, FIX-BE-00001 ajusta el XOR al pasar. No es un blocker, sólo orden cosmético.
- **Cleanup del comment Phase-2** — idempotente; si REQ-BE-00037 sale antes, este PR ve diff vacío en esa línea. Ningún riesgo.
- **Factories deterministas** — usar Faker para lat/lng podría introducir tests flakey de rango. Decisión cerrada: constantes inline (CABA + Rosario). Sin Faker.
- **Sin backfill** — la migración explota si por algún motivo hay filas existentes sin coords. Confirmar dev/test/CI con `db:reset` o migrate sobre DB vacía. No hay producción.

## 6. Out of Scope

- Reverse geocoding server-side (decisión cerrada — UI-only via `componentRestrictions`).
- Bounding-box validation AR server-side (idem).
- Cualquier scope geográfico (Haversine, `within_pickup_radius_of`) — vive en [[REQ-BE-00037]].
- Cualquier cambio FE — vive en [[REQ-FE-00025]] / [[REQ-FE-00026]].

## 7. Acceptance Criteria

Re-lectura del issue body Backlog AC1–AC11; este plan no los duplica. Verificación local antes del PR:

- [ ] AC1–AC2 — `bundle exec rails db:migrate` corre limpio en una DB de cero.
- [ ] AC3–AC5 — `just backend-test` pasa los specs nuevos de validations + XOR.
- [ ] AC6 — request specs verifican 422 shape.
- [ ] AC7–AC8 — request specs verifican payload de GET con los 4 campos y `ShipmentResource` con cargo coords.
- [ ] AC9 — `bundle exec rails db:seed` corre limpio.
- [ ] AC10 — SimpleCov no baja del baseline (revisar `backend/coverage/index.html`).
- [ ] AC11 — `git diff` no agrega ningún comentario "Phase-2", "PostGIS", "unaccent", "citext", "EXCLUDE". `grep -ri postgis backend/` después del cleanup devuelve sólo refs históricas en `docs/`.

## 8. Related

- Issue body: `.gdsi-sdlc/issues/Backlog/REQ-BE-00036-us48-us49-lat-lng-migrations.issue.md`.
- US48 / US49: `docs/artifacts/backlog-us.typ:688-727`.
- Glossary: `docs/05-appendices/glossary.md` — «Ventana de transporte», «Carga».
- CLAUDE.md «Database policy».
- BE sibling: [[REQ-BE-00037]] (pickup_radius_km + Haversine).
- FE clientes: [[REQ-FE-00025]], [[REQ-FE-00026]], [[REQ-FE-00027]], [[REQ-FE-00028]].
- BE coordinación: REQ-BE-00035 (ShipmentResource), FIX-BE-00001 (destination nullable).
