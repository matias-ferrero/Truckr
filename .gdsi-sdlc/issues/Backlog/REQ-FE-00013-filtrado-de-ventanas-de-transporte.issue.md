---
tag: REQ-FE-00013
title: Filtrado multi-criterio en búsqueda de ventanas de transporte (precio, peso, volumen)
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/119
author: Claude Code
github_issue: 119
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDCo
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:29:11.625288+00:00Z
labels:
- REQ
- FE
- BE
- search
- filters
- mvp
- us5
---

## Summary

Permitir al Shipper refinar los resultados de la búsqueda de **ventanas de transporte** con filtros: precio por kilómetro, capacidad de carga del vehículo asociado (peso, volumen), distancia máxima. Cubre US5 fullstack sobre la base de `REQ-FE-00006`.

## Problem Statement

US5 lista varios filtros como AC: precio por km, peso, volumen, combinables, con reset. Sin estos filtros, la búsqueda devuelve listas inflables que no escalan. Los filtros aplican sobre la `TransportWindow` (precio/km) y sobre el `Vehicle` asociado (peso, volumen, capacidad).

## Expected Behavior

### Backend
- `GET /api/transport_windows/search` extiende los query params: `price_max`, `weight_min_kg`, `volume_min_cm3`, `max_distance_km`.
- Whitelist server-side; cualquier combinación es válida.
- Indexes apropiados sobre `vehicles.max_load_kg`, `vehicles.volume_cm3`, `transport_windows.price_per_km`.

### Frontend
- Sidebar/drawer de filtros sobre la página `/buscar`.
- Cada filtro: slider o input numérico.
- Botón "Aplicar" + "Limpiar todos".
- Filtros activos se reflejan como chips removibles arriba del listado.
- Estado persiste en URL (`?price_max=...&...`).

## Related

- US fuente: US5.
- Padres: `REQ-FE-00006` (search base), `REQ-BE-00021` (Marketplace), `REQ-BE-00009` (Vehicle).

## Acceptance Criteria

- [ ] Endpoint acepta los 4 filtros con whitelist y validación.
- [ ] UI de sidebar con sliders/inputs.
- [ ] Filtros combinables; reset disponible.
- [ ] Filtros persistentes en URL.
- [ ] E2E: aplicar filtro, ver lista reducida, limpiar, ver lista original.
- [ ] Coexistencia con paginado y sort de issues hermanos.
