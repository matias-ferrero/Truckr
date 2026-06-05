---
tag: REQ-FE-00023
title: Listado de Envíos del Expedidor (US17 — vista Shipper)
priority: P1
status: backlog
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/237
author: Claude Code
github_issue: 237
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr31w
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:54:49.099310+00:00Z
labels:
- REQ
- FE
- fulfilment
- shipper
- mvp
- us17
---

## Summary

Pantalla en `/shipper/shipments` accesible solo a Shippers autenticados que lista los `Shipment` que el usuario contrató. Espejo simétrico de [[REQ-FE-00022]] (Carrier): mismos chips compartidos, mismas reglas de orden y estado vacío con copy específico, mismo flujo de navegación al detalle (`/shipper/shipments/:id`). Consume `GET /api/shippers/me/shipments` (`REQ-BE-00035`).

## Problem Statement

Hoy el Shipper no tiene un punto de entrada en la UI para revisar los envíos que contrató una vez que se cerró el flujo de oferta. US17 le da ese listado, paralelo al del Carrier, para hacer seguimiento del estado del envío y del pago.

El componente es simétrico al del Carrier pero NO compartido — el split (dos rutas, dos componentes, dos endpoints) lo decidió la grilling session. La carve-out es que los building blocks (chips, fila base) sí se comparten — extraerlos en `frontend/src/components/shipments/`.

## Expected Behavior

### Ruta y guardado

- Componente React montado en `/shipper/shipments`.
- Guard: solo accesible si el usuario autenticado tiene rol Shipper. Si no es Shipper → redirección al dashboard con toast "Sección sólo accesible para expedidores" (clave i18n). Sin Shipper autenticado → flujo de login.
- Entrada en el sidebar del Shipper con label **"Mis Envíos"** (clave i18n).

### Layout

- Cabecera con título "Mis Envíos" (clave i18n `shipper.shipments.list.title`) + subtítulo / hint.
- Lista de filas. Sin paginación en este sprint.
- Estado vacío explícito (ver siguiente sub-sección).
- Estado de carga (skeleton / spinner).
- Estado de error con retry.

### Estado vacío

- Si la respuesta del endpoint es `{ shipments: [] }`: render del estado vacío con copy literal:
  > "Aún no contrataste envíos. Publicá una carga para empezar."
- Resuelta vía clave i18n (`shipper.shipments.list.empty.title` + `...empty.body`). Sin literales hardcoded.
- CTA secundaria opcional: link a "Publicar carga" (verificar la ruta canónica con `REQ-BE-00032` / US27).

### Fila

Reusa el componente `ShipmentListRow` (compartido con Carrier, extraído en [[REQ-FE-00022]] o aquí — el primero en aterrizar). El componente acepta el `Shipment` resumido y la URL del detalle como prop; el chip de pago se oculta cuando `state == "cancelled"`. Reglas idénticas a las del Carrier — ver AC3-AC5 de [[REQ-FE-00022]].

Toda la fila es clickeable como link a `/shipper/shipments/:id`.

### Orden

Definido por el backend (`latest_activity_at DESC`). El componente NO reordena.

### Sin paginación, filtros, búsqueda

Explícitamente fuera de alcance.

## Technical Notes

**Componentes compartidos** — `ShipmentStateChip`, `PaymentStateChip`, `ShipmentListRow` viven en `frontend/src/components/shipments/`. Si [[REQ-FE-00022]] aterriza primero, este issue los consume. Si aterriza después, este issue los crea y el Carrier los consume cuando llegue. Coordinar orden de PRs con el sprint lead.

**Hook de fetch** — `useShipperShipments()` que envuelve `fetch('/api/shippers/me/shipments')`. Mismo patrón que `useCarrierShipments` del Carrier.

**Lenguaje** — ruta en inglés (`/shipper/shipments`), claves i18n en inglés, valores en español. Sin literales españoles en JSX.

**Design system / lint** — chips usan tokens. El stylelint hook bloquea raw hex / side-stripes / gradient-text. Ver CLAUDE.md.

**No mapa, no historial de tracking events** — el listado solo muestra estado y datos resumidos. Historial detallado va al detalle (US39).

## Related

