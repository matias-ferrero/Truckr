---
tag: REQ-FE-00017
title: Bandeja de ofertas recibidas por el transportista
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/123
author: Claude Code
github_issue: 123
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDN8
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:30:00.946998+00:00Z
labels:
- REQ
- FE
- BE
- carrier
- offers-inbox
- mvp
- us10
---

## Summary

Listado para el transportista de las ofertas de viaje (`Quote`s `pending`) recibidas, con detalle expandible y CTA para aceptar. Cubre US10 fullstack.

## Problem Statement

Sin esta bandeja, las ofertas creadas por el cliente quedan invisibles desde el lado Carrier. Es la contraparte de US7.

## Expected Behavior

### Backend
- `GET /api/carriers/me/quotes?status=pending&page=1` — paginated.
- Response incluye datos del `CargoOffer` (origen, destino, peso, volumen, valor, fecha de retiro) + del `Shipper` (nombre — el contacto solo post-pago, según `REQ-BE-00008`) + monto del Quote.

### Frontend
- Ruta `/transportista/ofertas`.
- Listado tipo "inbox": cards con resumen (origen → destino, fecha, monto).
- Expandable: detalles completos del cargo + del shipper.
- CTA "Aceptar" en cada card (la lógica de aceptación vive en `REQ-BE-00024`/US12, este issue solo conecta el botón).
- Indicador de nuevas ofertas en el header (badge con count).

## Related

- US fuente: US10.
- Padres: `REQ-BE-00021` (Marketplace), `REQ-BE-00023` (auth).
- Hijos: US12 (aceptación) — el botón llama al endpoint que crea el otro issue.

## Acceptance Criteria

- [ ] `GET /api/carriers/me/quotes` con paginación y filtros por status.
- [ ] Pantalla `/transportista/ofertas` con listado + expand.
- [ ] Badge de count en header.
- [ ] E2E: shipper crea oferta, carrier la ve en su inbox.
- [ ] Solo el carrier dueño ve sus ofertas (autorización).
