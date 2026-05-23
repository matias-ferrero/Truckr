# FIX-BE-00001: Permitir destino nullable en TransportWindow (US4/US5 rework)

| Field | Value |
|-------|-------|
| **Tag** | FIX-BE-00001 |
| **Title** | Permitir destino nullable en TransportWindow (US4/US5 rework) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-22 |
| **Updated** | 2026-05-22 |
| **Author** | Claude Code |
| **Depends On** | Ninguna — US4/US5 ya implementadas (`REQ-FE-00006`, `REQ-BE-00021`); este fix amplía su alcance. |
| **Decision Doc** | N/A — fix scope, decisión tactical capturada inline en §2.3. |
| **Selected Approach** | Fullstack en un solo PR: migración + modelo + controller (search) + serializers (2) + content bundles + form/list/match UI + specs (RSpec, Vitest, Playwright). |

---

## 1. Problem Statement

US4 (búsqueda de ventanas) y US5 (filtrado) están implementadas y funcionando en `Api::TransportWindowsController#index` vía Ransack contra `origin_zone_normalized_cont` y `destination_zone_normalized_cont`. El producto contempla "ventanas de destino abierto" — un Carrier publica que está dispuesto a llevar carga desde un origen fijo a cualquier destino dentro de su radio operativo — pero el schema y el modelo bloquean el caso:

- `backend/db/schema.rb` → `t.string "destination_zone", null: false` en `transport_windows`.
- `backend/app/models/transport_window.rb:11` → `validates :origin_zone, :destination_zone, presence: true`.
- `normalize_search_fields` (mismo archivo, línea 39) ya guardea con `if destination_zone.present?`, así que la transliteración tolera nulos — el bloqueo real es schema + validator.

Resultado: el Carrier no puede publicar la ventana abierta y el listado US4/US5 nunca devuelve ese tipo de oferta. Es brecha de US4/US5, no una US nueva.

---

## 2. Solution Design

### 2.1 Approach

Cinco capas en un solo PR fullstack (no se puede partir BE/FE: el FE depende del schema nullable para distinguir el null y renderizar el label):

1. **Backend schema** — migración + actualización de `schema.rb`.
2. **Backend modelo + controller + serializers** — relajar el validator + extender el filtro de búsqueda + emitir `null` limpio.
3. **Backend specs** — request specs cubriendo create con destino vacío, search OR-with-NULL, no-regression con destino fijo.
4. **Frontend types + content + UI** — tipo `string | null`, nuevas keys i18n, render condicional en form/list/match.
5. **Frontend specs** — Vitest para el render condicional + Playwright e2e para el flujo de publicar ventana abierta.

### 2.2 Key Components

#### Backend

- **Migración** — `backend/db/migrate/YYYYMMDDHHMMSS_relax_destination_zone_on_transport_windows.rb`: `change_column_null :transport_windows, :destination_zone, true`. SQLite-friendly (no Postgres-isms). Sin data backfill porque no hay filas en prod (academic project).
- **Schema** — `backend/db/schema.rb`: regenerado automáticamente con `db:migrate`, drop el `null: false` de `destination_zone`.
- **Modelo** — `backend/app/models/transport_window.rb:11`: cambiar `validates :origin_zone, :destination_zone, presence: true` → `validates :origin_zone, presence: true`. `normalize_search_fields` ya tolera nulo (no requiere cambio).
- **Controller** — `backend/app/controllers/api/transport_windows_controller.rb`: refactorizar el filtro de destino fuera de Ransack para soportar OR-con-NULL (ver §2.3 Decision A).
- **Serializers** — `backend/app/resources/transport_window_resource.rb` y el bloque `transport_windows` en `backend/app/resources/carrier_search_resource.rb`: Alba ya emite `nil` como JSON `null` por default, **pero** verificar explícitamente con un spec que el wire format es `"destination_zone": null` (no string vacío). No requiere código nuevo salvo que falle el assert.

#### Frontend

