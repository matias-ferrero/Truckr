---
tag: REQ-FE-00008
title: Ordenamiento de resultados de búsqueda de transportistas
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/114
author: Claude Code
github_issue: 114
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtC3w
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:28:10.472230+00:00Z
labels:
- REQ
- FE
- search
- sort
- mvp
- us4
---

## Summary

Permitir al cliente ordenar los resultados de la búsqueda de transportistas por un criterio (precio/km, rating, distancia) con dirección ascendente/descendente. Split de US4.

## Problem Statement

US4 incluye "se puede seleccionar un criterio de ordenamiento (ascendente/descendente)" como AC. La elección del criterio default y los criterios disponibles deben coordinarse con la búsqueda base y el filtrado, pero la implementación misma es independiente.

## Expected Behavior

- Endpoint acepta `sort=<field>&dir=<asc|desc>`. Whitelist de fields (`price_per_km`, `rating_avg`, `created_at`).
- Default: `sort=price_per_km&dir=asc`.
- UI: dropdown con los criterios soportados + toggle de dirección, junto al listado.
- Persiste en URL (query string) para que el back-button funcione y la URL sea compartible.

## Technical Notes

- Whitelist server-side para evitar SQL injection vía `ORDER BY` arbitrario.
- Si `rating_avg` no existe todavía (depende de US20), el dropdown lo omite hasta que el campo esté disponible.

## Related

- US fuente: US4.
- Issue padre: `REQ-FE-00006` (búsqueda base).
- Hermano: `REQ-FE-00007` (paginado).

## Acceptance Criteria

- [ ] Endpoint acepta `sort` y `dir` con whitelist server-side.
- [ ] UI con dropdown + toggle de dirección.
- [ ] El criterio activo se refleja en la URL (`?sort=...&dir=...`).
- [ ] Compatible con paginado y filtros (no se pierden al cambiar el sort).
- [ ] Test: smoke verifica que cambiar el sort cambia el orden de la lista.
