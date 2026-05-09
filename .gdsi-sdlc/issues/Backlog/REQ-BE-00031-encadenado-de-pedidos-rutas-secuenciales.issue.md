---
tag: REQ-BE-00031
title: Encadenado de pedidos en una ruta secuencial (route suggestion + ETAs por posición)
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/111
author: Claude Code
github_issue: 111
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCvc
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:27:36.081374+00:00Z
labels:
- REQ
- BE
- FE
- chained-orders
- post-mvp
- us24
---

## Summary

Permitir al transportista encadenar pedidos en una ruta continua: el sistema sugiere ofertas compatibles con la ruta actual, calcula ETA por posición en la cadena, notifica a cada shipper su ETA estimado. Diferente de `REQ-BE-00030` (composite): aquí la ruta es secuencial, no agrupación cargada simultáneamente. Cubre US24 fullstack.

## Problem Statement

US24 difiere de US23 en que **la carga no coexiste**: el carrier hace pickup → delivery → pickup → delivery → ..., recogiendo y entregando en cadena a lo largo del recorrido. Es más exigente porque cambia las ETAs en cascada.

## Expected Behavior

### Backend
- Modelo `ChainedTrip` (o reusar `CompositeTrip` con flag `mode: composite|chained` — decisión de implementación).
- Endpoints:
  - `GET /api/carriers/me/chain_suggestions?from_shipment_id=X` — devuelve `Quote`s `pending` cuyo origen está cerca del destino del shipment X (matching geográfico). Limitado a las top-N por proximidad.
  - `POST /api/carriers/me/chained_trips` — crea con orden secuencial de shipments.
  - `GET /api/carriers/me/chained_trips/:id` — detalle con orden, ETA de cada parada según la cadena.
- ETAs calculadas en cascada: ETA de la parada N = ETA de la parada N-1 + duration entre N-1 y N.
- Cada shipper afectado recibe notificación con su ETA estimado (depende de `INF-BE-00005` mailer).

### Frontend
- En `/transportista/viajes/:id`, después de aceptar, sugerencias "Sumá a la ruta" con matching de proximidad.
- Pantalla `/transportista/cadenas/:id` con timeline de paradas + mapa secuencial.
- Cada shipper ve su ETA en `/expedidor/envios/:id/tracking` (`REQ-FE-00019`).

## Related

- US fuente: US24.
- Padres: `REQ-BE-00022` (Shipment), `REQ-BE-00030` (CompositeTrip — sirve como base si se decide reusar).
- Decisión de implementación: ¿extender CompositeTrip o crear ChainedTrip separado? Documentar al implementar.

## Acceptance Criteria

- [ ] Modelo apropiado (CompositeTrip extendido o ChainedTrip nuevo); decisión documentada.
- [ ] Endpoint de sugerencias con matching geográfico básico.
- [ ] ETAs en cascada calculadas y persistidas.
- [ ] Notificación a cada shipper con su ETA.
- [ ] UI de sugerencias + timeline + mapa secuencial.
- [ ] E2E: aceptar oferta A → ver sugerencias compatibles → encadenar oferta B → ambos shippers ven ETAs distintas según orden.
