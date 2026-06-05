---
tag: REQ-FE-00022
title: Listado de Envíos del Transportista (US17 — vista Carrier)
priority: P1
status: backlog
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/236
author: Claude Code
github_issue: 236
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr30Y
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:54:36.183735+00:00Z
labels:
- REQ
- FE
- fulfilment
- carrier
- mvp
- us17
---

## Summary

Pantalla en `/carrier/shipments` accesible solo a Carriers autenticados que lista los `Shipment` donde el usuario es el transportista contratado. Cada fila expone dos chips de estado independientes (estado del envío + estado del pago), información resumida (origen, destino, fecha de creación, monto acordado), y enlaza al detalle del envío (`/carrier/shipments/:id`, US39). Estado vacío con copy específico. Toda la copy via i18n. Consume `GET /api/carriers/me/shipments` (US17 backend, `REQ-BE-00035`).

## Problem Statement

Hoy el Carrier no tiene ningún lugar en la UI donde ver el conjunto de envíos que está realizando o realizó — la única forma de llegar a la información post-aceptación es vía el dashboard, que no escala más allá de "envío más reciente". US17 entrega ese punto de entrada como un listado plano.

El listado del Carrier es deliberadamente una pantalla aparte del listado del Shipper aunque comparte estructura — el split (vs un único componente "Mis Envíos" multi-rol) lo decidió la grilling session: cada persona tiene su propia ruta (`/carrier/shipments` vs `/shipper/shipments`), su propio endpoint, y vive en su propio submenu lateral. El detalle (US39) sí es compartido entre roles.

## Expected Behavior

### Ruta y guardado

- Componente React montado en `/carrier/shipments`.
- Guard: solo accesible si el usuario autenticado tiene rol Carrier. Si no es Carrier → redirección al dashboard con toast "Sección sólo accesible para transportistas" (clave i18n). Sin Carrier autenticado → flujo de login existente.
- Entrada de navegación en el sidebar del Carrier — agregar al menú lateral con label **"Mis Envíos"** (clave i18n). Verificar orden con `REQ-FE-00021` (dashboard + nav global).

### Layout

- Cabecera con título "Mis Envíos" (clave i18n `carrier.shipments.list.title`) + subtítulo / hint corto (clave i18n).
- Lista de filas. **Sin paginación** en este sprint (set completo del endpoint).
- Estado vacío explícito (ver siguiente sub-sección).
- Estado de carga (skeleton rows o spinner — alinear con el patrón ya usado en `QuoteInboxPage` / `REQ-FE-00017`).
- Estado de error (fetch falló): mensaje + botón de retry. Clave i18n. Sin literales hardcoded.

### Estado vacío

- Si la respuesta del endpoint es `{ shipments: [] }`: render del estado vacío con copy literal:
  > "Aún no realizaste envíos. Aceptá una oferta para empezar."
- Resuelta vía clave i18n (`carrier.shipments.list.empty.title` + `...empty.body`). Sin literales hardcoded en JSX.
- CTA secundaria opcional: link a la bandeja de ofertas (`/carrier/quotes` o equivalente — usar la ruta canónica del repo). Verificar con la implementación de `REQ-FE-00017`.

### Fila

Cada fila renderiza:

1. **Chip de estado del envío** (`shipment.state`):
   - Valores posibles: `accepted`, `in_transit`, `delivered`, `cancelled`. Renderizados como `Aceptado`, `En tránsito`, `Entregado`, `Cancelado` via claves i18n (`shipment.state.accepted` etc.).
   - Cada estado tiene su variante de color: azul/neutral para `Aceptado`, ámbar/activo para `En tránsito`, verde/éxito para `Entregado`, rojo/inactivo para `Cancelado`. Tokens del design system (no `#hex` literal — el lint del repo lo bloquea).
2. **Chip de estado del pago** (`payment_state`):
   - Valores: `pending` → `Pendiente de pago` (variante neutral/atención), `paid` → `Pagado` (variante éxito).
   - **Se oculta** si `shipment.state == "cancelled"` (en cuyo caso `payment_state` viene omitido del payload).
