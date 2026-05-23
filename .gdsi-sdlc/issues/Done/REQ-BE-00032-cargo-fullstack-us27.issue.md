---
tag: REQ-BE-00032
title: Cargo fullstack — modelo, endpoints, FSM + "Mis cargas" UI (US27)
priority: P1
status: done
created: '2026-05-19'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/198
author: Claude Code
github_issue: 198
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtNJOE
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-19T16:06:43.713163+00:00Z
plan: docs/features/REQ/REQ-BE-00032/REQ-BE-00032-cargo-fullstack-us27.plan.md
labels:
- REQ
- BE
- FE
- fullstack
- marketplace
- us27
- cargo
---

## Summary

Full vertical para el US27 (publicación de una `Cargo` por parte del Shipper). Aterriza, en una sola PR fullstack:

- **Backend**: modelo `Cargo`, FSM (`open / accepted / cancelled`), `POST /api/cargos`, listado, detalle, edit, soft-cancel, y `GET /api/cargos/:id/matches` (Haversine en app code).
- **Frontend**: rutas `/shipper/cargos[/new|/:id[/edit]]`, listado "Mis cargas", formulario de publicación, detalle con matches y offers, soft-cancel.

Es el lado **Shipper-publicación** del rename 2026-05-19 — la mitad faltante del scope original de issue #121 (que queda asociado a US7 = autoría de `CargoOffer`). Se filea fullstack porque sin la UI el endpoint no se puede ejercitar end-to-end y sin el endpoint la UI no tiene contrato — splitearlas obligaría a un MSW intermedio que duplica trabajo. La precedente del repo es `REQ-BE-00023` (auth fullstack US1+US2).

## Problem Statement

El dominio renombrado del 2026-05-19 (ver `docs/02-high-level-design/domain-model.md` § 3) introduce dos artefactos distintos del marketplace:

- **`Cargo`** — publicación del Shipper. Lifecycle: `open / accepted / cancelled`. US27.
- **`CargoOffer`** — bid dirigido del Shipper contra un `TransportWindow` específico. Lifecycle: `pending / accepted / rejected / expired`. US7.

`REF-BE-00002` renombra el código existente (la vieja `CargoOffer` pasa a ser `Cargo`, el viejo `Quote` pasa a ser `CargoOffer`). Esta issue agrega lo que **no existe** todavía: el endpoint para que el Shipper publique una `Cargo`, la UI para que lo dispare, y la lógica de matching contra `TransportWindow`s para alimentar US4 (que ahora es **Cargo-scoped**, no un browse global).

PR #193 actualmente layered `POST /api/quotes` mezclando creación de `Cargo` + `CargoOffer` en un solo endpoint — esa PR está pendiente de request-changes para splitearse en `POST /api/cargos` (esta issue) + `POST /api/cargos/:id/offers` (US7).

Sin esta vertical:

- No hay vía API para que un Shipper publique una carga — el funnel US27 → US4 → US5 → US6 → US7 está cortado en la raíz.
- US4 (REQ-FE-00006, `InReview`) asume "browse global de Windows" pero el reframe del 2026-05-19 lo movió a Cargo-scoped (`GET /api/cargos/:id/matches`). Esta issue es la dependencia faltante para que ese reframe se ejecute.

## Expected Behavior

### Backend

#### Modelo `Cargo`

- Atributos: `shipper_id` (FK), `description`, `origin_*` (lat/lng/address), `destination_*` (lat/lng/address), `pickup_window_start`, `pickup_window_end`, `weight_kg`, `volume_m3` (opcional), `declared_value_cents`, `status` (`open / accepted / cancelled`).
- `belongs_to :shipper` (vía `User`); `has_many :cargo_offers, dependent: :destroy`; `has_one :accepted_cargo_offer` (scope sobre `cargo_offers` con `status: :accepted`).
- FSM (AASM o enum + transitions manuales — alinear con `Shipment`):
  - `open → accepted` cuando algún `CargoOffer` asociado pasa a `accepted` (transición disparada por `REQ-BE-00024` / US12).
  - `open → cancelled` cuando el Shipper cancela explícitamente (sin offers `accepted`).
