# REQ-BE-00035: Endpoints de índice y detalle de Envíos — Carrier / Shipper / detalle (US17 + US39)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00035 |
| **Title** | Endpoints de índice y detalle de Envíos (Carrier / Shipper / detalle) (US17 + US39) |
| **Priority** | P1 |
| **Status** | BACKLOG → READY (al mergear este plan) |
| **Created** | 2026-05-24 |
| **Sprint** | 3 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00022` (modelos Fulfilment: `Shipment`, `TrackingEvent`, FSM, soft-delete — mergeado). `REQ-BE-00033` (US8 — modelo `Payment` y estados — lateral, Ready). |
| **Decision Doc** | N/A — decisiones cerradas inline en `.gdsi-sdlc/issues/Backlog/REQ-BE-00035-envios-index-endpoints.issue.md` (sección «Decisiones cerradas en triage») y reflejadas en `docs/05-appendices/glossary.md:25` y `docs/01-technical-vision/technical-vision.md:152` (ADR-012). |
| **Selected Approach** | Single PR — tres endpoints de lectura sobre `Shipment` con dos serializers Alba (listado + detalle), Pundit `Scope` + `show?` con override a 404 sólo en `#show`, derivación server-side de `payment_state` y `available_actions`, índice de soporte para el sort por actividad reciente. Read-only — sin migraciones, sin mutaciones. |

---

## 1. Decisiones canónicas

Las decisiones que rigen este plan ya están cerradas. **No reabrir.** Si un AC del issue o un consumidor FE pide algo que contradiga esta tabla, el plan gana — el contrato es éste.

| # | Decisión | Valor | Fuente |
|---|----------|-------|--------|
| D1 | Endpoint de listado: multi-rol vs split | **Split** — `GET /api/carriers/me/shipments` y `GET /api/shippers/me/shipments` separados | Issue §«Decisiones cerradas en triage» #1 |
| D2 | Endpoint de detalle: multi-rol vs split | **Multi-rol** — único `GET /api/shipments/:id`, autorización por Pundit, 404 (no 403) si no es contraparte | Issue §«Decisiones cerradas en triage» #2 |
| D3 | `available_actions` calculado en BE vs FE | **BE** — fuente única de verdad sobre transiciones permitidas; el FE sólo traduce strings a botones | Issue §«Decisiones cerradas en triage» #3 |
| D4 | `payment_state` columna vs derivado | **Derivado** — calculado en el serializer; nunca columna en `shipments` | Issue §«Decisiones cerradas en triage» #4 |
| D5 | Paginación / filtros / búsqueda | **Fuera de alcance** en Sprint 3 — listado plano | Issue §«Decisiones cerradas en triage» #5; US17 §«Fuera de alcance» |
| D6 | Mapa de recorrido en detalle | **Fuera de alcance** — `tracking_events` lista plana; el mapa vive en US51 | Issue §«Decisiones cerradas en triage» #6; US39 §«Fuera de alcance» |
| D7 | FSM canónico `Shipment` | `accepted → in_transit → delivered` (+ `cancelled` desde `accepted` o `in_transit`). No existen `pending`, `a_recoger`, `pendiente_de_pago`. | `docs/05-appendices/glossary.md:25`, ADR-012 (`docs/01-technical-vision/technical-vision.md:152`) |
| D8 | Interlock de cancelación post-pago | Shipper NO puede cancelar si existe `Payment` en `escrowed` (refund/dispute fuera de MVP) | ADR-012; US39 AC «Expedidor `accepted` + pagado» |
| D9 | Soft-delete | `Shipment.discarded_at` heredado de `REQ-BE-00022`. Listados aplican `default_scope`; `show` también — descarted → 404. | Issue §«Soft-delete (ADR-009)»; glossary entry de `Envío` |
| D10 | SQLite forever | Sort por `latest_activity_at` se resuelve con `LEFT JOIN tracking_events` + `MAX(...)` + `GROUP BY` + `COALESCE(MAX(...), shipments.updated_at)`. Sin window functions, sin `LATERAL`, sin `unaccent`. | CLAUDE.md «Database policy» |
| D11 | Lenguaje | Rutas en inglés (`/api/carriers/me/shipments` — NO `/api/transportistas/...`), JSON keys `snake_case` inglés, errores vía `I18n.t(...)`. Sin literales hardcodeados. | CLAUDE.md «Language policy» |
| **D12** | **Emisión de cargo lat/lng (`pickup_lat` / `pickup_lng` / `delivery_lat` / `delivery_lng`)** | **OWNED por este plan.** `CargoResource` y el bloque `cargo` de `ShipmentResource` declaran los cuatro atributos `DECIMAL(9,6)`. Hasta que `REQ-BE-00036` mergee su migración, los atributos se emiten como `nil` (las columnas todavía no existen). Una vez mergeada esa migración, los valores reales fluyen sin cambio al resource. **Decoupling Q6.** | Q6 cross-issue (locked); `docs/features/REQ/REQ-BE-00036/REQ-BE-00036-us48-us49-lat-lng-migrations.plan.md` §2.6 |
| D13 | Emisión de `TransportWindow` lat/lng | **NO** vive en este plan. `TransportWindowResource` es propiedad exclusiva de `REQ-BE-00036`. Este plan no lo toca ni lo redefine. | REQ-BE-00036 plan §2.6 |

