---
tag: REQ-FE-00016
title: Publicar disponibilidad del transportista (TransportWindow CRUD)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/122
author: Claude Code
github_issue: 122
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDLc
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:29:48.618802+00:00Z
labels:
- REQ
- FE
- BE
- carrier
- transport-window
- mvp
- us9
---

## Summary

El transportista publica su disponibilidad: zona origen, precio/km, kilómetros máximos, ventana de fechas. Crea/edita/despublica `TransportWindow`s. Cubre US9 fullstack.

## Problem Statement

Sin disponibilidad publicada, los Shippers no encuentran transportistas y la búsqueda (US4) devuelve listas vacías. Es la contraparte visible de la búsqueda.

## Expected Behavior

### Backend
- `POST /api/carriers/me/transport_windows` — crea.
- `GET /api/carriers/me/transport_windows` — lista las del carrier logueado.
- `PATCH /api/carriers/me/transport_windows/:id` — edita.
- `DELETE /api/carriers/me/transport_windows/:id` — soft delete (marcar `active=false`) — no destroy real para no romper Quotes ya creados.
- Validaciones: `price_per_km > 0`, `available_from < available_to`, fechas no en el pasado.

### Frontend
- Ruta `/transportista/disponibilidad`.
- Listado de las windows del carrier (activas + inactivas con toggle de visibilidad).
- Form para crear nueva window: zona origen, zona destino (opcional para "cualquiera"), precio/km, max km, rango de fechas, vehículo asociado (si tiene flota).
- Acciones por fila: editar, despublicar (toggle `active`), reactivar.

## Related

- US fuente: US9.
- Padres: `REQ-BE-00021` (Marketplace), `REQ-BE-00023` (auth), `REQ-BE-00009` (Vehicle).

## Acceptance Criteria

- [ ] CRUD endpoints + request specs.
- [ ] Soft delete (no `destroy`) cuando hay Quotes asociados.
- [ ] Pantalla `/transportista/disponibilidad` con CRUD funcional.
- [ ] E2E: crear window, ver que aparece en búsqueda pública (`REQ-FE-00006`), despublicar, ver que desaparece.
- [ ] Solo Carriers logueados pueden gestionar sus windows (autorización).