- **Tipos** — `frontend/src/api/transport_windows.ts:15` y `:41`: `destination_zone: string | null`. `frontend/src/types/Cargo.ts:44` (`CargoMatch`): mismo cambio.
- **Content bundles** — `frontend/src/pages/carrier/carrierContent.ts` y `frontend/src/features/cargo/cargosContent.ts`: agregar key `destinationAny` (es-AR: `"Destino abierto"`) bajo `availability` y `match` respectivamente. También helper text para el form: `destinationHelper` (es-AR: `"Dejá vacío si aceptás cargas a cualquier destino dentro de tu radio"`). NUNCA hardcodear el string — convención del repo (CLAUDE.md § Language policy + carve-out de `landingContent.ts`).
- **Form** — `frontend/src/pages/carrier/TransportWindowForm.tsx`: input `destination_zone` deja de ser `required`. Helper text visible. En el submit, mapear `"" → null` antes de enviar. Mostrar el helper text bajo el input.
- **List** — `frontend/src/pages/carrier/TransportWindowList.tsx:194,196,234,235,305`: reemplazar interpolaciones `${tw.origin_zone} → ${tw.destination_zone}` por un helper `formatRoute(origin, destination)` que devuelva `${origin} → ${destination ?? t.destinationAny}`. Mismo helper para los `aria-label`.
- **MatchCard** — `frontend/src/features/cargo/MatchCard.tsx:28-31`: idem — `cargosContent.list.route(origin, destination)` debe tolerar `destination: string | null`. Actualizar la signature `route: (from: string, to: string | null)` y delegar el fallback a la function.
- **Glossary** — `docs/05-appendices/glossary.md`: nueva entrada `Destino abierto / Open destination — TransportWindow sin destination_zone; el Carrier acepta cargas dentro de su radio operativo`.

### 2.3 Decisiones Tácticas

#### Decisión A — Ransack OR con NULL: extraer el filtro de destino fuera de Ransack

**Decisión:** dejar Ransack en el controller para origen + fechas; aplicar el filtro de destino con un `.where("destination_zone_normalized LIKE ? OR destination_zone_normalized IS NULL", "%#{normalized}%")` sobre el resultado de Ransack.

**Por qué (sobre las 3 alternativas del issue):**

| Alt | Forma | Pro | Contra |
|---|---|---|---|
| 1. Preprocesar params y armar scope a mano | bypass total de Ransack | trivial control | duplica la lógica de origen/fechas |
| 2. Custom Ransack predicate | declarativo | reusable | API privada de Ransack, fragil entre versiones |
| **3. Ransack + `.where(...) IS NULL`** | combinación | preserva el scope de origen/fechas; OR explícito y testeable | dos llamadas en lugar de una |

Alt 3 gana: cambio quirúrgico de **una línea adicional** después del `q.result(...)`, no toca el resto del pipeline (date validation, `policy_scope`, agrupación por carrier, Pagy).

#### Decisión B — `null` semántica unificada en wire format

**Decisión:** ambos serializers (`TransportWindowResource` y `CarrierSearchResource`) emiten `destination_zone: null` cuando es nullo. **No** emitir string vacío, no emitir un boolean `open_destination`, no omitir el field.

**Por qué:** un solo wire-level sentinel que el FE tipa como `string | null`. Cualquier "ergonomic flag" derivado (`isOpenDestination`) lo computa el FE.

#### Decisión C — Migración sin data backfill

**Decisión:** la migración solo flippea `null: false → null: true`. No hace `update_all` ni `down` con backfill — el `down` simplemente vuelve a `null: false` (asumiendo que no hubo inserts con `NULL` post-deploy; aceptable para coursework sin prod).

**Por qué:** SQLite + zero-prod-data = no hay riesgo. Mantiene la migración leíble en una línea.

#### Decisión D — Form mappea `"" → null` en el submit, no en cada `onChange`

**Decisión:** el state local del form sigue siendo `destination_zone: string`. Solo en el `submit` se convierte `""` → `null` antes de mandar al API client.

