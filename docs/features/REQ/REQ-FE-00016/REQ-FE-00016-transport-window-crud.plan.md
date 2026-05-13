# REQ-FE-00016: TransportWindow CRUD — publicar disponibilidad del transportista (US9)

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00016 |
| **Title** | Publicar disponibilidad del transportista — TransportWindow CRUD |
| **Priority** | P1 |
| **Status** | InProgress |
| **Created** | 2026-05-11 |
| **Updated** | 2026-05-11 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00023` (Auth — `Api::BaseController` + Devise session). `REQ-BE-00020` (Identity — `Carrier`/`Vehicle`). `REQ-BE-00009/10` (Vehicle CRUD — `VehicleSelect` component + carrier CSS design system). |
| **Selected Approach** | Fullstack en un solo PR: endpoints CRUD bajo `/api/carriers/me/transport_windows` + pantalla `/carrier/availability` (lista + form). Soft-delete vía `active=false` en lugar de destroy. Sigue exactamente los patrones establecidos por el PR de vehículos (PR #144). |

---

## 1. Problem Statement

Sin ventanas de disponibilidad publicadas, la búsqueda de transportistas (US4, REQ-FE-00006) devuelve listas vacías y no hay mercado. El `TransportWindow` ya existe como modelo con migraciones y validaciones; falta la capa de API y la UI para que el transportista gestione sus publicaciones.

Estado actual del repo (al momento de este plan):
- `TransportWindow` model con `belongs_to :vehicle`, `has_many :quotes, dependent: :restrict_with_error`, validaciones `time_window_is_coherent` y `no_vehicle_overlap`.
- `transport_windows` factory existente.
- `Carrier#has_many :transport_windows, through: :vehicles`.
- No hay endpoints `/api/carriers/me/transport_windows`.
- No hay pantalla de disponibilidad en el frontend.

---

## 2. Solution Design

### 2.1 Approach

Cinco capas independientes comprometidas en orden:

1. **Backend API** — `Api::Carriers::Me::TransportWindowsController` (CRUD), `TransportWindowPolicy` (Pundit), `TransportWindowResource` (Alba).
2. **Backend tests** — `spec/policies/transport_window_policy_spec.rb` + `spec/requests/api/carriers/me/transport_windows_spec.rb`.
3. **Frontend API client** — `src/api/transport_windows.ts` con tipos TypeScript + funciones de fetch.
4. **Frontend UI** — `TransportWindowList.tsx` (lista + toggle active) + `TransportWindowForm.tsx` (create/edit) + rutas `/carrier/availability[/new|/:id]`.
5. **Frontend tests** — Vitest para lista + form; Playwright E2E create → deactivate.

### 2.2 Key Design Decisions

#### Decisión A — Soft-delete en DELETE

- **Decisión**: `DELETE /api/carriers/me/transport_windows/:id` no llama `window.destroy!` sino `window.update!(active: false)`.
- **Rationale**: la issue lo especifica explícitamente. El model tiene `has_many :quotes, dependent: :restrict_with_error` — destruir una window con quotes rompe el marketplace. La semántica de "despublicar" es lógicamente correcta para el usuario.
- **Corolario**: el endpoint PATCH puede reactivar con `{ active: true }`. El botón "Reactivar" en la UI usa PATCH.

#### Decisión B — Scope through vehicles (no `carrier_id` directo en transport_windows)

- **Decisión**: `current_carrier.transport_windows` usa el `has_many :through :vehicles` ya definido en `Carrier`. La policy scope hace `joins(:vehicle).where(vehicles: { carrier_id: user.carrier.id })`.
- **Rationale**: la tabla `transport_windows` no tiene `carrier_id` (carrier se deriva del vehicle). Agregar una columna denormalizada sería baggage que viola la política SQLite del proyecto.

#### Decisión C — vehicle_id solo en CREATE; no en UPDATE

- **Decisión**: `transport_window_params` para `create` incluye `:vehicle_id`; para `update`, se filtra. El vehículo asociado no cambia después de creado.
- **Rationale**: reasignar el vehicle después de que hay quotes asociados crearía inconsistencias lógicas. La simplicidad gana.

