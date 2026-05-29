---
tag: REQ-FE-00027
title: Definir Radio de Recogida — input numérico + círculo arrastrable (US50)
priority: P1
status: in_review
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/241
author: Claude Code
github_issue: 241
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr3_I
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:55:42.778748+00:00Z
labels:
- REQ
- FE
- fulfilment
- carrier
- mvp
- us50
- gmaps
sprint: 4
assignee: tcorzo
plan: docs/features/REQ/REQ-FE-00027/REQ-FE-00027-us50-definir-radio-de-recogida.plan.md
---

## Summary

Agrega un control de **radio de recogida** (en kilómetros) al formulario de publicación de ventana de transporte (US9) y al de edición (US33). El control es doble: un campo numérico (entero 1–200, default 10) sincronizado con un **círculo arrastrable** centrado en el pin de origen (introducido por [[REQ-FE-00025]] / US48). Arrastrar el borde actualiza el número y viceversa.

El valor se persiste en `pickup_radius_km` (ver [[REQ-BE-00037]]). El radio es el lado FE del filtro de US5 que excluye ventanas cuyo origen está fuera de alcance del pickup de la carga; cambiar el radio NO invalida `CargoOffer`s ya `pending` (es filtro de discoverability, no restricción retroactiva).

## Problem Statement

Sin radio, una ventana publicada en Buenos Aires aparece como compatible con una carga en Salta — la UX es ruidosa y el Carrier no tiene forma de expresar "no me muevo más de X km". US50 entrega ese control. Anclar el radio al **pin publicado** (no a la geolocalización en vivo del Carrier — vive en US13 / US21, post-MVP) mantiene el match espacial determinista y testeable sin necesidad de GPS en vivo.

La UX clave: dos controles sincronizados. Tipear "25" en el input mueve el círculo; arrastrar el círculo a ~25 km actualiza el input. Cualquier divergencia entre los dos rompe la sensación de que son la misma cosa.

## Expected Behavior

### Control numérico

- Nuevo campo `pickup_radius_km` en el form de US9, debajo (o al costado, según layout) del `<AddressPicker />` de origen.
- Input `type="number"`, `min={1}`, `max={200}`, `step={1}`, `defaultValue={10}`.
- Label clave i18n `transport_window.form.pickup_radius_km.label` con texto «Radio de recogida (km)» (es-AR).
- Placeholder con sugerencia («Ej. 10»).
- Error inline con clave i18n cuando el valor cae fuera de rango.

### Círculo arrastrable

- Bajo el input, un mini-mapa estático centrado en el pin de origen capturado por el `<AddressPicker />`.
- Sobre el mapa, un `google.maps.Circle` editable (`editable: true`, `draggable: false` — el centro está locked al pin de origen).
- Radio inicial = `pickup_radius_km * 1000` (Google Maps usa metros).
- Listener `radius_changed`: actualiza el input numérico al entero más cercano (km).
- Listener al `change` del input numérico: actualiza `circle.setRadius(value * 1000)`.
- Si el pin de origen aún no se confirmó (form recién montado, vacío): el mapa muestra un placeholder con copy i18n («Seleccioná el origen para definir el radio»). Cuando se confirma el origen, el mapa se centra y aparece el círculo con el default.

### Integración en US33 (editar ventana)

- En el form de US33, el control se prepoblar con el valor actual de `pickup_radius_km` de la ventana.
- Editar y guardar emite PATCH con el nuevo valor.
- **No se muestra advertencia** sobre `CargoOffer`s pendientes al achicar el radio (decisión cerrada: el radio es discoverability, no retroactivo). Sin diálogo, sin friction.

### Validación

- Server-side: `pickup_radius_km` `INTEGER`, `NOT NULL`, validación de rango (1–200) en `TransportWindow`. Rechazo HTTP 422 con clave i18n. Ver [[REQ-BE-00037]].
- Client-side: input nativo `min`/`max` + validación explícita en el form library (yup / zod / lo que use el frontend); mostrar error inline antes de submitear.

## Acceptance Criteria

> AC1–AC6 son textuales de US50 (`docs/artifacts/backlog-us.typ:729-747`). AC7–AC10 son garantías técnicas adicionales.

