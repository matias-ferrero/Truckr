---
tag: REQ-FE-00007
title: Paginado de resultados de búsqueda de transportistas
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/113
author: Claude Code
github_issue: 113
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtC1A
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:27:58.127246+00:00Z
labels:
- REQ
- FE
- search
- pagination
- mvp
- us4
---

## Summary

Agregar paginado server-side al endpoint y la pantalla de búsqueda de transportistas. Split de US4: aísla la decisión de paginación (cursor vs offset, page size, UI) de la búsqueda base.

## Problem Statement

La rebanada base (`REQ-FE-00006`) devuelve una lista plana. Cuando haya muchos transportistas en la zona, esa lista se vuelve impráctica y costosa de transportar por la wire. US4 explicita "se muestran en páginas distintas (paginado)" como AC.

## Expected Behavior

- Endpoint `GET /api/carriers/search` acepta `page` y `per_page` (defaults: `page=1`, `per_page=20`, max `per_page=100`).
- Respuesta incluye metadata: `{ data: [...], pagination: { page, per_page, total, total_pages } }`.
- Pantalla muestra controles de paginación (anterior/siguiente + número de página actual).
- Conserva los filtros activos al cambiar de página.
- Scroll vuelve al tope al cambiar de página.

## Technical Notes

- **Paginación**: offset-based para MVP (más simple). Cursor-based queda como evolución futura si la lista crece.
- **Total count**: `Carrier.where(...).count` está bien para volúmenes MVP. Si crece, mover a estimate (`pg_class.reltuples` cuando se migre a Postgres).
- **Performance**: agregar índice sobre las columnas de filtro (`origin_zone`, `destination_zone`) — coordinar con el issue de modelado (`REQ-BE-00005`).

## Related

- US fuente: US4.
- Issue padre / hermano: `REQ-FE-00006` (búsqueda base — debe estar cerrado primero).
- Issue hermano: `REQ-FE-00008` (sort).

## Acceptance Criteria

- [ ] Endpoint acepta `page`/`per_page`, valida rangos, devuelve metadata `pagination`.
- [ ] UI de controles de paginación funcional (anterior/siguiente + indicador de página).
- [ ] Filtros y ordenamiento persisten al cambiar de página.
- [ ] Test: caso con > 1 página de resultados verifica navegación.
- [ ] Default `per_page` documentado.
