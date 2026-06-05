---
tag: REQ-FE-00025
title: Selector de Direcciones — Ventana de Transporte (US48 — picker FE compartido)
priority: P1
status: in_review
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/239
author: Claude Code
github_issue: 239
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr38Q
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:55:15.697195+00:00Z
labels:
- REQ
- FE
- fulfilment
- carrier
- mvp
- us48
- gmaps
sprint: 4
assignee: tcorzo
plan: docs/features/REQ/REQ-FE-00025/REQ-FE-00025-us48-selector-direcciones-ventana-transporte.plan.md
---

## Summary

Reemplaza los inputs de texto libre de origen y destino en el formulario de publicación de ventana de transporte (US9) y en el de edición (US33) por un **selector de direcciones geocodificadas** sobre Google Places JavaScript API. Por cada dirección, el formulario captura tres datos: el texto formateado y el par `lat` / `lng` (`DECIMAL(9,6)`). El componente queda como pieza reusable: US49 (selector para `Cargo`) lo monta sin modificación.

Restricción AR-only se aplica vía `componentRestrictions: { country: 'ar' }` en el cliente — no hay bounding box ni reverse-geocode server-side (decisión cerrada en triage 2026-05-24).

## Problem Statement

Sin pines geocodificados, US5 («Filtrar Ventanas Compatibles») no puede ordenar por distancia ni filtrar por radio (US50). Hoy origen y destino son strings libres; no hay forma confiable de saber dónde está un punto. US48 es el load-bearing front-end para todo el bloque GMaps del MVP (US48 + US49 + US50 + US51).

El componente debe diseñarse para que US49 lo reuse sin tocar nada — mismo shape de captura (`texto + lat + lng`), mismo manejo de error, mismo restriction AR. La duplicación entre US48 y US49 es el síntoma a evitar.

## Expected Behavior

### Componente reusable

- Nuevo componente `<AddressPicker />` en `frontend/src/components/` (o ubicación del design system equivalente).
- Props mínimos: `name` (para el form), `label` (clave i18n), `value` (`{ text, lat, lng } | null`), `onChange`, `error?`.
- Internamente usa `@react-google-maps/api` (o equivalente — verificar lo que ya esté instalado; si nada, agregar la dep en este PR).
- Pasa `componentRestrictions: { country: 'ar' }` al `Autocomplete` — UI-only AR validation.
- Al confirmar una sugerencia, captura: el texto formateado de Google Places, `place.geometry.location.lat()`, `place.geometry.location.lng()` (truncados a 6 decimales para alinearse con `DECIMAL(9,6)`).
- Si el usuario tipea pero no confirma una sugerencia (sale del input o submitea el form), el componente entra en estado de error con clave i18n `address_picker.error.unconfirmed` y bloquea submit del form padre.
- Si la API de Google Places no responde / devuelve error de billing / quota, fallback con clave i18n `address_picker.error.service_unavailable` — el campo se vuelve inutilizable pero el resto del form sigue siendo navegable (no crashea la pantalla entera).
- Toda la copy del componente se resuelve por clave i18n; sin literales hardcodeados.

### Integración en US9 (publicar ventana)

- El formulario de US9 reemplaza los inputs de texto libre de origen y destino por dos instancias del `<AddressPicker />`.
- El form persiste `origin_lat`, `origin_lng`, `destination_lat`, `destination_lng` además del texto.
- Submit del form: si el origen no tiene `lat`/`lng` válidos → bloquea submit con error i18n. Para destino, idem si el usuario empezó a tiparlo pero no confirmó (destino puede quedar vacío — es opcional per US9).

### Integración en US33 (editar ventana)

- Cuando el usuario abre el form de edición, los `<AddressPicker />` se prepoblan con `{ text, lat, lng }` desde el estado actual de la ventana.
- Editar y confirmar una nueva dirección reemplaza los tres valores; el texto editado sin confirmar bloquea el submit como en US9.

### Defensive — datos legacy

No hay datos legacy a contemplar — la migración de [[REQ-BE-00036]] hace `origin_lat`/`origin_lng`/`destination_lat`/`destination_lng` `NOT NULL` para nuevos registros (decisión cerrada en triage 2026-05-24, no hay backfill ni filas viejas). El frontend no necesita branching defensivo para "ventana sin pines".

## Acceptance Criteria

> AC1–AC6 son textuales de US48 (`docs/artifacts/backlog-us.typ:688-707`). AC7–AC11 son garantías técnicas adicionales.