**Por qué:** evita cambios invasivos en el componente; los inputs HTML controlados naturalmente trabajan con `""`. La conversión es de borde, no de UI state.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Generar migración `relax_destination_zone_on_transport_windows` | Pending | `backend/db/migrate/YYYYMMDDHHMMSS_*.rb`, `backend/db/schema.rb` (auto) |
| 2 | Sacar `destination_zone` del validator `presence: true` | Pending | `backend/app/models/transport_window.rb` |
| 3 | Extender controller con `.where(OR IS NULL)` post-Ransack | Pending | `backend/app/controllers/api/transport_windows_controller.rb` |
| 4 | Agregar request specs (US4 OR-con-NULL + create con destino vacío + no-regresión) | Pending | `backend/spec/requests/api/transport_windows_spec.rb`, `backend/spec/requests/api/carriers/me/transport_windows_spec.rb` |
| 5 | Verificar wire format `null` en specs de serializer | Pending | `backend/spec/resources/transport_window_resource_spec.rb` (crear si no existe) |
| 6 | TypeScript: `destination_zone: string \| null` en `transport_windows.ts` y `Cargo.ts` | Pending | `frontend/src/api/transport_windows.ts`, `frontend/src/types/Cargo.ts` |
| 7 | Agregar `destinationAny` + `destinationHelper` a content bundles | Pending | `frontend/src/pages/carrier/carrierContent.ts`, `frontend/src/features/cargo/cargosContent.ts` |
| 8 | Form: destino opcional + helper text + mapeo `"" → null` en submit | Pending | `frontend/src/pages/carrier/TransportWindowForm.tsx` |
| 9 | List: helper `formatRoute` reemplaza interpolaciones | Pending | `frontend/src/pages/carrier/TransportWindowList.tsx` |
| 10 | MatchCard / cargosContent.route: tolerar null | Pending | `frontend/src/features/cargo/MatchCard.tsx`, `frontend/src/features/cargo/cargosContent.ts` |
| 11 | Vitest: render del label en list, match, form | Pending | `frontend/src/pages/carrier/TransportWindowList.test.tsx`, `frontend/src/features/cargo/MatchCard.test.tsx`, `frontend/src/pages/carrier/TransportWindowForm.test.tsx` |
| 12 | Playwright e2e: publicar ventana de destino abierto | Pending | `frontend/playwright/...` (nuevo spec) |
| 13 | Glossary: entrada "Destino abierto / Open destination" | Pending | `docs/05-appendices/glossary.md` |
| 14 | Quality gate pre-PR: `/critique` → `/polish` → `/audit` + `just lint` + `just frontend-test-coverage` + `just frontend-test-e2e` + `just backend-test` | Pending | — |

---

## 4. Code Changes

### 4.1 `backend/db/migrate/YYYYMMDDHHMMSS_relax_destination_zone_on_transport_windows.rb`

**Purpose:** permitir `NULL` en `transport_windows.destination_zone`.

```ruby
class RelaxDestinationZoneOnTransportWindows < ActiveRecord::Migration[8.0]
  def up
    change_column_null :transport_windows, :destination_zone, true
  end

  def down
    change_column_null :transport_windows, :destination_zone, false
  end
end
```

### 4.2 `backend/app/models/transport_window.rb` (línea 11)

**Antes:**

```ruby
validates :origin_zone, :destination_zone, presence: true
```

**Después:**

```ruby
validates :origin_zone, presence: true
```

(`normalize_search_fields` líneas 38-41 no se tocan — ya tolera `destination_zone` nulo via `if destination_zone.present?`.)

### 4.3 `backend/app/controllers/api/transport_windows_controller.rb`

**Antes (líneas 28-39):**

```ruby
q = base_scope.ransack(
  origin_zone_normalized_cont:      params[:origin_zone],
  destination_zone_normalized_cont: params[:destination_zone],
  available_from_lteq:              date_to.end_of_day,
  available_to_gteq:                date_from.beginning_of_day
)
windows = q.result(distinct: true).includes(vehicle: :carrier).order(:available_from)
```

**Después:**

```ruby
q = base_scope.ransack(
  origin_zone_normalized_cont: params[:origin_zone],
  available_from_lteq:         date_to.end_of_day,
  available_to_gteq:           date_from.beginning_of_day
)
normalized_destination = I18n.transliterate(params[:destination_zone].to_s).downcase
windows = q.result(distinct: true)
  .where(
    "destination_zone_normalized LIKE :term OR destination_zone_normalized IS NULL",
    term: "%#{normalized_destination}%"
  )
  .includes(vehicle: :carrier)
  .order(:available_from)
```

