---
tag: REQ-FE-00024
title: Detalles de Envío (US39 — pantalla compartida con acciones contextuales por
  rol)
priority: P1
status: ready
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/238
author: Claude Code
github_issue: 238
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr37A
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:55:02.619097+00:00Z
labels:
- REQ
- FE
- fulfilment
- carrier
- shipper
- mvp
- us39
sprint: 3
assignee: tcorzo
---

## Summary

Pantalla de detalle de un `Shipment` accesible desde el listado (US17) en dos rutas inglesas: `/carrier/shipments/:id` (Transportista) y `/shipper/shipments/:id` (Expedidor). **Un único componente** sirve ambas rutas — las acciones contextuales (botones) las dicta el backend vía el array `available_actions` del payload ([[REQ-BE-00035]]), por lo que el componente es role-aware sin lógica de rol replicada. La pantalla muestra datos del envío, chips de estado, historial de `TrackingEvent` como timeline textual, y los botones permitidos. **El mapa visual del recorrido queda fuera de alcance en Sprint 3** — sección reservada con copy placeholder; la aterriza US51 en Sprint 4 ([[REQ-FE-00028]]).

> **Sprint 3 commitment.** Owner: **@tcorzo** (Tomás). BE de soporte (`GET /api/shipments/:id`) en [[REQ-BE-00035]] (mismo sprint, owner Franco). Endpoints de mutación en [[REQ-BE-00038]] (`start_transit`, `deliver`) y [[REQ-BE-00033]] (`payments`).

**Plan:** [`docs/features/REQ/REQ-FE-00024/REQ-FE-00024-us39-detalles-de-envio.plan.md`](../../../docs/features/REQ/REQ-FE-00024/REQ-FE-00024-us39-detalles-de-envio.plan.md) — layout completo, mapping de `available_actions` a botones, matriz de estados visibles, i18n keys propuestas, y plan de tests. Lo de abajo es solo Problem Statement + AC.

## Problem Statement

US17 entrega la lista de envíos pero no permite tomar acciones sobre uno específico. El Carrier necesita iniciar transporte / confirmar entrega; el Shipper necesita pagar o reintentar pago. US39 es la pantalla donde esas acciones viven, con visibilidad determinada por el backend (`available_actions`) — el FE confía en esa lista como única fuente de verdad (safe-by-delegation).

Decisión clave del triage: **un único componente compartido entre los dos roles**, no dos pantallas espejo. El grueso del contenido es idéntico; la única variación es qué botones aparecen + qué label tiene la contraparte. El backend ya emite `available_actions` y `counterparty` resueltos por rol.

Las etiquetas **"A recoger"** y **"Pendiente de pago"** son **composiciones de UI**, no estados del FSM (ver glossary `docs/05-appendices/glossary.md:25` entrada Envío + ADR-012). El FE las deriva localmente de `Shipment.state` + payment status.

## Acceptance Criteria

> AC1–AC6 son textuales de US39 (`docs/artifacts/backlog-us.typ`). AC7–AC14 son garantías técnicas adicionales. Detalle de implementación en el plan.

- [ ] **AC1** — La pantalla de detalle es alcanzable desde el listado (US17). Rutas: `/carrier/shipments/:id` (Carrier) y `/shipper/shipments/:id` (Shipper). Un usuario no puede acceder al detalle de un envío que no le pertenece — el backend responde 404; el frontend muestra pantalla específica de "no encontrado" sin información discriminante.
- [ ] **AC2** — La pantalla muestra los datos del envío: origen, destino, descripción y peso de la carga, vehículo asignado (placa, tipo), contraparte (nombre del transportista o del expedidor según el rol que mira), fecha de creación y monto acordado.
- [ ] **AC3** — La pantalla muestra los dos chips de estado independientes definidos en US17 (`shipment.state` + `payment_state` derivado).
- [ ] **AC4** — La pantalla muestra el historial de `TrackingEvent` asociados al envío en forma de timeline textual (timestamp + tipo de evento traducido).
- [ ] **AC5** — Sección reservada para mapa visual del recorrido con copy «Se mostrará el recorrido cuando esté disponible» (clave i18n). Anclada con id estable (`<section id="shipment-tracking-map">`) para reemplazo futuro por [[REQ-FE-00028]] (US51).
- [ ] **AC6** — Acciones contextuales renderizadas a partir del array `available_actions` del payload del backend. Mapeo completo en el plan §4. Lista vacía → sin sección de acciones.
- [ ] **AC7** — El frontend NO recalcula la disponibilidad de los botones. La fuente única de verdad es `available_actions` del backend (safe-by-delegation). Si el backend dice `[]`, el componente no muestra ningún botón.
- [ ] **AC8** — Toda la copy de UI se resuelve por clave i18n; no hay literales en español hardcodeados en el componente.
- [ ] **AC9** — El bloque de contraparte usa la clave i18n correcta según el rol del usuario que consulta.
- [ ] **AC10** — Después de una mutación exitosa, el componente refetcha el detalle y refresca los chips, la timeline, y los botones. Emite evento `truckr:shipment-updated` para que el listado lo reciba si está montado.
- [ ] **AC11** — Las etiquetas UI compuestas "A recoger" (Carrier, `accepted` pre-tránsito) y "Pendiente de pago" (Shipper, `accepted` sin `Payment.escrowed`) se derivan en el FE — NO se envían ni se piden al backend (ver glossary).
- [ ] **AC12** — Pantalla de "no encontrado" cuando el backend responde 404; CTA "Volver al listado". Estado de carga (skeleton) mientras la request está en vuelo. Estado de error (≠ 404) con retry.
- [ ] **AC13** — Vitest + Playwright cubren la matriz de estados del plan §6 (golden paths Carrier y Shipper + 404 + lista vacía). Cobertura ≥ 80%.
- [ ] **AC14** — `just frontend-lint-css` limpio. PR title con conventional prefix sin `[REQ-FE-00024]`.

## Decisiones cerradas en triage (2026-05-24)

1. **Componente único multi-rol** vs split — único compartido.
2. **Acciones permitidas en el FE vs BE** — BE (`available_actions` del payload).
3. **Cancelación post-pago** — no permitida (ADR-012). Cancelación pre-pago diferida a Sprint 4+; backend omite la entrada del array.
4. **Mapa de recorrido** — fuera de alcance (US51, Sprint 4).
5. **404 vs 403 para no-contraparte** — 404 consolidado.
6. **"A recoger" / "Pendiente de pago"** — composiciones de UI, no estados del FSM (ver glossary `docs/05-appendices/glossary.md:25`).