- **No existe** un estado intermedio `offered` — `Cargo` queda `open` mientras tenga `pending` offers; pasa a `accepted` recién cuando alguna se acepta (decisión bloqueada 2026-05-19).

#### Endpoints

- `POST /api/cargos` — Shipper autenticado crea una `Cargo`. Body: campos del modelo (sin `status`, default `open`). Response 201 con la `Cargo` serializada + sus matches iniciales contra `TransportWindow`s compatibles.
- `GET /api/cargos` — lista las `Cargo`s del Shipper autenticado. Filtros: `status`. Paginado.
- `GET /api/cargos/:id` — detalle de una `Cargo` del Shipper. Incluye sus `CargoOffer`s (con su Window asociado) y el contador por estado.
- `GET /api/cargos/:id/matches` — lista los `TransportWindow`s compatibles. Paginado + ordenable. Excluye Windows ya en `pending_offer`/`reserved`/`closed`.
- `PATCH /api/cargos/:id` — Shipper puede editar mientras `status == open` y no hay offers `accepted`.
- `DELETE /api/cargos/:id` — soft-cancel (`status → cancelled`) si no hay offers `accepted`. Las offers `pending` quedan `expired` en la misma tx; sus Windows auto-flip a `open`.

#### Autorización

- Todas las rutas requieren auth (Devise + JWT por `REF-BE-00001`).
- `POST /api/cargos` y endpoints `:id` validan que `current_user` sea Shipper (rol via relación `shippers`, no booleano).
- `GET /api/cargos/:id` y `/matches` solo si `cargo.shipper_id == current_user.shipper.id` — un Shipper no ve cargas ajenas.

#### Matching

- Algoritmo Haversine en application code (per CLAUDE.md database policy — sin PostGIS).
- "Compatible": origen de la `Cargo` dentro de `pickup_radius_km` del origen de la `TransportWindow`; destino de la `Cargo` dentro de `pickup_radius_km` del destino de la Window; `cargo.pickup_window_*` overlap con `window.departure_*`; `window.max_load_kg >= cargo.weight_kg`.
- Sin caché — recalcula on-demand. La query base filtra Windows `open` con bounding-box previo al Haversine para no escanear toda la tabla.

### Frontend

#### Rutas (en inglés, UI text via i18n)

- `/shipper/cargos` — listado "Mis cargas".
- `/shipper/cargos/new` — formulario de publicación.
- `/shipper/cargos/:id` — detalle con matches + offers existentes.
- `/shipper/cargos/:id/edit` — formulario de edición.

#### Listado "Mis cargas" (`/shipper/cargos`)

- Tabla / cards con: descripción corta, origen → destino, fecha del pickup window, estado, # de offers `pending` recibidas.
- Filtros: por estado (`open / accepted / cancelled / all`).
- Empty state: CTA "Publicá tu primera carga".
- Botón superior derecho: **"Publicar carga"** → `/shipper/cargos/new`.

#### Formulario de publicación (`/shipper/cargos/new`)

Campos (todos requeridos salvo donde se indique):

- Descripción corta (text, max 200 chars).
- Origen — autocomplete + map picker (lat/lng + address). Reuso del componente que ya estaba pensado para US7/US9 (si no existe, lo aporta esta issue).
- Destino — idem.
- Pickup window — `start` + `end` (date+time pickers; valida `end > start`).
- Peso (kg), Volumen (m³, opcional), Valor declarado (ARS).

Validación client-side (zod) antes del POST. Mensajes via i18n key. Submit → `POST /api/cargos` → redirect a `/shipper/cargos/:id`.

#### Detalle (`/shipper/cargos/:id`)

