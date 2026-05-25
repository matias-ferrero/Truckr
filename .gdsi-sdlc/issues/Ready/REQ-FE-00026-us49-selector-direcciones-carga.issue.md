---
tag: REQ-FE-00026
title: Selector de Direcciones — Carga (US49 — reuso del picker compartido)
priority: P1
status: ready
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/240
author: Claude Code
github_issue: 240
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr39o
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:55:29.153661+00:00Z
labels:
- REQ
- FE
- fulfilment
- shipper
- mvp
- us49
- gmaps
sprint: 4
assignee: tcorzo
plan: docs/features/REQ/REQ-FE-00026/REQ-FE-00026-us49-selector-direcciones-carga.plan.md
---

## Summary

Reemplaza los inputs de texto libre de las direcciones de retiro y entrega en el formulario de publicación de carga (US27) y en el de edición (US47) por el **mismo `<AddressPicker />`** que entrega [[REQ-FE-00025]] (US48). El formulario captura por cada dirección: texto formateado + `lat` / `lng` (`DECIMAL(9,6)`). Cero código duplicado: este issue es montaje del componente compartido.

## Problem Statement

US27 hoy persiste origen y destino como strings libres en `cargos`. Sin pines geocodificados, US5 («Filtrar Ventanas Compatibles») no puede ordenar las ventanas por distancia al origen de la carga ni filtrar por el `pickup_radius_km` de US50 (la otra punta del Haversine match). US49 hace simétrica la cobertura geocodificada: `transport_windows` (US48) + `cargos` (US49) = el match espacial de US5 tiene los dos extremos.

Por construcción, este issue es trivial — el componente y su contrato ya están especificados y testeados en US48. Lo único que cambia es **dónde se monta** y **qué columnas persiste** (en `cargos` en vez de `transport_windows`).

## Expected Behavior

### Integración en US27 (publicar carga)

- El formulario de US27 reemplaza los inputs de texto libre de **dirección de retiro** y **dirección de entrega** por dos instancias del `<AddressPicker />` entregado por [[REQ-FE-00025]].
- Mismo restriction `country: 'ar'`, mismo formato de captura, mismo manejo de error (servicio caído, no-confirmación).
- El form persiste `pickup_lat`, `pickup_lng`, `delivery_lat`, `delivery_lng` además del texto (todos obligatorios per AC4).
- Submit del form: si cualquiera de las cuatro coordenadas falta o el usuario no confirmó la sugerencia, bloquea con error i18n.

### Integración en US47 (editar carga)

- Cuando el Shipper abre el form de edición, los `<AddressPicker />` se prepoblan con los `{ text, lat, lng }` actuales.
- Editar y confirmar nueva dirección reemplaza los tres valores; texto sin confirmar bloquea el submit.

### Preview del mapa (AC5 de US48 → reflejado acá)

- La pantalla muestra un pequeño preview del mapa con los pines de retiro y entrega seleccionados, como confirmación visual antes de guardar.
- Reusa el componente `<ShipmentMap />` introducido por [[REQ-FE-00028]] (US51, mismo sprint) si ya aterrizó; si no, un preview minimal (estático, dos pines) inline en este issue. Coordinar: si US51 va antes, este issue lo consume; si va después, este issue entrega un preview minimal y US51 hace el upgrade.

### Defensive — datos legacy

No hay datos legacy. Las cuatro coordenadas son `NOT NULL` para nuevos registros (decisión cerrada en triage 2026-05-24, ver [[REQ-BE-00036]]).

## Acceptance Criteria

> AC1–AC6 son textuales de US49 (`docs/artifacts/backlog-us.typ:709-727`). AC7–AC9 son garantías técnicas adicionales.

