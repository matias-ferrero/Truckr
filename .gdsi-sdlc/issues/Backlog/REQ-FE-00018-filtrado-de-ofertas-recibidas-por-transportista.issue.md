---
tag: REQ-FE-00018
title: Filtrado de ofertas en bandeja del transportista
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/124
author: Claude Code
github_issue: 124
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDQA
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:30:15.176491+00:00Z
labels:
- REQ
- FE
- BE
- carrier
- offers-inbox
- filters
- mvp
- us11
---

## Summary

Filtros sobre la bandeja de ofertas (`REQ-FE-00017`): por origen, rango de fecha de retiro, peso, volumen. Cubre US11 fullstack.

## Problem Statement

Cuando un transportista activo recibe muchas ofertas, no escala revisar la lista plana. US11 prescribe los filtros como AC.

## Expected Behavior

### Backend
- `GET /api/carriers/me/quotes` extiende query params: `pickup_zone`, `pickup_date_from`, `pickup_date_to`, `weight_min`, `weight_max`, `volume_min`, `volume_max`.
- Combinables, reset implícito al omitir el param.

### Frontend
- Sidebar/drawer de filtros sobre la bandeja.
- Chips de filtros activos arriba del listado.
- Botón "Limpiar todos".
- Estado en URL (`?pickup_zone=...&...`) para que la URL sea compartible / preservable.

## Related

- US fuente: US11.
- Padre: `REQ-FE-00017`.

## Acceptance Criteria

- [ ] Query params soportados con whitelist server-side.
- [ ] UI de filtros + chips + reset.
- [ ] Filtros combinables y reflejados en URL.
- [ ] E2E: aplicar filtro, ver lista reducida.