- [ ] **AC1** — En el formulario de publicación de ventana (US9), un nuevo campo numérico «Radio de recogida (km)» permite ingresar un valor entero entre 1 y 200; valor por defecto 10 km.
- [ ] **AC2** — El preview del mapa de origen (introducido por US48) renderiza un círculo arrastrable centrado en el pin del origen; arrastrar el borde del círculo actualiza el valor numérico y viceversa (los dos controles están sincronizados al entero más cercano de km).
- [ ] **AC3** — El valor del radio se persiste en `pickup_radius_km` y se valida server-side: rechazo HTTP 422 con clave i18n si está fuera del rango permitido o si falta. Ver [[REQ-BE-00037]].
- [ ] **AC4** — El radio es editable a posteriori desde el formulario de US33 «Editar Ventana de Transporte» — misma UI, mismo rango.
- [ ] **AC5** — Cambiar el radio (hacia arriba o hacia abajo) NO invalida ni cancela ninguna `CargoOffer` ya existente en estado `pending` contra esta ventana. (Garantía BE — el FE no muestra advertencia.) Ver [[REQ-BE-00037]].
- [ ] **AC6** — Toda la copy del control (label, placeholder, mensaje de validación) se resuelve por clave i18n.
- [ ] **AC7** — Si el pin de origen aún no fue confirmado, el mapa muestra un placeholder con copy i18n («Seleccioná el origen para definir el radio»); el control numérico queda deshabilitado hasta que haya pin.
- [ ] **AC8** — Sincronización bidireccional: tipear en el input mueve el círculo, arrastrar el círculo actualiza el input. Sin lag percibible y sin loops (debounce si hace falta).
- [ ] **AC9** — Vitest cubre los estados (idle/sin-pin, con-pin/default, edit-via-input, edit-via-drag, out-of-range error) ≥ 80%.
- [ ] **AC10** — Playwright e2e: Carrier publica una ventana con radio custom, verifica que el POST persiste el valor; luego Carrier edita la ventana via US33, cambia el radio, verifica PATCH.

### Tests requeridos

- [ ] Vitest — input acepta 1–200 enteros; rechaza 0, negativos, decimales, >200.
- [ ] Vitest — input prepoblado con default 10 al montar; con el valor existente en US33.
- [ ] Vitest — placeholder mostrado cuando no hay pin de origen; input deshabilitado.
- [ ] Vitest — drag del círculo dispara `onChange` del input al entero más cercano de km.
- [ ] Vitest — change del input dispara `circle.setRadius()` con el valor en metros.
- [ ] Playwright e2e — Carrier publica ventana con radio 25; el POST persiste 25; abre la ventana via US33; el control se prepoblar con 25; cambia a 50; PATCH persiste 50.

## Technical Notes

**Locked center** — el `google.maps.Circle` tiene `editable: true` para permitir resize, pero **NO `draggable: true`** porque el centro está locked al pin de origen. Si el usuario arrastra el círculo entero, ignorar el evento `center_changed` (forzar `circle.setCenter(originLatLng)` en cada update del pin).

**Default value origin** — el `defaultValue={10}` vive **en el componente FE**, no en la migración BE. La migración define el column type y la constraint NOT NULL; el default UX lo da el form. Ver [[REQ-BE-00037]] — no hardcodear el default en dos lados.

**Sincronización sin loops** — al actualizar el círculo desde el input, marcar un flag local (`isSettingFromInput`) y reincorporarlo a `false` después del próximo tick para que el listener de `radius_changed` no re-dispare el `onChange` del input. Pattern estándar de two-way binding.

**SQLite-forever** — `pickup_radius_km` `INTEGER NOT NULL`. **El filtrado por radio en US5 NO es PostGIS** — es Haversine en código Ruby contra `origin_lat` / `origin_lng` (ver [[REQ-BE-00037]] para la cobertura del lado matcher).

**Lenguaje** — claves i18n en inglés, valores en español. Sin literales españoles en JSX.

**Design system / lint** — input numérico via primitive del DS; sin raw hex; sin gradient-text.

## Related

- US50 en `docs/artifacts/backlog-us.typ:729-747`.
- Glossary: «Radio de recogida» (`docs/05-appendices/glossary.md`) — define semántica, anchor, no-retroactividad.
- Dependencia hard FE: [[REQ-FE-00025]] (US48 — el pin de origen viene del `<AddressPicker />`).
- BE companion: [[REQ-BE-00037]] (`pickup_radius_km` column + validación de rango + Haversine en el US5 matcher).
- US5 (filtrado con radio): `docs/artifacts/backlog-us.typ:109-128`.
- Cliente upstream: US33 (Editar Ventana de Transporte).

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(fulfilment): ...`), sin `[REQ-FE-00027]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Bloqueado por [[REQ-FE-00025]]** y por [[REQ-BE-00037]] — necesitás el pin de origen (FE) y la columna persistente (BE) antes de que este PR aporte valor end-to-end.
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit` (especialmente importante por la sincronización bidireccional input ↔ círculo, fácil de hacer mal). Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`.

## Decisiones cerradas en triage (2026-05-24)

| Tema | Decisión |
|---|---|
| Anchor del radio | Pin publicado de la ventana. **Nunca** geolocalización en vivo del Carrier. |
| Editabilidad | Vía US33 «Editar Ventana». Misma UI, mismo rango. |
| Shrinkage vs in-flight offers | NO invalida ni cancela `CargoOffer`s en `pending`. Sin advertencia FE. |
| Rango y default | 1–200 km enteros; default 10. |
| Cálculo de distancia | Haversine en código Ruby (no PostGIS) — del lado BE en [[REQ-BE-00037]]. |