- [ ] **AC1** — El formulario de publicación de carga (US27) y el de edición (US47) reemplazan los inputs de texto libre de las direcciones de retiro y entrega por un selector de direcciones (Google Places Autocomplete).
- [ ] **AC2** — El selector reutiliza el componente FE definido en US48 (mismo restriction `country: 'ar'`, mismo formato `texto + lat + lng`, mismo manejo de error de Google Places).
- [ ] **AC3** — Al confirmar una sugerencia, el formulario captura tres datos por dirección: el texto formateado, y el par `lat` / `lng`.
- [ ] **AC4** — El backend rechaza la creación o edición de una carga cuyos `pickup_lat` / `pickup_lng` o `delivery_lat` / `delivery_lng` estén ausentes o inválidos (HTTP 422 con clave i18n). Ver [[REQ-BE-00036]].
- [ ] **AC5** — La pantalla muestra un pequeño preview del mapa con los pines de retiro y entrega seleccionados, como confirmación visual antes de guardar.
- [ ] **AC6** — Toda la copy del selector se resuelve por clave i18n; no hay literales en español hardcodeados.
- [ ] **AC7** — Cero código duplicado del picker — el componente es el de [[REQ-FE-00025]] montado tal cual.
- [ ] **AC8** — Vitest cubre los flows de US27 (crear con coordenadas) y US47 (editar con prepoblación) ≥ 80%.
- [ ] **AC9** — Playwright e2e cubre el golden path: Shipper publica una carga, ambas direcciones quedan geocodificadas, el backend persiste los cuatro `lat`/`lng`.

### Tests requeridos

- [ ] Vitest — render del form de US27 con dos pickers; submit bloqueado si falta alguna coordenada.
- [ ] Vitest — render del form de US47 con prepoblación; edición + confirmación reemplaza valores.
- [ ] Vitest — preview del mapa muestra dos pines en las coordenadas confirmadas.
- [ ] Playwright e2e — Shipper publica una carga, verifica POST `/api/cargos` con `pickup_lat` / `pickup_lng` / `delivery_lat` / `delivery_lng`.
- [ ] Playwright e2e — Shipper edita una carga existente, verifica PATCH con coordenadas actualizadas.

## Technical Notes

**Dependencia FE-FE estricta** — este issue se planifica con [[REQ-FE-00025]] como dependencia hard. No se puede arrancar el PR de US49 hasta que el `<AddressPicker />` esté mergeado (o al menos exportado en una rama compartida). Coordinar el orden con el sprint plan: típico patrón = US48 va primero, US49 lo consume.

**Coordinación con [[REQ-FE-00028]] (US51)** — el preview del mapa de AC5 es un caso reducido del `<ShipmentMap />` de US51. Si US51 entrega primero, lo reusamos. Si US49 entrega primero, dejamos un preview minimal (estático, hardcodeado a dos pines) y un TODO inline para que US51 lo unifique.

**SQLite-forever** — `pickup_lat` / `pickup_lng` / `delivery_lat` / `delivery_lng` como `DECIMAL(9,6)`. Sin spatial indexes, sin PostGIS.

**Lenguaje** — claves i18n en inglés, valores en español. Sin literales españoles en JSX.

## Related

- US49 en `docs/artifacts/backlog-us.typ:709-727`.
- Glossary: «Carga» (`docs/05-appendices/glossary.md`) — define `pickup_lat` / `pickup_lng` / `delivery_lat` / `delivery_lng` como `DECIMAL(9,6)`.
- Componente compartido: [[REQ-FE-00025]] (US48 — el `<AddressPicker />`).
- BE companion: [[REQ-BE-00036]] (migraciones lat/lng + permits en `CargosController`).
- Mapa preview compartido (potencialmente): [[REQ-FE-00028]] (US51).
- Modelo BE: `backend/app/models/cargo.rb` (recibe la migración de [[REQ-BE-00036]]).

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(fulfilment): ...`), sin `[REQ-FE-00026]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Bloqueado por [[REQ-FE-00025]]** — no abrir PR hasta que el componente compartido esté disponible. Si necesitás avanzar antes, branchear desde la branch de US48 y rebasear al merge.
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit`. Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`.

## Decisiones cerradas en triage (2026-05-24)

| Tema | Decisión |
|---|---|
| Reuso del picker | US49 monta `<AddressPicker />` de US48 sin modificación. Cero duplicación. |
| Datos legacy | No hay. Las cuatro coordenadas son `NOT NULL` para nuevos registros. |
| Orden con US48 | US48 primero (entrega el componente), US49 segundo (lo monta). |