## 2. Schema impact

**Ninguno por parte de este plan.** El issue es read-only.

- No hay migraciones nuevas en este PR. Las columnas que el detalle eventualmente expone vía D12 — `cargos.pickup_lat / pickup_lng / delivery_lat / delivery_lng` (`DECIMAL(9,6)`) — son emitidas por la migración de `REQ-BE-00036`, no por ésta.
- Único cambio DB tolerable acá: índice de soporte para el sort por actividad — `add_index :tracking_events, %i[shipment_id created_at]` **si y sólo si no existe**. Verificar `db/schema.rb` antes; si ya existe (lo probable, dado `REQ-BE-00022`), no añadir. Si se añade, sigue siendo SQLite-clean (B-tree, sin partial, sin spatial).
- Sin columna `shipments.payment_state` (D4 lo prohíbe explícitamente — no denormalizar para query convenience, ver `feedback_no_denormalized_role_flags`).
- Sin columna `shipments.latest_activity_at` — derivado en SQL, no persistido.

Until `REQ-BE-00036` mergea su migración de `cargos.*_lat/lng`, el detalle responde con esos cuatro campos en `nil`. El contrato del JSON no rompe — los campos están declarados en el resource desde el día 1. Ver D12.

## 3. Endpoints

### 3.1 `GET /api/carriers/me/shipments`

- **Auth**: JWT obligatorio (`current_user` resuelto por el middleware existente).
- **Rol**: `current_user.carrier?` requerido. Sin perfil Carrier → 403.
- **Scope**: `ShipmentPolicy::Scope` con `current_user.carrier` — devuelve `Shipment` donde `transport_window.vehicle.carrier_id == current_user.carrier.id`. Camino canónico vía `transport_window` (sin denormalizar `carrier_id` en `Shipment`).
- **Sort**: `latest_activity_at DESC` = `COALESCE(MAX(tracking_events.created_at), shipments.updated_at) DESC` (D10).
- **Soft-delete**: respeta `default_scope` (envíos descartados no aparecen). D9.
- **Paginación**: ninguna (D5).
- **Status codes**:
  - `200` con `{ "shipments": [...] }` — set completo serializado vía `ShipmentListResource`.
  - `401` sin JWT.
  - `403` JWT válido pero sin perfil Carrier.
- **Eager loads**: `eager_load(:payment, cargo_offer: { cargo: :shipper }, transport_window: { vehicle: :carrier })`. AC11 — sin N+1.

### 3.2 `GET /api/shippers/me/shipments`

Espejo simétrico de 3.1, lado Expedidor.