3. **Información resumida**: origen → destino, fecha de creación (formato `dd/MM/yyyy`, locale `es-AR`), monto acordado formateado con `Intl.NumberFormat('es-AR', { style: 'currency', currency: 'ARS' })`.
4. **Indicador de "ir al detalle"**: chevron o similar; toda la fila es clickeable como link a `/carrier/shipments/:id`.

### Orden

El orden viene definido por el backend (`latest_activity_at DESC`). El componente NO reordena.

### Sin paginación, filtros, búsqueda

Explícitamente fuera de alcance del sprint. Si la lista es larga, el scroll vertical es la respuesta del MVP.

## Technical Notes

**Reusar `ShipmentStateChip` y `PaymentStateChip`** — los dos chips se comparten con [[REQ-FE-00023]] (Shipper) y [[REQ-FE-00024]] (US39 detalle). Extraerlos a `frontend/src/components/shipments/` desde el inicio. No copy-paste entre las tres pantallas.

**Hook de fetch reusable** — `useCarrierShipments()` que envuelve `fetch('/api/carriers/me/shipments')`. Patrón ya establecido en el repo (`useCarrierQuotes`, etc — confirmar nombre exacto). Side: el Shipper usa `useShipperShipments()`.

**Sin React Query (verificar)** — si el repo no usa una librería de data-fetching, mantener el patrón actual (state local + effect). No introducir React Query / SWR en este issue.