- Header: campos de la Cargo + botones "Editar" / "Cancelar" según elegibilidad.
- Sección **Matches** (`GET /:id/matches`): cards con `TransportWindow` + Carrier (nombre, rating), distance_km, capacidad. CTA "Ofertar" → wizard de US7 (`REQ-FE-00015`; stub redirect si todavía no aterrizó).
- Sección **Mis ofertas**: `CargoOffer`s ya autoradas contra esta Cargo, con su estado y Window target.
- Si `status == accepted`: Carrier ganador prominent + datos de contacto + tracking link (alimenta US21).
- Si `status == cancelled`: badge + razón si aplica.

#### Acciones

- "Cancelar carga" — confirm modal, dispara `DELETE`. Avisa que las offers `pending` se expiran. Solo si `status == open` y sin offers `accepted`.
- "Editar" — solo si elegible. Form pre-rellenado.

#### Auth-guards

- Redirect a `/login` si no autenticado.
- 403 page si autenticado pero no Shipper.

## Current Behavior

- Backend: no existe `Cargo` como modelo separado (post-`REF-BE-00002` será el renombrado de la vieja `CargoOffer`). Falta `POST /api/cargos`, `/matches`, FSM `open / accepted / cancelled`, auto-cancel cascade.
- Frontend: solo landing-page (per CLAUDE.md + `.gdsi-sdlc/continue.md`). No hay UI ni tipos del dominio.

## Reproduction Steps

N/A (feature work).

## Impact

**Quién**: Shippers (US27 directo); indirectamente Carriers (porque US4/US10/US12 dependen de tener `Cargo`s publicadas).

**Cómo**: desbloquea la demo end-to-end del lado Shipper. Es el punto de entrada de todo el funnel marketplace tras el reframe Cargo-scoped.

**Riesgos**:

- Coordinación con `REF-BE-00002` y PR #193. Esta issue **se bloquea en `REF-BE-00002`** porque el modelo `Cargo` solo existe en código después del rename.
- Dependencia sobre `INF-FE-00003` (routing por features) para montar las rutas.
- Matching Haversine on-demand puede ser lento con muchas Windows. MVP: aceptable; documentar como limitación final (sin "Phase-2 PostGIS" — per CLAUDE.md DB policy).
- Map picker (Google Maps SDK, `REQ-FE-00009`) puede no estar listo cuando esta issue arranque. Fallback: input text + geocoding al submit.
- PR fullstack grande. Mitigación: backend y frontend pueden desarrollarse en commits separados dentro del mismo branch, con CI verde en cada paso.

## Technical Notes

### Backend

#### Migración

- No crea la tabla `cargos` — la trae `REF-BE-00002` (rename de `cargo_offers` → `cargos`).
- Puede agregar columnas nuevas si el schema post-`REF-BE-00002` no las cubre — revisar contra `backend/db/schema.rb` resultante.

#### Controllers / serializers

- `Api::CargosController` con acciones `index / show / create / update / destroy / matches`.
- Hereda del `ApplicationController` API; usa el error envelope estándar de `INF-BE-00004`.
- Serializers: `CargoSerializer`, `CargoMatchSerializer` (incluye Window + `distance_km` calculado).

#### Routes

```ruby
namespace :api do
  resources :cargos do
    get :matches, on: :member
  end
end
```

#### Specs backend

- Request specs (rswag) para los 6 endpoints: happy path (201/200), 401 sin auth, 403 si no Shipper o Cargo ajena, 422 validaciones (weight ≤ 0, lat/lng inválido, `pickup_window_end < start`), `DELETE` con offers `pending` → siblings `expired` + Windows `open`, `matches` filtra Windows no-`open`.
- Model spec: validaciones, FSM transitions, asociaciones.
- Factory: `cargos.rb` (renombrada en `REF-BE-00002`).

#### I18n backend

- Validaciones via symbolic key (`errors.add(:weight_kg, :must_be_positive)`); mensajes en `config/locales/cargos.es.yml`.
- Endpoint paths en inglés (`/api/cargos`).