- **Rol**: `current_user.shipper?`. Sin perfil Shipper → 403.
- **Scope**: `shipment.cargo_offer.cargo.shipper_id == current_user.shipper.id`.
- Resto idéntico (sort, soft-delete, sin paginación, mismo shape de payload, mismos status codes).

### 3.3 `GET /api/shipments/:id`

Único endpoint de detalle, multi-rol (D2).

- **Auth**: JWT obligatorio.
- **Rol**: no se filtra por rol de URL — la autorización es Pundit `ShipmentPolicy#show?` y permite tanto Carrier dueño del Vehicle como Shipper dueño del Cargo.
- **Autorización 404-not-403**: `rescue_from Pundit::NotAuthorizedError, with: :render_not_found` **localmente en este action**, no global. El rescue global del controller padre (que devuelve 403) sigue vigente para otros endpoints. Implementación pragmática: override en `Api::ShipmentsController` con un `rescue_from` específico, o un módulo `Concerns::ShowSecretly` reusable si se anticipan más casos (no necesario en este sprint — un único endpoint con este comportamiento; preferir el `rescue_from` local).
- **Pundit policy**: `ShipmentPolicy#show?` retorna `true` sii `record.cargo_offer.cargo.shipper_id == user.shipper&.id || record.transport_window.vehicle.carrier_id == user.carrier&.id`. Boolean limpio — la traducción a 404 vive en el controller.
- **Soft-delete**: envíos descartados → 404 (mismo response que id inexistente o no-contraparte; no se filtra existencia).
- **Status codes**:
  - `200` con `{ "shipment": { ... } }` — payload completo vía `ShipmentDetailResource`.
  - `401` sin JWT.
  - `404` para: id inexistente, JWT de no-contraparte, envío descartado. **Nunca 403** en este action.
- **Eager loads**: `find` con `eager_load(:payment, :tracking_events, cargo_offer: { cargo: :shipper }, transport_window: { vehicle: :carrier })`. AC11.

## 4. Resources (Alba)

Patrón: dos resources Alba siguiendo la convención existente de `cargo_offer_resource.rb` (revisar el path real — `backend/app/resources/`). Sin AMS, sin gem nueva. Cada resource recibe `current_user` como context para resolver campos rol-dependientes.

### 4.1 `ShipmentListResource`

Campos:

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | integer | |
| `state` | string | uno de `accepted | in_transit | delivered | cancelled` (D7) |
| `payment_state` | string | derivado (D4). `"paid"` si existe `Payment` en `escrowed` para el envío; `"pending"` en otro caso. **Omitido del payload si `state == "cancelled"`** (no `null` — omisión literal). |
| `origin` | string | `shipment.cargo_offer.cargo.pickup_address` (o el campo canónico de origen del Cargo — verificar en `cargo.rb`) |
| `destination` | string | `shipment.cargo_offer.cargo.delivery_address` |
| `created_at` | ISO8601 | |
| `amount_cents` | integer | `shipment.amount_cents` (monto acordado del envío) |
| `currency` | string | `shipment.currency` |
| `latest_activity_at` | ISO8601 | `COALESCE(MAX(tracking_events.created_at), shipments.updated_at)` — el FE no lo usa, pero lo expone para debugging y verificación de orden |

### 4.2 `ShipmentDetailResource`

Campos:

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | integer | |
| `state` | string | |
| `payment_state` | string | mismo derivado y mismo criterio de omisión que `ShipmentListResource` |
| `created_at` | ISO8601 | |
| `amount_cents` | integer | |
| `currency` | string | |
| `cargo` | object | bloque anidado — ver 4.3 |
| `vehicle` | object | `{ id, plate, kind }` |
| `counterparty` | object | `{ kind, id, display_name }`. `kind ∈ {carrier, shipper}` — **siempre el opuesto al usuario que consulta** (si Carrier consulta → devuelve al Shipper; si Shipper consulta → devuelve al Carrier). Esto le quita al FE la responsabilidad de saber «quién es quién»: el componente de detalle es agnóstico de rol para este bloque. |
| `payment` | object \| null | `{ id, state, amount_cents, currency, escrowed_at }` — emitido si existe registro de `Payment`. `null` si no se inició el flujo de pago. **Omitido del payload si `state == "cancelled"`** (mismo criterio que `payment_state`). |
| `tracking_events` | array | `[{ id, kind, occurred_at }, ...]` ordenado ascendente por `occurred_at`. `kind` reusa los valores definidos en `REQ-BE-00022`. |
| `available_actions` | array<string> | **Contrato crítico** — ver §4.4. |