**Refresh post-mutation** — fuera de alcance directo de este issue (no hay mutaciones desde el listado). Pero: si llegamos al detalle (US39), disparamos una transición, y volvemos al listado — debe refrescar. Considerar suscripción al evento `truckr:shipment-updated` (mismo patrón que `truckr:carrier-quote-updated` de PR #194). Coordinar con [[REQ-FE-00024]].

**Design system / lint** — chips usan tokens del design system. El stylelint hook bloquea `#000` / `#fff` / `border-left|right > 1px` / `background-clip: text`. Ver CLAUDE.md "Pre-PR UI quality gate".

**Lenguaje** — ruta en inglés (`/carrier/shipments`), claves i18n en inglés snake/dot-case, valores en español. Sin literales españoles en JSX.

**No mapa** — el listado NO muestra mapa de recorrido. Tomás lo entrega como US separada.

## Related

- **US fuente:** US17 (`docs/artifacts/backlog-us.typ:295-326`) — sección Carrier.
- **Dependencia BE:** [[REQ-BE-00035]] (endpoints de índice + detalle de envíos). Bloquea este issue.
- **Dependencia BE upstream:** [[REQ-BE-00022]] (modelos Fulfilment, mergeado), [[REQ-BE-00024]] / [[REQ-FE-00017]] (aceptación de oferta, PR #221, mergeado).
- **Hermano:** [[REQ-FE-00023]] (US17 Shipper — espejo simétrico de este componente).
- **Consumidor downstream:** [[REQ-FE-00024]] (US39 detalle — destino de cada link de fila).
- **Componentes a crear / extender:**
  - `frontend/src/pages/carrier/CarrierShipmentsPage.tsx` (nuevo).
  - `frontend/src/components/shipments/ShipmentStateChip.tsx` (nuevo, compartido).
  - `frontend/src/components/shipments/PaymentStateChip.tsx` (nuevo, compartido).
  - `frontend/src/components/shipments/ShipmentListRow.tsx` (nuevo, compartido — al menos el shell).
  - `frontend/src/hooks/useCarrierShipments.ts` (nuevo).
  - Entradas i18n en `landingContent.ts` o equivalente (verificar bundle activo).
- **Política:** [`CLAUDE.md`](../../../CLAUDE.md) — language policy, pre-PR UI quality gate.

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(carrier): ...`), sin `[REQ-FE-00022]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Coordinar con el dev del Shipper** ([[REQ-FE-00023]]) — los componentes compartidos (`ShipmentStateChip`, `PaymentStateChip`, `ShipmentListRow`) idealmente se commitean primero en uno de los dos PRs. Si ambos se desarrollan en paralelo, el segundo PR rebase sobre el primero. Discutir orden con el sprint lead.
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit` sobre el nuevo componente. Luego `just lint`, `just frontend-test-coverage` (80% threshold), `just frontend-test-e2e` (cubrir golden path + estado vacío).

## Acceptance Criteria

> AC1–AC9 son textuales de US17 (`docs/artifacts/backlog-us.typ:313-321`) filtrados al lado Carrier. AC10–AC13 son las garantías técnicas adicionales.

- [ ] **AC1** — Existe una pantalla en `/carrier/shipments` accesible solo a transportistas autenticados. Acceso por no-Carrier → redirección (al dashboard) con toast i18n. Acceso sin auth → flujo de login.
- [ ] **AC2** — Si no hay envíos, se muestra un estado vacío con copy: «Aún no realizaste envíos. Aceptá una oferta para empezar.» (vía clave i18n).
- [ ] **AC3** — Cada fila del listado expone dos chips de estado independientes:
  - *Estado del envío*: uno de `Aceptado`, `En tránsito`, `Entregado`, `Cancelado` (claves i18n `shipment.state.*`).
  - *Estado del pago*: `Pendiente de pago` si `payment_state == "pending"`, `Pagado` si `payment_state == "paid"`. Oculto cuando el envío está `Cancelado` (el campo viene omitido del payload).
- [ ] **AC4** — Cada fila muestra información resumida: origen, destino, fecha de creación (formato es-AR), monto acordado (formato es-AR con currency ARS), y los dos chips.
- [ ] **AC5** — Cada fila enlaza al detalle del envío: `/carrier/shipments/:id` (clic en cualquier parte de la fila navega).
- [ ] **AC6** — El ordenamiento por defecto es por fecha de actividad más reciente, descendente (definido por el backend; el frontend no reordena).
- [ ] **AC7** — Toda la copy de UI se resuelve por clave i18n; no hay literales en español hardcodeados en el componente.
- [ ] **AC8** — Sin filtros por estado, sin búsqueda, sin paginación: listado plano. (Fuera de alcance explícito.)
- [ ] **AC9** — Sin mapa de recorrido en cada fila (corresponde a la US "marcar Recorrido" de Tomás).
- [ ] **AC10** — Estado de carga visible mientras la request está en vuelo (skeleton o spinner alineado con el patrón existente).
- [ ] **AC11** — Estado de error con retry si el fetch falla; mensaje vía clave i18n.
- [ ] **AC12** — Los chips (`ShipmentStateChip`, `PaymentStateChip`) y la fila (`ShipmentListRow`) están extraídos como componentes compartidos en `frontend/src/components/shipments/` — listo para reuso por [[REQ-FE-00023]] (Shipper) y [[REQ-FE-00024]] (detalle).
- [ ] **AC13** — Stylelint design-system enforcement (`just frontend-lint-css`) limpio: sin `#hex` raw, sin `border-left|right > 1px`, sin `background-clip: text`.

### Tests requeridos

- [ ] Vitest — fila renderiza ambos chips con la combinatoria de estados (8 combos relevantes: 4 estados de envío × pago pending/paid, con `cancelled` ocultando el chip de pago).
- [ ] Vitest — estado vacío con copy correcto.
- [ ] Vitest — estado de error con botón de retry.
- [ ] Vitest — fila clickeable navega a `/carrier/shipments/:id`.
- [ ] Vitest — guard de ruta: no-Carrier no llega al render del listado.
- [ ] Playwright e2e — golden path: Carrier con 2 envíos visualiza el listado, hace click en una fila, llega al detalle.
- [ ] Playwright e2e — estado vacío: Carrier sin envíos visualiza el copy correcto.

## Decisiones cerradas en triage (2026-05-24)

1. ~~**Split Carrier/Shipper vs componente multi-rol**~~ — **split**: dos componentes en dos rutas. Razón: cada persona tiene su sidebar / dashboard / submenu propio y el listado es la pantalla "home" de su flujo de Envíos; un único componente multi-rol mezcla preocupaciones.
2. ~~**Paginación / filtros / búsqueda**~~ — **fuera de alcance** (US17 textual).
3. ~~**Mapa de recorrido en filas**~~ — **fuera de alcance** (US "marcar Recorrido" de Tomás).
4. ~~**Refresh post-mutation desde el detalle**~~ — coordinar con [[REQ-FE-00024]] el evento `truckr:shipment-updated`. No bloquea este issue si el detalle aún no aterriza.
