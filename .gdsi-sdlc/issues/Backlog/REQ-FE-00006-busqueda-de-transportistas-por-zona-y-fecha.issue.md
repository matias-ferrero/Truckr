---
tag: REQ-FE-00006
title: Búsqueda de transportistas por zona origen/destino y rango de fechas
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/112
author: Claude Code
github_issue: 112
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCyQ
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:27:46.541254+00:00Z
labels:
- REQ
- FE
- search
- mvp
- us4
---

## Summary

Pantalla y endpoint base de búsqueda de transportistas (`Carrier`) por zona de origen, zona de destino y rango de fechas — la rebanada **fundacional** de US4 (sin paginado ni ordenamiento, que se abordan en issues hermanos). El click sobre un resultado debe navegar al detalle (US6).

## Problem Statement

US4 (`docs/artifacts/backlog-us.typ`) agrupa búsqueda + paginado + ordenamiento + click-through en un único bloque. Tratado como una sola unidad, no entra en una rebanada vertical razonable: cada criterio (zona, fecha) requiere decisiones de modelado (`TransportWindow.origin_zone`, formato de zonas: lat/lng vs string), de UX (autocomplete de localidades vs free-text) y de query (filtrado server-side vs client-side). Conviene separar la búsqueda básica del resto de los affordances (paginación, sort).

## Expected Behavior

- Pantalla `/buscar-transportistas` (frontend) con tres campos:
  - Zona origen (input de texto libre por ahora; autocomplete diferido).
  - Zona destino (idem).
  - Rango de fechas de retiro (date pickers desde/hasta).
- Endpoint `GET /api/carriers/search?origin_zone=...&destination_zone=...&date_from=...&date_to=...` que devuelve un array de `Carrier`s con sus `TransportWindow`s activas que matcheen.
- Resultado: lista plana (sin paginado todavía — el paginado vive en `REQ-FE-00007`).
- Click sobre un resultado navega a `/carriers/:id` (placeholder o link al detalle de US6 cuando exista).
- Estados: vacío (sin búsqueda aún), sin resultados, cargando, error.

## Current Behavior

No existe endpoint ni pantalla. El frontend solo tiene `App.tsx` con un quote-form de placeholder.

## Impact

- **Cliente** (`Shipper`): primera capacidad real para descubrir transportistas. Bloquea US5 (filtrado), US6 (detalles), US7 (oferta).
- **Backend**: forza decisiones tempranas sobre cómo persistir zonas (lat/lng vs string libre vs catálogo). Estas decisiones deberían tomarse alineadas con el ADR de geo-storage que sale de `REQ-BE-00005`.

## Technical Notes

- **Modelado**: `TransportWindow` belongs_to `Carrier`. El matching MVP puede ser case-insensitive substring sobre strings de zona (Phase 0/1) hasta que haya catálogo de localidades o PostGIS.
- **Dependencias**: requiere que `REQ-BE-00005` (modelo de dominio) esté cerrado para `Carrier` y `TransportWindow`.
- **Query**: snake_case en JSON (regla del proyecto). Sin envelope de error todavía; usar la convención existente.
- **Naming**: el endpoint usa `carriers`, no `transportistas`. El copy de UI usa "transportistas" (es-AR).

## Related

- US fuente: `docs/artifacts/backlog-us.typ` US4.
- USM: epic "Ver Transportistas Disponibles".
- Issues hermanos (splits de US4): `REQ-FE-00007` (paginado), `REQ-FE-00008` (ordenamiento).
- Issues dependientes: `REQ-BE-00005` (modelo de dominio — bloqueante).
- Issues consumidores: US5 filtrado (futuro), US6 detalles (futuro), US7 oferta (futuro).

## Acceptance Criteria

- [ ] Endpoint `GET /api/carriers/search` implementado, devuelve JSON snake_case, query params validados.
- [ ] Pantalla `/buscar-transportistas` con los tres campos (origen, destino, rango de fechas).
- [ ] Submit dispara la búsqueda y renderiza la lista de resultados (cards con datos básicos: nombre, zonas, precio/km).
- [ ] Estado vacío, sin resultados, cargando y error cubiertos visualmente.
- [ ] Click en resultado navega a `/carriers/:id` (puede ser placeholder hasta que exista US6).
- [ ] Sin paginado y sin ordenamiento (explícitamente fuera de scope — issues hermanos).
- [ ] Test mínimo: smoke E2E (Playwright) que ejerce el happy path con resultados mockeados (MSW en frontend, fixture en backend).
- [ ] Identifiers en inglés, copy en es-AR.