### 4.3 `CargoResource` (bloque `cargo`)

El bloque `cargo` dentro de `ShipmentDetailResource` y el resource standalone `CargoResource` (que `REQ-BE-00032` ya define o que este plan introduce si no existe — verificar) comparten contrato:

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | integer | |
| `origin` | string | dirección textual (mantiene compatibilidad con AC7 del issue) |
| `destination` | string | |
| `description` | string | |
| `weight_kg` | integer | |
| `pickup_lat` | decimal(9,6) \| null | **D12 — emitido como `nil` hasta que `REQ-BE-00036` mergee su migración.** Una vez que las columnas `cargos.pickup_lat/...` existen, el atributo fluye sin cambio al resource. |
| `pickup_lng` | decimal(9,6) \| null | idem |
| `delivery_lat` | decimal(9,6) \| null | idem |
| `delivery_lng` | decimal(9,6) \| null | idem |

**Por qué D12 vive acá y no en REQ-BE-00036:** desacopla el shipping del FE detalle (US39 / REQ-FE-00024) del schedule de la migración. El JSON contract es estable desde el día 1 — sólo cambia el valor de `null` a un `DECIMAL` cuando la migración aterriza. `REQ-BE-00036` es responsable de las columnas, este plan es responsable del JSON shape.

### 4.4 `available_actions` — contrato pinned

**Este es el contrato que `REQ-FE-00024` (US39) consume. No puede cambiar sin coordinación cross-issue.**

Lista de strings estables que el BE deriva del `(rol del usuario autenticado, shipment.state, payment_state)`. El FE NO recalcula. Mapeo string → botón i18n + endpoint POST vive en el FE.

Strings legales (whitelist cerrada):

- `start_transit` — transición `accepted → in_transit` (US18). Sólo Carrier.
- `deliver` — transición `in_transit → delivered` (US19). Sólo Carrier.
- `pay` — iniciar / reintentar pago (US8, `REQ-BE-00033`). Sólo Shipper.
- `cancel` — transición `accepted → cancelled` (en este sprint sólo pre-pago; ver D8). Sólo Shipper.

**Reglas de derivación** (la tabla canónica — implementar en `ShipmentDetailResource#available_actions` o en un helper `Shipment::AvailableActions.for(shipment:, user:)`):

| Rol | `shipment.state` | `payment_state` | `available_actions` |
|-----|------------------|-----------------|---------------------|
| Shipper | `accepted` | `pending` | `["pay"]` |
| Shipper | `accepted` | `pending` (+ quiere cancelar) | ver nota → en este sprint: `["pay"]` si no hay endpoint cancel todavía; o `["pay", "cancel"]` si REQ-BE-00038 / cancel ya está disponible. **Default conservador para este PR: `["pay"]`** — el cancel se suma cuando aterrice su endpoint, sin breaking change del contrato. |
| Shipper | `accepted` | `paid` | `[]` — interlock D8 (post-pago, sin cancelación; refund fuera de MVP) |
| Carrier | `accepted` | `paid` | `["start_transit"]` |
| Carrier | `accepted` | `pending` | `[]` — Carrier no puede iniciar transporte sin pago en `escrowed` (US18 AC4) |
| Carrier | `in_transit` | (cualquiera) | `["deliver"]` |
| Cualquiera | `delivered` | (cualquiera) | `[]` — solo lectura |
| Cualquiera | `cancelled` | (cualquiera) | `[]` — solo lectura |

**Notas sobre el contrato (fijas para REQ-FE-00024):**

