---
tag: REQ-BE-00026
title: Marcar producto como retirado (transición Shipment → in_transit)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/106
author: Claude Code
github_issue: 106
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCjc
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:26:36.937313+00:00Z
labels:
- REQ
- BE
- FE
- shipment-state
- mvp
- us18
---

## Summary

El transportista marca el producto como retirado. Transiciona el `Shipment.status: accepted → in_transit`, registra `picked_up_at` y un `TrackingEvent`. El cliente ve el cambio reflejado. Cubre US18 fullstack.

## Problem Statement

US18 AC: botón para marcar como retirado, cliente ve estado actualizado, fecha y hora registradas, no permitir si no está aceptado y pagado.

## Expected Behavior

### Backend
- `POST /api/carriers/me/shipments/:id/mark_picked_up` — solo carrier dueño + solo si `Shipment.status == accepted` (que implica CargoOffer pagado).
- `Shipment.transition_to!(:in_transit)` (de `REQ-BE-00022`), set `picked_up_at`, emite `TrackingEvent`.
- Notifica al cliente (in-app + email) con el cambio de estado.

### Frontend
- En la pantalla de viaje activo del carrier (`/transportista/viajes/:id`), botón destacado "Marcar como retirado".
- Confirmación modal antes de la acción (irreversible en el flujo MVP).
- Tras marcar, el botón se reemplaza por "Marcar como entregado" (placeholder hasta `REQ-BE-00027` / US19).
- En la pantalla del cliente (`/expedidor/envios/:id`), el estado se refresca a "En tránsito" con timestamp.

## Related

- US fuente: US18.
- Padres: `REQ-BE-00022` (Shipment state machine), `REQ-BE-00024` (US12 — el shipment debe existir y estar `accepted`).
- Hermano: `REQ-BE-00027` (US19 mark delivered).

## Acceptance Criteria

- [ ] `POST /api/carriers/me/shipments/:id/mark_picked_up` con request specs (happy + estado inválido + no-owner).
- [ ] Transición atómica + `TrackingEvent` + `picked_up_at` set.
- [ ] Notificación al cliente.
- [ ] Botón en frontend con confirmación.
- [ ] E2E: aceptar viaje → pagar → marcar retirado → ver "in_transit".