### 4.4 `frontend/src/api/transport_windows.ts` (líneas 15, 41)

**Antes:**

```ts
destination_zone: string;
```

**Después:**

```ts
destination_zone: string | null;
```

### 4.5 `frontend/src/pages/carrier/carrierContent.ts` (en `availability`)

**Agregar bajo el form y la list:**

```ts
destinationAny: "Destino abierto",
destinationHelper: "Dejá vacío si aceptás cargas a cualquier destino dentro de tu radio",
formatRoute: (from: string, to: string | null) =>
  `${from} → ${to ?? "Destino abierto"}`, // resolved via destinationAny in callers if preferred
```

(Equivalente helper en `cargosContent.ts` para `MatchCard`.)

### 4.6 `frontend/src/pages/carrier/TransportWindowList.tsx`

Reemplazar las 4 interpolaciones inline por:

```tsx
const route = t.formatRoute(tw.origin_zone, tw.destination_zone);
// ...
<span title={route}>{route}</span>
// y los aria-label idem.
```

### 4.7 `frontend/src/features/cargo/cargosContent.ts` (línea 147)

**Antes:**

```ts
route: (from: string, to: string) => `${from} → ${to}`,
```

**Después:**

```ts
route: (from: string, to: string | null) =>
  `${from} → ${to ?? "Destino abierto"}`,
```

(El literal sigue saliendo del content bundle — no hardcoded en JSX.)

### 4.8 `frontend/src/pages/carrier/TransportWindowForm.tsx`

- Quitar `required` del input `destination_zone` (línea ~234).
- Agregar `<small className="formHelper">{f.fields.destinationHelper}</small>` debajo del input.
- En el submit (línea ~123): `destination_zone: draft.destination_zone.trim() || null`.

### 4.9 `docs/05-appendices/glossary.md`

**Agregar:**

```markdown
| **Destino abierto** | _Open destination_ | `TransportWindow` sin `destination_zone`; el Carrier acepta cargas dentro de su radio operativo. Aplica a US4/US5. |
```

(Insertar manteniendo el orden alfabético / agrupado por bounded context — chequear el formato real del archivo al editar.)

---

## 5. Testing

### Unit / Request Tests (RSpec)

- **Model**: factory `:transport_window` puede instanciarse con `destination_zone: nil`; validator no se queja.
- **Request — US4 search OR-con-NULL**:
  - Seed: ventana A (`destination_zone: "Córdoba"`), ventana B (`destination_zone: nil`), ambas en el rango de fechas y con origen "Buenos Aires".
  - `GET /api/transport_windows?origin_zone=Buenos&destination_zone=Cordoba&...` → devuelve **A y B**.
  - `GET /api/transport_windows?origin_zone=Buenos&destination_zone=Rosario&...` → devuelve solo B.
- **Request — no-regresión**: las specs existentes en `backend/spec/requests/api/transport_windows_spec.rb` siguen verdes sin cambios (excepto el assert de tamaño donde ahora pueda colarse una ventana abierta — verificar).
- **Request — create**: `POST /api/carriers/me/transport_windows` con `destination_zone: ""` o ausente → 201, `destination_zone == nil` en DB.
- **Resource — wire format**: serializar una ventana con `destination_zone: nil` → JSON contiene `"destination_zone": null` (no `""`, no omitido).

### Vitest (Frontend)

- `TransportWindowList.test.tsx`: render con `destination_zone: null` muestra "Destino abierto" (resolved via content bundle, no literal).
- `MatchCard.test.tsx`: idem en el `<span class="matchRoute">`.
- `TransportWindowForm.test.tsx`: enviar form con destino vacío → `createTransportWindow` recibe `destination_zone: null` (no `""`).

### Playwright E2E

- Nuevo spec: Carrier logueado → `/carrier/availability/new` → completa origen + fechas + precio, deja destino vacío → submit → list muestra la ventana con "Destino abierto".

### Coverage

- Mantener thresholds de `frontend/vitest.config.ts` (80% lines/functions/branches/statements). El nuevo helper `formatRoute` y el branch `?? destinationAny` deben quedar cubiertos por los tests del punto 1.