- **US fuente:** US17 (`docs/artifacts/backlog-us.typ:295-326`) — sección Shipper.
- **Dependencia BE:** [[REQ-BE-00035]] (endpoints de envíos). Bloquea este issue.
- **Dependencia BE upstream:** [[REQ-BE-00022]] (modelos Fulfilment, mergeado), [[REQ-BE-00033]] (US8 pago, en planificación) — el estado `payment_state` derivado depende de la coherencia del modelo `Payment` de Brian.
- **Hermano:** [[REQ-FE-00022]] (US17 Carrier).
- **Consumidor downstream:** [[REQ-FE-00024]] (US39 detalle — destino de cada link de fila).
- **Componentes a crear / extender:**
  - `frontend/src/pages/shipper/ShipperShipmentsPage.tsx` (nuevo).
  - `frontend/src/components/shipments/{ShipmentStateChip,PaymentStateChip,ShipmentListRow}.tsx` (nuevos, compartidos — ver coordinación con [[REQ-FE-00022]]).
  - `frontend/src/hooks/useShipperShipments.ts` (nuevo).
  - Entradas i18n en el bundle activo.
- **Política:** [`CLAUDE.md`](../../../CLAUDE.md).

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(shipper): ...`), sin `[REQ-FE-00023]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Coordinar con el dev del Carrier** ([[REQ-FE-00022]]) — los componentes compartidos los commitea uno de los dos PRs; el segundo rebase.
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit`. Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`.

## Acceptance Criteria

> AC1–AC9 son textuales de US17 (`docs/artifacts/backlog-us.typ:313-321`) filtrados al lado Shipper. AC10–AC13 son garantías técnicas.

- [ ] **AC1** — Existe una pantalla en `/shipper/shipments` accesible solo a expedidores autenticados. Acceso por no-Shipper → redirección con toast i18n. Sin auth → login.
- [ ] **AC2** — Si no hay envíos, se muestra un estado vacío con copy: «Aún no contrataste envíos. Publicá una carga para empezar.» (vía clave i18n).
- [ ] **AC3** — Cada fila expone los dos chips compartidos (`ShipmentStateChip`, `PaymentStateChip`) con las mismas reglas que la vista Carrier — incluida la ocultación del chip de pago si el envío está cancelled.
- [ ] **AC4** — Cada fila muestra información resumida: origen, destino, fecha de creación (es-AR), monto acordado (es-AR, ARS), y los dos chips.
- [ ] **AC5** — Cada fila enlaza al detalle: `/shipper/shipments/:id`.
- [ ] **AC6** — Orden por fecha de actividad más reciente, descendente (definido por el backend).
- [ ] **AC7** — Toda la copy de UI via clave i18n; sin literales españoles hardcoded.
- [ ] **AC8** — Sin filtros / búsqueda / paginación.
- [ ] **AC9** — Sin mapa de recorrido (Tomás).
- [ ] **AC10** — Estado de carga visible mientras la request está en vuelo.
- [ ] **AC11** — Estado de error con retry; mensaje via clave i18n.
- [ ] **AC12** — Componentes compartidos (`ShipmentStateChip`, `PaymentStateChip`, `ShipmentListRow`) consumidos desde `frontend/src/components/shipments/`. No hay copy-paste con la vista Carrier.
- [ ] **AC13** — `just frontend-lint-css` limpio.

### Tests requeridos

- [ ] Vitest — fila renderiza los chips con la combinatoria de estados (igual que Carrier).
- [ ] Vitest — estado vacío con copy específico del Shipper.
- [ ] Vitest — estado de error con botón de retry.
- [ ] Vitest — fila clickeable navega a `/shipper/shipments/:id`.
- [ ] Vitest — guard de ruta: no-Shipper no llega al render.
- [ ] Playwright e2e — golden path: Shipper con envíos, click en fila, llega al detalle.
- [ ] Playwright e2e — estado vacío: Shipper sin envíos visualiza copy correcto.

## Decisiones cerradas en triage (2026-05-24)

1. ~~**Split vs multi-rol**~~ — split (mismo razonamiento que [[REQ-FE-00022]]).
2. ~~**Componentes compartidos en `components/shipments/`**~~ — sí, no duplicar entre Carrier/Shipper/detalle.
3. ~~**Paginación / filtros / búsqueda / mapa**~~ — fuera de alcance.