- `available_actions` es **siempre un array** (nunca `null`). Vacío `[]` significa «solo lectura, sin acciones disponibles».
- Los strings son **estables** — renombrar uno es un breaking change que requiere coordinación cross-issue.
- El FE traduce string → label i18n + endpoint POST. Ej: `"start_transit"` → label `t('shipment.action.start_transit')`, endpoint `POST /api/shipments/:id/start_transit` (definido por `REQ-BE-00038` / US18).
- El array refleja el **estado actual + rol + invariantes ADR-012** en el momento del GET. El FE no cachea decisiones — re-fetch tras cada mutación.
- **Diferencia de naming respecto al issue body**: el issue body usa `mark_picked_up` / `mark_delivered` / `retry_payment` / `cancel_shipment`. Este plan **renombra a `start_transit` / `deliver` / `pay` / `cancel`** alineado con la FSM canónica (D7). El issue body refleja un naming anterior; este plan es la fuente verdad del contrato consumido por REQ-FE-00024. Actualizar el issue para reflejarlo es parte de la tarea #1 del §7.

## 5. Policies (Pundit)

Extender `backend/app/policies/shipment_policy.rb` (ya existe a partir de `REQ-BE-00022`):

```ruby
class ShipmentPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.carrier?
        scope.joins(transport_window: :vehicle)
             .where(vehicles: { carrier_id: user.carrier.id })
      elsif user.shipper?
        scope.joins(cargo_offer: :cargo)
             .where(cargos: { shipper_id: user.shipper.id })
      else
        scope.none
      end
    end
  end

  def show?
    (user.carrier? && record.transport_window.vehicle.carrier_id == user.carrier.id) ||
      (user.shipper? && record.cargo_offer.cargo.shipper_id == user.shipper.id)
  end
end
```

- `Scope#resolve` se invoca desde los **dos** controllers de listado pero, en cada caso, el controller ya filtró por el rol correcto (un Shipper consultando `/api/carriers/me/shipments` rebota antes en el guard de rol). El doble filtro es defensivo y barato.
- `show?` es un boolean limpio — la conversión a 404 vive en el controller (no en el policy). Esto mantiene el policy testeable en aislamiento.
- Las dos ramas del OR usan `user.carrier&.id` / `user.shipper&.id` con safe-navigation por si un usuario tiene un solo perfil. ADR-008 (no denormalized role flags) — `user.carrier?` / `user.shipper?` derivan de las relation rows.

## 6. Test Strategy

### Request specs

- `spec/requests/api/carriers/shipments_spec.rb` (listado carrier):
  - 401 sin JWT.
  - 403 con JWT no-carrier (Shipper-only, User sin ningún perfil).
  - 200 con JWT de Carrier — payload con los campos exactos de §4.1.
  - Sort: 3 shipments con `tracking_events` y `updated_at` distintos → orden esperado por `latest_activity_at DESC`.
  - Soft-delete: shipment con `discarded_at != nil` no aparece.
  - N+1: ≤ 3 queries totales (medido con `bullet` o `count_queries` helper) — AC11.
- `spec/requests/api/shippers/shipments_spec.rb` — espejo simétrico.
- `spec/requests/api/shipments_spec.rb` (detalle):
  - 401 sin JWT.
  - 404 con id inexistente.
  - 404 con JWT de no-contraparte (Carrier ajeno, Shipper ajeno, User sin perfiles).
  - 404 con shipment descartado.
  - 200 con JWT de Carrier dueño — payload completo + `counterparty.kind == "shipper"`.
  - 200 con JWT de Shipper dueño — payload completo + `counterparty.kind == "carrier"`.
  - **`available_actions` matrix** — los 8 combos de §4.4 (uno por fila de la tabla); spec parametrizado.
  - `payment` block presente cuando hay registro, `null` cuando no, omitido cuando `state == "cancelled"`.
  - `tracking_events` ordenado ascendente.
  - **`cargo` lat/lng emission** — los 4 campos están **presentes en el shape** del JSON. Antes de `REQ-BE-00036`, sus valores son `nil`; después, son `DECIMAL`. Spec inicial: presencia de las claves + `null` esperado.