### Frontend

#### Stack

- React + TypeScript (Deno + Vite). Router: React Router (post-`INF-FE-00003`).
- Validación: react-hook-form + zod (alinear con `REQ-FE-00016` TransportWindow CRUD).
- i18n: por ahora `landingContent.ts` patrón hasta que aterrice un i18n lib real (per CLAUDE.md carve-out). Crear `cargosContent.ts` análogo o, idealmente, esta issue motiva la introducción del i18n lib propiamente — decidir en plan.

#### Componentes nuevos

- `features/cargo/CargoList.tsx`
- `features/cargo/CargoForm.tsx` (compartido new/edit)
- `features/cargo/CargoDetail.tsx`
- `features/cargo/MatchCard.tsx`
- `features/cargo/api.ts` (cliente REST tipado contra los serializers)

#### Tipos

- `types/Cargo.ts`: `Cargo`, `CargoStatus`, `CargoOffer`. Primer set de tipos del dominio en frontend — define la convención para los próximos US.

#### Tests frontend

- Vitest unit/component: validación del `CargoForm` (zod schema), empty state + filtros del `CargoList`, ramas por status en `CargoDetail`.
- Playwright E2E (chromium) cubriendo golden path: login Shipper → empty state → publicar carga → detalle con matches → volver al listado.
- Coverage threshold 80% (per CLAUDE.md `vitest.config.ts`).

#### A11y

- Form fields con `<label htmlFor>` correctos.
- Errores anunciados con `aria-live="polite"`.
- Confirm modal cancelar carga es trap-focus + `Esc`-dismissable.
- Botones con estado `loading` y `disabled` durante POST/DELETE.

### Sequencing

Bloquea en:

1. **`REF-BE-00002`** — necesita el modelo `Cargo` renombrado en código.
2. **PR #193 resuelto** — para que no haya `POST /api/quotes` colgado en main.
3. **`INF-FE-00003`** — routing por features para montar las rutas.

Plan de PR sugerido (no rígido):

1. Commit BE: modelo + FSM + migración delta (si la hay) + endpoints + request specs.
2. Commit BE: matches + auto-cancel cascade + tx semantics + specs.
3. Commit FE: tipos + `api.ts` + `CargoList` + empty state.
4. Commit FE: `CargoForm` (new/edit) + validación.
5. Commit FE: `CargoDetail` + `MatchCard` + acciones.
6. Commit: Playwright E2E + `/critique`/`/polish`/`/audit` fixes.

## Origin

Identificado durante la sesión de grilling del 2026-05-19 que renombró el dominio y reframed los US del marketplace a flujo Cargo-scoped. El scope de US27 originalmente quedó solapado con US7 en issue #121; esta issue cierra el gap fullstack.

Mergeada del par previo (`REQ-BE-00032` BE-only + `REQ-FE-00022` FE-only) por instrucción 2026-05-19: la vertical no se splitea porque el contrato JSON entre ambos lados no estabiliza sin las dos puntas en la misma PR. Precedente: `REQ-BE-00023` (auth fullstack US1+US2).

## Related

- US: US27.
- Bloquea en: `REF-BE-00002` (rename de código), resolución de PR #193 (split de endpoint), `INF-FE-00003` (routing).
- Inputs: `REQ-FE-00009` (Google Maps SDK — habilita map picker en el form).
- Habilita: `REQ-FE-00006` (US4 reframed a Cargo-scoped), `REQ-FE-00015` (US7 wizard de oferta — CTA "Ofertar" en los matches), `REQ-BE-00024` (US12 — la acceptance transitionea `Cargo.status → accepted`).
- Issue #121 — sibling US (US7); esta issue cubre US27.
- Docs: `docs/02-high-level-design/domain-model.md` §§ 3, 3.1, 3.2.
- Docs: `docs/05-appendices/glossary.md` — `Cargo`, `Oferta de carga`.
- Docs: `docs/04-database-diagrams/erd-marketplace.puml`.
- Docs: `docs/artifacts/backlog-us.typ` — US27.

