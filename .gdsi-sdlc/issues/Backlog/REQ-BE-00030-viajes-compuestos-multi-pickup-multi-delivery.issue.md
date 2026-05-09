---
tag: REQ-BE-00030
title: Viajes compuestos — agrupar múltiples envíos en un viaje (multi-pickup / multi-delivery)
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/110
author: Claude Code
github_issue: 110
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCr0
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:27:24.659337+00:00Z
labels:
- REQ
- BE
- FE
- composite-trip
- post-mvp
- us23
---

## Summary

Permitir al transportista agrupar múltiples ofertas aceptadas en un único viaje compuesto: ruta optimizada con todos los puntos de retiro/entrega, validación de capacidad, estado individual por shipment, resumen consolidado para el carrier. Cubre US23 fullstack.

## Problem Statement

US23 (Release 3) consolida varias decisiones complejas: agrupación, validación de capacidad, ruta optimizada, estado individual visible para cada shipper, resumen para el carrier. Aunque es "fat", la regla del proyecto es entregar fullstack en un único TAG.

## Expected Behavior

### Backend
- Modelo `CompositeTrip`: `carrier_id`, `vehicle_id`, `route_id` (FK), `status` (`planned → in_transit → completed → cancelled`), timestamps.
- Asociación `composite_trip_id` (nullable) en `shipments`. Un Shipment pertenece a 0 o 1 CompositeTrip.
- Endpoints:
  - `POST /api/carriers/me/composite_trips` con `shipment_ids: [...]` — valida capacidad sumada, calcula ruta optimizada (Directions API con waypoints, optimizando orden), persiste.
  - `GET /api/carriers/me/composite_trips/:id` — detalle con orden de paradas + estado individual de cada shipment.
  - `POST /api/carriers/me/composite_trips/:id/start` — transición a `in_transit`; transicióna también todos los Shipments asociados a `in_transit`.
- Validación de capacidad: la suma de pesos y volúmenes no debe exceder la capacidad del vehículo. Falla con 422.
- Cada shipper sigue viendo su Shipment individualmente (US21 tracking funciona igual).

### Frontend
- En `/transportista/viajes-activos`, opción "Agrupar viajes" abre selector multi-check sobre Shipments `accepted` compatibles.
- Validación client-side de capacidad antes de enviar.
- Pantalla `/transportista/viajes-compuestos/:id` con mapa de ruta optimizada + lista ordenada de paradas (retiro/entrega + shipper de cada uno).
- Botón "Iniciar viaje" transiciona el grupo a `in_transit`.
- Al usar `REQ-FE-00010` (live nav) sobre un CompositeTrip, los waypoints son la ruta optimizada del viaje compuesto.

## Related

- US fuente: US23.
- Padres: `REQ-BE-00022` (Shipment), `REQ-BE-00009/10` (Vehicle + capacity), `REQ-FE-00009/10` (Maps + nav).
- Consumidor: `REQ-FE-00019` (US21 tracking — sigue funcionando por shipment).

## Acceptance Criteria

- [ ] Modelo `CompositeTrip` + asociación con Shipments.
- [ ] Endpoints de creación, detalle, start; validación de capacidad sumada.
- [ ] Ruta optimizada calculada con Directions API y persistida en `Route`.
- [ ] UI de selección + validación + visualización + start.
- [ ] Cada shipper sigue viendo su shipment individual; el carrier ve la vista consolidada.
- [ ] E2E: aceptar 2 ofertas compatibles → agruparlas → iniciar viaje compuesto → ambos shippers ven sus envíos en `in_transit`.
