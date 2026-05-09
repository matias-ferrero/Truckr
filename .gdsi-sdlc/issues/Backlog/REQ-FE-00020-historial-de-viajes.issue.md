---
tag: REQ-FE-00020
title: Historial de viajes (cliente y transportista, con detalle y reseñas)
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/126
author: Claude Code
github_issue: 126
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDUQ
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:30:40.541391+00:00Z
labels:
- REQ
- FE
- BE
- history
- post-mvp
- us17
---

## Summary

Pantalla de historial de viajes para ambas personas: cliente ve sus envíos (todos los estados); transportista ve sus viajes realizados. Detalle accesible. El historial del carrier es **público** para los clientes que lo evalúan. Cubre US17 fullstack.

## Problem Statement

US17 cubre dos audiencias y dos visibilidades distintas en una sola US "fat":
- Shipper ve sus envíos (privado).
- Carrier ve sus viajes (privado para él, **público parcial** para shippers que lo consultan desde US6).

Tratado como un solo issue con la regla "fullstack, no splitting", el reto es respetar visibility correctamente.

## Expected Behavior

### Backend
- `GET /api/shippers/me/shipments?status=&page=` — historial del shipper logueado.
- `GET /api/carriers/me/shipments?status=&page=` — historial completo del carrier logueado.
- `GET /api/carriers/:id/public_history?page=` — historial público del carrier (sin datos del shipper, sin precios; solo: fecha, origen-destino genérico, estado, rating de la reseña asociada). Consumido por `REQ-FE-00014` (US6).
- Paginación + filtros (estado, rango de fechas).

### Frontend
- Ruta `/expedidor/historial` para Shippers.
- Ruta `/transportista/historial` para Carriers.
- Listado tabular con: fecha, origen-destino, estado, monto (solo en privado), link al detalle.
- Detalle (`/envios/:id` para shipper, `/viajes/:id` para carrier) muestra timeline de eventos (`TrackingEvent`s), datos del viaje, reseña asociada (si existe).
- En US6 (`REQ-FE-00014`), sección "Historial público" embebida usa el endpoint público.

## Related

- US fuente: US17.
- Padres: `REQ-BE-00022` (Shipment + TrackingEvent), `REQ-BE-00023` (auth).
- Consumidor del endpoint público: `REQ-FE-00014` (US6).

## Acceptance Criteria

- [ ] Tres endpoints (shipper privado, carrier privado, carrier público) con request specs y autorización.
- [ ] El endpoint público omite datos sensibles (shipper, monto, dirección exacta).
- [ ] Pantallas `/expedidor/historial` y `/transportista/historial` con filtros y paginación.
- [ ] Detalle con timeline de TrackingEvents.
- [ ] Sección "Historial público" embebida en `REQ-FE-00014`.
- [ ] E2E: crear shipment, completarlo, verlo en ambos historiales y en el público.