### Resource specs

- `spec/resources/shipment_list_resource_spec.rb` — `payment_state` derivado correcto (paid si hay Payment escrowed, pending si no, omitido si cancelled).
- `spec/resources/shipment_detail_resource_spec.rb` — `counterparty.kind` flip por rol; `available_actions` tabla canónica; `cargo` lat/lng como `nil` mientras la migración no exista.

### Policy spec

- `spec/policies/shipment_policy_spec.rb` — `Scope` retorna correcto para Carrier / Shipper / sin perfiles. `show?` retorna boolean correcto para Carrier dueño, Shipper dueño, Carrier ajeno, Shipper ajeno, User sin perfiles.

Cobertura: SimpleCov no baja del baseline. `just backend-test` y `just lint` limpio antes del PR.

## 7. Implementation Tasks

| # | Task | Layer | Files |
|---|------|-------|-------|
| 1 | Sync issue body — renombrar `mark_picked_up`/`mark_delivered`/`retry_payment`/`cancel_shipment` → `start_transit`/`deliver`/`pay`/`cancel` alineado con FSM D7 | Issue | `.gdsi-sdlc/issues/Backlog/REQ-BE-00035-envios-index-endpoints.issue.md` |
| 2 | Routes namespaced — `carriers/me/shipments`, `shippers/me/shipments`, `shipments` (sólo `show`) | Routing | `backend/config/routes.rb` |
| 3 | `Api::Carriers::ShipmentsController#index` con `ShipmentPolicy::Scope(current_user)` | Controller | `backend/app/controllers/api/carriers/shipments_controller.rb` (nuevo) |
| 4 | `Api::Shippers::ShipmentsController#index` espejo | Controller | `backend/app/controllers/api/shippers/shipments_controller.rb` (nuevo) |
| 5 | `Api::ShipmentsController#show` con `rescue_from Pundit::NotAuthorizedError` local → 404 | Controller | `backend/app/controllers/api/shipments_controller.rb` (nuevo) |
| 6 | Extender `ShipmentPolicy` con `Scope#resolve` y `show?` (boolean limpio) | Policy | `backend/app/policies/shipment_policy.rb` |
| 7 | `ShipmentListResource` Alba — campos §4.1, `payment_state` derivado, omisión si `cancelled` | Resource | `backend/app/resources/shipment_list_resource.rb` (nuevo) |
| 8 | `ShipmentDetailResource` Alba — campos §4.2, `counterparty` rol-flip, `payment` block, `tracking_events` ordenado, `available_actions` (§4.4) | Resource | `backend/app/resources/shipment_detail_resource.rb` (nuevo) |
| 9 | `CargoResource` Alba — emisión de los 4 atributos `pickup_lat/lng`, `delivery_lat/lng` (D12) con valor `nil` hasta REQ-BE-00036 | Resource | `backend/app/resources/cargo_resource.rb` (nuevo o extender si existe) |
| 10 | Helper `Shipment::AvailableActions.for(shipment:, user:)` con la matriz §4.4 | PORO | `backend/app/services/shipment/available_actions.rb` (nuevo) |
| 11 | Sort query — scope `with_latest_activity_at` o método de clase en `Shipment` que arme el `LEFT JOIN tracking_events` + `MAX` + `COALESCE` + `ORDER BY` SQLite-clean | Model | `backend/app/models/shipment.rb` |
| 12 | Índice de soporte `add_index :tracking_events, %i[shipment_id created_at]` **si no existe** | DB | `backend/db/migrate/<timestamp>_add_index_to_tracking_events_for_shipment_activity.rb` (condicional) |
| 13 | Locales — claves de error si faltan (mensajes de unauthorized / not_found) — reusar `:unauthorized`, `:not_found` existentes | i18n | `backend/config/locales/es.yml`, `en.yml` |
| 14 | RSpec request specs — los tres endpoints, matriz de `available_actions`, N+1 | Spec | `backend/spec/requests/api/carriers/shipments_spec.rb`, `shippers/shipments_spec.rb`, `shipments_spec.rb` |
| 15 | RSpec resource specs | Spec | `backend/spec/resources/shipment_list_resource_spec.rb`, `shipment_detail_resource_spec.rb` |
| 16 | RSpec policy spec | Spec | `backend/spec/policies/shipment_policy_spec.rb` |

