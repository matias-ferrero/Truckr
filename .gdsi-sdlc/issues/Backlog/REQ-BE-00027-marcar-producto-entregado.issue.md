---
tag: REQ-BE-00027
title: Marcar producto como entregado (transición Shipment → delivered + dispara payout)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/107
author: Claude Code
github_issue: 107
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtClc
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:26:48.693061+00:00Z
labels:
- REQ
- BE
- FE
- shipment-state
- mvp
- us19
---

## Summary

El transportista confirma la entrega. Transición `Shipment.status: in_transit → delivered`, set `delivered_at`, emite `TrackingEvent`, dispara `CarrierPayoutJob` (de `REQ-BE-00011`). El cliente ve el viaje como completado y queda habilitado para reseña. Cubre US19 fullstack.

## Problem Statement

US19: botón para entregado, cliente ve completado, dispara transferencia al transportista, fecha registrada, no permitir si no está retirado.

## Expected Behavior

### Backend
- `POST /api/carriers/me/shipments/:id/mark_delivered` — solo carrier dueño + solo si `Shipment.status == in_transit`.
- Transición atómica + `TrackingEvent` + `delivered_at`.
- Encola `CarrierPayoutJob` (no espera el resultado — el job es el dueño del payout, este endpoint solo dispara).
- Notifica al cliente (email + in-app) con CTA "Dejar reseña" (link a `REQ-BE-00013` cuando exista).

### Frontend
- En `/transportista/viajes/:id`, botón "Marcar como entregado" disponible cuando el viaje está `in_transit`.
- Confirmación modal.
- Tras marcar, viaje se mueve a "viajes completados" del carrier.
- En `/expedidor/envios/:id`, estado se refresca a "Entregado" con timestamp.

## Related

- US fuente: US19.
- Padres: `REQ-BE-00022` (Shipment), `REQ-BE-00026` (US18 — debe estar `in_transit`).
- Hijos disparados: `REQ-BE-00011` (carrier payout), `REQ-BE-00013` (review window).

## Acceptance Criteria

- [ ] `POST /api/carriers/me/shipments/:id/mark_delivered` con request specs.
- [ ] Transición + `TrackingEvent` + `CarrierPayoutJob` encolado.
- [ ] Notificación al cliente con CTA reseña.
- [ ] Botón en frontend con confirmación.
- [ ] E2E: pickup → entrega → ver estado delivered + payout encolado.