#### Decisión D — Ruta `/carrier/availability` (no `/carrier/transport-windows`)

- **Decisión**: la ruta visible al usuario es `/carrier/availability[/new|/:id]` — palabras en inglés, semánticamente claras.
- **Rationale**: cumple la política de idioma de CLAUDE.md (rutas en inglés). El término "availability" es la traducción natural de "disponibilidad" para un carrier.

---

## 3. Components

### 3.1 Backend

**Controller:** `Api::Carriers::Me::TransportWindowsController`
- `GET /api/carriers/me/transport_windows` — lista con Pagy (default 20), ordenadas por `available_from ASC`, scope a través de la policy.
- `GET /api/carriers/me/transport_windows/:id`
- `POST /api/carriers/me/transport_windows` — crea; valida que `vehicle_id` pertenezca al carrier.
- `PATCH /api/carriers/me/transport_windows/:id` — actualiza (sin reasignación de vehicle).
- `DELETE /api/carriers/me/transport_windows/:id` — soft-delete (`active=false`).

**Policy:** `TransportWindowPolicy`
- `index?` / `show?` / `create?` / `update?` / `destroy?` — owner-only (vehicle.carrier == current_carrier).
- `Scope#resolve` — `joins(:vehicle).where(vehicles: { carrier_id: carrier.id })`.

**Resource:** `TransportWindowResource` (Alba)
- Todos los campos + objeto `vehicle` embebido (id, make, model, plate, vehicle_type).
- `.list` → misma clase (no hay variante slim relevante aquí).

### 3.2 Frontend

**API client:** `src/api/transport_windows.ts`
- Tipos: `TransportWindow`, `TransportWindowListMeta`, `TransportWindowListResult`.
- Funciones: `listMyTransportWindows`, `getMyTransportWindow`, `createTransportWindow`, `updateTransportWindow`, `deactivateTransportWindow`.

**Páginas:**
- `/carrier/availability` → `TransportWindowList.tsx` — lista con cards/filas, badge de estado, botones Editar / Despublicar / Reactivar.
- `/carrier/availability/new` → `TransportWindowForm.tsx` (modo create)
- `/carrier/availability/:id` → `TransportWindowForm.tsx` (modo edit)

**Contenido:** sección `availability` en `carrierContent.ts`.

---

## 4. Test Plan

### Backend
- `spec/policies/transport_window_policy_spec.rb` — anónimo / owner / otro carrier (matriz 5×3).
- `spec/requests/api/carriers/me/transport_windows_spec.rb` — index paginado, create validaciones, update, soft-delete (active=false), autorización cross-carrier.

### Frontend
- `TransportWindowList.test.tsx` — loading / empty / populated / toggle active / delete soft.
- `TransportWindowForm.test.tsx` — submit create, pre-fill edit, errores de validación.
- `e2e/carrier-transport-window.spec.ts` — create → verify in list → deactivate → verify inactive. El paso "aparece en búsqueda pública" es `test.skip` hasta que REQ-FE-00006 aterrice.

---

## 5. Acceptance Criteria Mapping

| AC | Implementación |
|----|----------------|
| CRUD endpoints + request specs | Commits 2 + 3 |
| Soft delete (no destroy) cuando hay Quotes | `window.update!(active: false)` en destroy; `restrict_with_error` como fallback de seguridad |
| Pantalla `/transportista/disponibilidad` | `/carrier/availability` — commits 5 (Frontend UI) |
| E2E: crear → búsqueda pública → despublicar | Create → list → deactivate E2E; búsqueda pública `test.skip` hasta REQ-FE-00006 |
| Solo Carriers logueados pueden gestionar | `before_action :authenticate_user! + :require_carrier!` + `TransportWindowPolicy` |

---

## 6. Out of Scope

- Búsqueda pública de transportistas (REQ-FE-00006).
- Filtros de búsqueda (REQ-FE-00013).
- Selección de TransportWindow desde el flujo de oferta del Shipper (REQ-FE-00015).
- Geocodificación real de zonas (queda como texto libre, MVP).