---

## 6. Acceptance Criteria

- [ ] Un transportista puede publicar una `TransportWindow` sin especificar destino (request spec verde + form FE).
- [ ] La búsqueda US4 incluye ventanas de destino abierto cuando el expedidor filtra por destino (request spec OR-con-NULL).
- [ ] La búsqueda US4 sigue respetando el filtro de origen y demás criterios (no se relaja origen ni fechas).
- [ ] El listado US4/US5 muestra el label de destino abierto vía content bundle (`destinationAny`) cuando la ventana no tiene destino — **nunca hardcoded en JSX**.
- [ ] El detalle público / `MatchCard` muestra el mismo label.
- [ ] Ventanas con destino fijo siguen comportándose igual — specs existentes verdes.
- [ ] Migración corre limpia en SQLite (CI verde).
- [ ] Vitest cubre el render condicional en List, Match y Form.
- [ ] Playwright e2e cubre el flujo "publicar ventana de destino abierto".
- [ ] Glossary actualizado con la entrada "Destino abierto / Open destination".
- [ ] PR title: `fix(marketplace): allow nullable destination on TransportWindow` (Conventional, sin `[TAG]` prefix). Body: `Closes #211`. `gh pr create --assignee @me`.
- [ ] Quality gate pre-PR (`/critique` → `/polish` → `/audit` + `just lint` + tests) corrido y limpio.

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `backend/db/migrate/YYYYMMDDHHMMSS_relax_destination_zone_on_transport_windows.rb` | Migración que relaja el NOT NULL. |
| `backend/spec/resources/transport_window_resource_spec.rb` | Spec del wire format `null` (solo si no existe ya). |
| `frontend/playwright/transport-window-open-destination.spec.ts` | E2E nuevo del flujo de publicación. |

### Modified Files

| File | Changes |
|------|---------|
| `backend/db/schema.rb` | Regenerado por `db:migrate`: `destination_zone` ya sin `null: false`. |
| `backend/app/models/transport_window.rb` | Línea 11: sacar `destination_zone` del validator `presence: true`. |
| `backend/app/controllers/api/transport_windows_controller.rb` | Refactor del filtro de destino fuera de Ransack: OR-con-NULL inline. |
| `backend/spec/requests/api/transport_windows_spec.rb` | Nuevos casos: search OR-con-NULL + verificar no-regresión. |
| `backend/spec/requests/api/carriers/me/transport_windows_spec.rb` | Nuevo caso: create con `destination_zone: nil`. |
| `frontend/src/api/transport_windows.ts` | Tipo `destination_zone: string \| null` en 2 interfaces. |
| `frontend/src/types/Cargo.ts` | Línea 44: `destination_zone: string \| null` en `CargoMatch`. |
| `frontend/src/pages/carrier/carrierContent.ts` | Nuevas keys `destinationAny` + `destinationHelper` + helper `formatRoute`. |
| `frontend/src/features/cargo/cargosContent.ts` | `route` helper tolera `null`; nueva key implícita "Destino abierto". |
| `frontend/src/pages/carrier/TransportWindowForm.tsx` | Destino opcional, helper text, submit mapea `"" → null`. |
| `frontend/src/pages/carrier/TransportWindowList.tsx` | Reemplazar las 4 interpolaciones por `t.formatRoute(...)`. |
| `frontend/src/features/cargo/MatchCard.tsx` | Pasar `destination_zone: string \| null` al `route` helper. |
| `frontend/src/pages/carrier/TransportWindowList.test.tsx` | Cobertura del render con `destination_zone: null`. |
| `frontend/src/features/cargo/MatchCard.test.tsx` | Idem. |
| `frontend/src/pages/carrier/TransportWindowForm.test.tsx` | Cobertura del submit con destino vacío. |
| `docs/05-appendices/glossary.md` | Nueva entrada "Destino abierto / Open destination". |
| `docs/features/ISSUES-INDEX.md` | Row de FIX-BE-00001: link al plan. |
| `.gdsi-sdlc/issues/Ready/FIX-BE-00001-permitir-destino-nullable-en-transport-window.issue.md` | Frontmatter: agregar `plan:` field. |
