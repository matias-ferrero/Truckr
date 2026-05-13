---
tag: REQ-FE-00006
title: Búsqueda de ventanas de transporte por zona origen/destino y rango de fechas
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

Pantalla y endpoint base de búsqueda de **ventanas de transporte** (`TransportWindow`) por zona de origen, zona de destino y rango de fechas — la rebanada **fundacional** de US4 (sin paginado ni ordenamiento, que se abordan en issues hermanos). Cada resultado representa una ventana publicada por un `Carrier` y enlaza al detalle del carrier responsable (US6) conservando el contexto de la ventana seleccionada.

## Problem Statement

US4 (`docs/artifacts/backlog-us.typ`) describe el flujo de descubrimiento del Shipper: a partir de su carga, encontrar transporte disponible para esa ruta y fecha. La unidad correcta de descubrimiento es la `TransportWindow` (origen + destino + franja temporal + vehículo), no el `Carrier` aislado — un mismo carrier puede tener múltiples ventanas con rutas y fechas distintas, y al Shipper le importa el slot, no la persona. Esta rebanada cubre la búsqueda básica; paginado y ordenamiento van en issues hermanos.

## Expected Behavior

- Pantalla `/buscar` (frontend) con tres campos:
  - Zona origen (input de texto libre por ahora; autocomplete diferido).
  - Zona destino (idem).
  - Rango de fechas de retiro (date pickers desde/hasta).
- Endpoint `GET /api/transport_windows/search?origin_zone=...&destination_zone=...&date_from=...&date_to=...` que devuelve un array de `TransportWindow`s activas que matchean el par origen→destino y se solapan con el rango de fechas. Cada resultado embebe los datos básicos del `Carrier` responsable y del `Vehicle` asociado.
- Resultado: lista plana (sin paginado todavía — el paginado vive en `REQ-FE-00007`).
- Click sobre una ventana navega al detalle del carrier responsable (`/carriers/:id?window=:window_id`) — placeholder o link al detalle de US6 cuando exista, conservando el `window_id` para que la pantalla de detalle pueda calcular el costo estimado contra esa ventana específica.
- Estados: vacío (sin búsqueda aún), sin resultados, cargando, error.

## Current Behavior

No existe endpoint ni pantalla. El frontend solo tiene `App.tsx` con un quote-form de placeholder.

## Impact

- **Shipper**: primera capacidad real de descubrimiento. Bloquea US5 (filtrado), US6 (detalles del carrier), US7 (oferta).
- **Backend**: forza decisiones tempranas sobre cómo persistir zonas (lat/lng vs string libre vs catálogo). Estas decisiones deberían tomarse alineadas con el ADR de geo-storage que sale de `REQ-BE-00005`.
- **Demo loop**: cierra el lado Shipper del marketplace contra las `TransportWindow`s publicadas por Carriers (US9).

## Technical Notes

- **Modelado**: `TransportWindow` belongs_to `Carrier`, belongs_to `Vehicle`. El matching MVP puede ser case-insensitive substring sobre strings de zona (Phase 0/1) hasta que haya catálogo de localidades o PostGIS.
- **Solapamiento de fechas**: `available_from <= date_to AND available_to >= date_from`. Indexar `(origin_zone, destination_zone, available_from, available_to)`.
- **Solo ventanas activas**: excluir las despublicadas (`active = false`) — coordinar con `REQ-FE-00016`.
- **Dependencias**: requiere que `REQ-BE-00005` (modelo de dominio) esté cerrado para `Carrier`, `Vehicle` y `TransportWindow`.
- **Query**: snake_case en JSON (regla del proyecto). Sin envelope de error todavía; usar la convención existente.
- **Naming**: el endpoint usa `transport_windows`, no `ventanas`. El copy de UI usa "ventanas de transporte" (es-AR).

## Related

- US fuente: `docs/artifacts/backlog-us.typ` US4.
- USM: epic "Ver Ventanas de Transporte Disponibles".
- Issues hermanos (splits de US4): `REQ-FE-00007` (paginado), `REQ-FE-00008` (ordenamiento).
- Issues dependientes: `REQ-BE-00005` (modelo de dominio — bloqueante), `REQ-FE-00016` (publicación de ventanas — sin ventanas publicadas no hay nada que buscar).
- Issues consumidores: US5 filtrado (futuro), US6 detalles del carrier (futuro), US7 oferta (futuro).

## Acceptance Criteria

- [ ] Endpoint `GET /api/transport_windows/search` implementado, devuelve JSON snake_case con `TransportWindow` + `carrier` + `vehicle` embebidos, query params validados.
- [ ] Solo devuelve ventanas activas que solapen origen, destino y rango de fechas.
- [ ] Pantalla `/buscar` con los tres campos (origen, destino, rango de fechas).
- [ ] Submit dispara la búsqueda y renderiza la lista de resultados (cards con datos básicos: zonas, franja temporal, precio/km, nombre del transportista, capacidad del vehículo).
- [ ] Estado vacío, sin resultados, cargando y error cubiertos visualmente.
- [ ] Click en resultado navega a `/carriers/:id?window=:window_id` (puede ser placeholder hasta que exista US6).
- [ ] Sin paginado y sin ordenamiento (explícitamente fuera de scope — issues hermanos).
- [ ] Test mínimo: smoke E2E (Playwright) que ejerce el happy path con resultados mockeados (MSW en frontend, fixture en backend).
- [ ] Identifiers en inglés, copy en es-AR.