Orden de commits dentro del PR — uno por capa (routes → policies → controllers → resources → specs), no por user story. Si el diff explota >400 líneas, splitear pero mantener el contrato del JSON estable.

## 8. Out of Scope

- **Migraciones de coordinates** (`cargos.pickup_lat / pickup_lng / delivery_lat / delivery_lng`) — propiedad de **`REQ-BE-00036`**. Este plan declara la emisión en el resource (D12) pero no agrega columnas.
- **`TransportWindowResource`** — propiedad de **`REQ-BE-00036`**. No tocar acá (D13).
- **Endpoints de transición** (`start_transit`, `deliver`) — propiedad de **`REQ-BE-00038`** / US18 / US19. Este plan sólo expone `available_actions` que indica qué transiciones están disponibles; la mutación es otro PR.
- **Endpoint de pago** (`pay` / reintento) — propiedad de **`REQ-BE-00033`** (US8). Este plan consume el estado `Payment.escrowed` para derivar `payment_state`; el flujo de creación de `Payment` es otro PR.
- **Endpoint de cancelación** (`cancel`) — fuera del MVP per ADR-012 si hay pago en `escrowed`. Pre-pago hay un flujo existente del Shipper, pero el endpoint dedicado se difiere a Sprint 4+. `available_actions` no incluye `"cancel"` en este sprint (ver nota en §4.4 — default conservador `["pay"]`).
- **Paginación, filtros, búsqueda, mapa de recorrido** — D5, D6.

## 9. Related

- **Issue body (fuente de AC):** `.gdsi-sdlc/issues/Backlog/REQ-BE-00035-envios-index-endpoints.issue.md`.
- **User stories:** US17 (`docs/artifacts/backlog-us.typ:297-327`), US39 (`docs/artifacts/backlog-us.typ:364-395`).
- **Glossary:** `docs/05-appendices/glossary.md:25` («Envío» — FSM canónica, composiciones de UI), línea 23 («Carga» — pickup/delivery lat/lng), línea 28 («Pago / Escrow» — FSM y cancellation interlock).
- **ADR-012:** `docs/01-technical-vision/technical-vision.md:152` — `Payment` per-attempt rows + cancellation interlock + escrow terminal.
- **Sibling BE — lateral:**
  - `REQ-BE-00033` (US8 — `Payment` model, Brian) — define `Payment` y el estado `escrowed` que este plan consume para derivar `payment_state`. Coordinar el shape final antes de freezear `ShipmentDetailResource#payment`. Plan: `docs/features/REQ/REQ-BE-00033/REQ-BE-00033-us8-realizar-pago-expedidor.plan.md`.
  - `REQ-BE-00036` (US48 + US49 — migraciones lat/lng) — owns la migración que materializa los valores `pickup_lat/lng/delivery_lat/lng` que este resource emite (D12). Plan: `docs/features/REQ/REQ-BE-00036/REQ-BE-00036-us48-us49-lat-lng-migrations.plan.md`.
  - `REQ-BE-00038` (transiciones — US18 + US19, en planificación) — owns los endpoints `start_transit` / `deliver`. Este plan sólo expone `available_actions`.
- **Consumidor FE:** `REQ-FE-00024` (US39 detalle) — consume `available_actions` y el shape de `ShipmentDetailResource`. **Pinned contract — §4.4.**
- **Política:** `CLAUDE.md` — DB SQLite forever, language policy, no denormalized flags (ADR-008).
- **Dependencia upstream:** `REQ-BE-00022` — `Shipment`, `TrackingEvent`, FSM, soft-delete (mergeado).