## Acceptance Criteria

### Sequencing

- [ ] `REF-BE-00002` mergeado (precondición de schema).
- [ ] PR #193 resuelta con split en `POST /api/cargos` + `POST /api/cargos/:id/offers` (esta issue toma ownership del primero).
- [ ] `INF-FE-00003` mergeada (routing por features disponible).

### Backend — modelo + FSM

- [ ] Modelo `Cargo` con asociaciones `belongs_to :shipper`, `has_many :cargo_offers, dependent: :destroy`, `has_one :accepted_cargo_offer`.
- [ ] FSM `Cargo.status` (`open / accepted / cancelled`) sin estado `offered`. Transition `open → accepted` disparada por `CargoOffer` aceptada (cross-link con `REQ-BE-00024`).

### Backend — endpoints

- [ ] `POST /api/cargos` crea `Cargo` con `status: open`; response 201 incluye matches iniciales.
- [ ] `GET /api/cargos` lista Cargos del Shipper; filtro `?status=`; paginado.
- [ ] `GET /api/cargos/:id` retorna detalle con offers anidadas; 403 si ajena.
- [ ] `GET /api/cargos/:id/matches` retorna `TransportWindow`s compatibles (Haversine app-code); excluye Windows no-`open`; paginado.
- [ ] `PATCH /api/cargos/:id` bloquea edición si hay offers `accepted` (422).
- [ ] `DELETE /api/cargos/:id` soft-cancel + auto-expira offers `pending` + flip Windows a `open` (misma tx).

### Backend — specs + i18n

- [ ] Request specs (rswag) verdes para los 6 endpoints, incluyendo 401/403/422.
- [ ] Model spec cubre validaciones + FSM + asociaciones.
- [ ] Factory `:cargo` actualizada.
- [ ] I18n: mensajes de validación y error desde `config/locales/cargos.es.yml`; cero strings hardcoded.
- [ ] `grep -rn '\bQuote\b\|/api/quotes' backend/app` no devuelve hits (excluyendo insurance vocabulary).
- [ ] RSpec + rswag + brakeman + bundler-audit + rubocop verdes.

### Frontend — rutas + UI

- [ ] Rutas `/shipper/cargos`, `/shipper/cargos/new`, `/shipper/cargos/:id`, `/shipper/cargos/:id/edit` montadas en el router.
- [ ] Listado muestra Cargos del Shipper con filtros por estado + paginado + empty state con CTA.
- [ ] Formulario valida client-side (zod), llama `POST /api/cargos`, redirige al detalle.
- [ ] Detalle muestra Cargo + sección Matches + sección Mis ofertas.
- [ ] CTA "Ofertar" en cada match abre el wizard de US7 (stub redirect aceptable si `REQ-FE-00015` no aterrizó).
- [ ] "Cancelar carga" confirma + dispara `DELETE`, muestra mensaje de offers expiradas.
- [ ] "Editar" funciona si y solo si `status == open` && sin offers `accepted`.
- [ ] Todas las strings UI vía i18n key; rutas todas en inglés.

### Frontend — tests + a11y + quality gate

- [ ] Vitest coverage ≥ 80% lines/functions/branches/statements en archivos nuevos.
- [ ] Playwright E2E del golden path verde en chromium.
- [ ] A11y: labels correctos, focus management en modal, `aria-live` en errores.
- [ ] `/critique` + `/polish` + `/audit` ejecutados sobre las pantallas nuevas; findings resueltos o anotados en PR description.
- [ ] `just lint` + `just frontend-test-coverage` + `just frontend-test-e2e` + `just backend-test` verdes.

### PR

- [ ] PR title: `feat(cargo): cargo fullstack — modelo, endpoints + mis cargas UI (US27)`. Body referencia `REQ-BE-00032` y `Closes #N`. `--assignee @me`.
