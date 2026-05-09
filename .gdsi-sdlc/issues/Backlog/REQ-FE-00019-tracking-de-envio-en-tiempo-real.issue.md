---
tag: REQ-FE-00019
title: Tracking de envío en tiempo real (mapa + estado + ETA + auto-refresh)
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/125
author: Claude Code
github_issue: 125
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDSM
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:30:28.599709+00:00Z
labels:
- REQ
- FE
- BE
- tracking
- maps
- post-mvp
- us21
---

## Summary

Pantalla del cliente para seguir su envío en tiempo real: mapa con la posición del transportista, estado actual del envío, ETA, auto-refresh sin recargar. Cubre US21 fullstack.

## Problem Statement

US21 AC: ubicación del transportista en mapa en vivo, estado actual, estimación de tiempo, solo para viajes aceptados+pagados, auto-refresh.

## Expected Behavior

### Backend
- `GET /api/shipments/:id/tracking` — devuelve `status`, `latest_location` (`lat`, `lng`, `recorded_at`), `eta_seconds`, `route_polyline` (encoded).
- Solo el shipper dueño o el carrier asignado pueden acceder.
- Solo disponible si `Shipment.status in [in_transit]` (antes solo retorna estado, sin location).

### Frontend
- Ruta `/expedidor/envios/:id/tracking`.
- Mapa Google Maps (usa `<Map>` de `REQ-FE-00009`) con marker del carrier + polyline de la ruta.
- Card con estado actual ("En tránsito hacia el destino"), ETA, distancia restante.
- Polling cada 30s (configurable).
- Cuando el shipment pasa a `delivered`, la pantalla se transforma en confirmación + CTA "Dejar reseña".

## Related

- US fuente: US21.
- Padres: `REQ-BE-00022` (Shipment + TrackingEvent), `REQ-FE-00009` (Maps SDK), `REQ-FE-00010` (carrier publishing locations).

## Acceptance Criteria

- [ ] `GET /api/shipments/:id/tracking` con autorización.
- [ ] Pantalla `/expedidor/envios/:id/tracking` con mapa + estado + ETA.
- [ ] Auto-refresh cada 30s.
- [ ] Bloqueado para shipments no `in_transit`/`delivered`.
- [ ] Tras `delivered`, transición visual a estado completado.
- [ ] E2E con location updates simuladas (MSW + mock geolocation).