- [ ] **AC1** — El formulario de publicación de ventana de transporte (US9) reemplaza los inputs de texto libre de origen y destino por un selector de direcciones (Google Places Autocomplete).
- [ ] **AC2** — El selector restringe sugerencias a Argentina (`componentRestrictions: { country: 'ar' }`); no se llama a reverse-geocoding en backend.
- [ ] **AC3** — Al confirmar una sugerencia, el formulario captura tres datos por dirección: el texto formateado, `lat` y `lng` (`DECIMAL(9,6)`).
- [ ] **AC4** — El backend rechaza la creación o edición de una ventana cuyos `origin_lat` / `origin_lng` (siempre obligatorios) o `destination_lat` / `destination_lng` (cuando hay destino) estén ausentes o inválidos (HTTP 422 con clave i18n). Ver [[REQ-BE-00036]].
- [ ] **AC5** — Si la API de Google Places falla / no carga, el campo muestra un mensaje neutral con clave i18n y no rompe el resto del formulario.
- [ ] **AC6** — Toda la copy del selector se resuelve por clave i18n; no hay literales en español hardcodeados.
- [ ] **AC7** — El componente `<AddressPicker />` es reusable y queda disponible para [[REQ-FE-00026]] (US49) y [[REQ-FE-00027]] (US50, donde acompaña al control de radio).
- [ ] **AC8** — La integración cubre tanto US9 (publicar) como US33 (editar) — el mismo componente prepoblado.
- [ ] **AC9** — Tipear sin confirmar una sugerencia bloquea el submit con clave i18n `address_picker.error.unconfirmed`.
- [ ] **AC10** — Vitest cubre los estados del componente (idle, suggesting, confirmed, error de servicio, error de no-confirmación) ≥ 80% (umbral del repo).
- [ ] **AC11** — Playwright e2e cubre el golden path: abrir el form de US9, tipear, seleccionar sugerencia, confirmar publicación; verificar que el backend recibió `lat`/`lng`.

### Tests requeridos

- [ ] Vitest — estados idle / suggesting / confirmed / error de servicio / error de no-confirmación.
- [ ] Vitest — prepoblación correcta cuando se monta con `value` non-null (US33).
- [ ] Vitest — `onChange` se dispara con `{ text, lat, lng }` al confirmar; nunca con `lat`/`lng` `null` cuando hay sugerencia confirmada.
- [ ] Playwright e2e — Carrier publica una ventana con direcciones reales de AR (mock de la JS API en CI); verificar que el payload del POST incluye `origin_lat` / `origin_lng`.
- [ ] Playwright e2e — Carrier edita una ventana existente (US33), cambia el origen, confirma; verificar que el PATCH incluye nuevos `lat`/`lng`.

## Technical Notes

**Google Places JS API key** — separar de cualquier API key de mapas (la del componente de mapa de US51) si tienen scopes diferentes; coordinar con el responsable de infra (Fernando) para tener la key configurada en `frontend/.env`. Si la key no está, el componente debe degradar al estado `service_unavailable` (no crashear). Documentar el setup en el plan del feature.

**Decimal precision** — el frontend trunca `lat`/`lng` a 6 decimales antes de enviar al backend (alineado con `DECIMAL(9,6)`). El backend valida igual por defensa en profundidad.

**SQLite-forever** — los pines viven como columnas planas (`DECIMAL(9,6)`) en `transport_windows`. **Sin PostGIS, sin spatial indexes, sin nada que dependa de extensiones de Postgres.** El radio de US50 y el ordenamiento por distancia de US5 se computan con Haversine en código Ruby (no SQL espacial).

**Componente reusable, no duplicado** — US49 monta este mismo `<AddressPicker />` para los pines de retiro y entrega de `Cargo`. Si en algún momento se descubre que la API necesita ramificar entre los dos casos de uso, prefiero extender el componente con un prop (`types: ['address']` vs `types: ['establishment']`) antes que duplicarlo.

**Lenguaje** — claves i18n en inglés, valores en español. Sin literales españoles en JSX.

**Design system / lint** — el `<AddressPicker />` usa primitives del design system (input, label, error message). Sin raw hex; sin gradient-text.

## Related

- US48 en `docs/artifacts/backlog-us.typ:688-707`.
- Glossary: «Ventana de transporte» (`docs/05-appendices/glossary.md`) — define `origin_lat` / `origin_lng` / `destination_lat` / `destination_lng` como `DECIMAL(9,6)`.
- BE companion: [[REQ-BE-00036]] (migraciones lat/lng + permits + validaciones).
- Cliente del componente: [[REQ-FE-00026]] (US49 — mismo picker para `Cargo`).
- Cliente del componente: [[REQ-FE-00027]] (US50 — radio + circle preview anclado al pin de origen).
- Modelo BE: `backend/app/models/transport_window.rb` (recibe la migración de [[REQ-BE-00036]]).

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(fulfilment): ...`), sin `[REQ-FE-00025]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Coordinar con [[REQ-BE-00036]]** — el shape del payload (`{ origin: { text, lat, lng }, destination: { text, lat, lng } | null }` vs columnas planas en el JSON) debe acordarse antes del primer PR; usar columnas planas (`origin_lat`, `origin_lng`, etc.) en JSON keys snake_case por consistencia con el resto de la API.
- **Coordinar con Fernando** — Google Places API key en `frontend/.env`. Si no llega antes, prototipar con un mock local (Vitest msw + Playwright route stub).
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit` sobre el componente. Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`.

## Decisiones cerradas en triage (2026-05-24)

| Tema | Decisión |
|---|---|
| Validación AR | UI-only via `componentRestrictions: { country: 'ar' }`. No bounding box server-side. No reverse-geocode. |
| Datos legacy | No hay. Columnas `NOT NULL` para nuevos registros. |
| Componente shared | US48 lo entrega, US49 lo monta sin cambios. Mismo formato de captura. |
