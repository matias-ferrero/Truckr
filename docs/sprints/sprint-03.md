---
sprint: 3
phase: development
status: closed
window: 2026-05-21 → 2026-05-27
in_progress_user_stories: [US32, US39, US35]
completed_user_stories: [US4, US7, US8, US10, US12, US17, US27, US46, US47, US52]
---

## Retro

- _A completar por el equipo._

## Notas por US

### Carryover de Sprint 2 (arrancadas en Sprint 2, completadas en Sprint 3)

- US7 — Ofertar retiro de una carga — completada.
- US10 — Observar ofertas recibidas (bandeja del Transportista) — completada (PR #221, `REQ-FE-00017`).
- US12 — Aceptar oferta de carga — completada (PR #221, `REQ-BE-00024`) con cascada `sibling-reject`.
- US27 — Publicar carga — completada (`REQ-BE-00032`, PR #205 — fullstack cargo).
- US46 — Ver detalles de una carga — completada.
- US47 — Editar carga — completada.

### User Stories de Sprint 3

- US4 — Búsqueda de Ventanas compatibles con mi Carga — completada vía `FIX-BE-00001` (PR #227): `TransportWindow.destination` nullable cerró los AC pendientes.
- US8 — Realizar pago del Expedidor sobre Shipment aceptado — completada (`REQ-BE-00033`, PR #272). Gateway mockeado; integración real con MercadoPago diferida fuera de alcance.
- US17 — Listado de Envíos del Transportista — completada (add-on mid-sprint, `REQ-FE-00022`, PR #258).
- US52 — Listado de Envíos del Expedidor — completada (add-on mid-sprint, `REQ-FE-00023`, bundled en PR #258).
- US32 — Baja de vehículo (soft delete vía `discard`) — sin completar (queda en progreso); PR #269 abierto al cierre del sprint, sin review.
- US39 — Detalle de envío — sin completar (queda en progreso); add-on mid-sprint sin PR al cierre.
