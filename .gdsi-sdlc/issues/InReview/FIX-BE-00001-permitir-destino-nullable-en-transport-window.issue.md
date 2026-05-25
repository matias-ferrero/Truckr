---
tag: FIX-BE-00001
title: Permitir destino nullable en TransportWindow (US4/US5 rework)
priority: P1
status: in_review
created: '2026-05-22'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/211
author: Claude Code
github_issue: 211
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-25T03:38:24.193235+00:00Z
labels:
- bug
- BE
- FE
- mvp
- marketplace
- us4
- us5
- transport-window
- FIX
plan: docs/features/FIX/FIX-BE-00001/FIX-BE-00001-permitir-destino-nullable-en-transport-window.plan.md
---

## Summary

Permitir que un `TransportWindow` se publique sin destino fijo ("destino abierto" — el Carrier ofrece llevar carga a cualquier punto dentro de su radio operativo). Hoy `destination_zone` es `NOT NULL` y `validates :origin_zone, :destination_zone, presence: true`, lo que impide modelar el caso. Cambio fullstack en un solo PR: migración + modelo + controller (búsqueda US4 / filtrado US5) + serializer + UI (resultado, detalle, formulario de publicación) + tests.

## Problem Statement

US4 (búsqueda de ventanas) y US5 (filtrado) ya están implementadas en `Api::TransportWindowsController#index` vía Ransack sobre `origin_zone_normalized_cont` y `destination_zone_normalized_cont`. El producto contempla ventanas de "destino abierto", pero el schema y el modelo bloquean ese caso:

- `backend/db/schema.rb` → `t.string "destination_zone", null: false` en `transport_windows`.
- `backend/app/models/transport_window.rb:11` → `validates :origin_zone, :destination_zone, presence: true`.
- `normalize_search_fields` (mismo archivo) ya guardea `if destination_zone.present?`, así que la transliteración tolera nulos — el bloqueo es schema + validator.

Resultado: un Carrier no puede publicar "estoy disponible para llevar carga desde Buenos Aires a cualquier destino dentro de 500 km", y el listado US4/US5 nunca devuelve ese tipo de oferta. Es una brecha de US4/US5, no una US nueva.

## Expected Behavior

### Backend

- Migración: `change_column_null :transport_windows, :destination_zone, true`. `destination_zone_normalized` ya es nullable — no requiere cambio. SQLite-friendly (sin Postgres-isms).
- `TransportWindow`: sacar `destination_zone` del validator `presence: true` (queda `validates :origin_zone, presence: true`). `normalize_search_fields` ya tolera nulo.
- `Api::TransportWindowsController#index`: cuando el shipper filtra por destino, el match debe incluir las ventanas de destino abierto (semántica: "yo te llevo a cualquier lado dentro del radio"). Implementar OR con `destination_zone_normalized IS NULL` alongside del `destination_zone_normalized_cont` actual. Ransack no expresa este OR cómodamente — preprocesar el scope antes del search o agregar un scope dedicado.
- Serializer (`TransportWindowResource` o equivalente): emitir `destination_zone: null` limpio para que el FE distinga.

### Frontend

- En el listado de resultados US4 y el detalle público, cuando `destination_zone === null` renderizar el label vía i18n key `transport_window.destination.any` (es-AR: "Destino abierto"). **NUNCA hardcodear el string** — i18n keys por política del repo.
- En el formulario donde el Carrier publica un `TransportWindow`, el campo "destino" pasa a ser opcional. Agregar helper text que aclare la semántica ("Dejá vacío si aceptás cargas a cualquier destino dentro de tu radio").

### Glossary

Si la noción de "destino abierto" no está formalizada, agregar el término a `docs/05-appendices/glossary.md` en el mismo PR (entrada nueva: `Destino abierto / Open destination — TransportWindow sin destination_zone, el Carrier acepta cargas dentro de su radio operativo`).

## Technical Notes

- **SQLite forever** — sin `EXCLUDE`, `citext`, partial indexes Postgres-only, ni framing de "Phase-2 Postgres". Migración limpia en SQLite (no hay datos prod a respetar).
- **Ransack OR con NULL**: opciones (elegir en plan):
  1. Preprocesar el params hash y armar el scope a mano antes de pasar a Ransack.
  2. Custom Ransack predicate `destination_zone_matches_or_open`.
  3. Aplicar Ransack y luego `or(TransportWindow.where(destination_zone: nil))` sobre el resultado.
- El validator de overlap (`no_vehicle_overlap`) no depende de `destination_zone` — no requiere cambio.
- `destination_zone_normalized` queda nullable; el índice `index_transport_windows_on_destination_zone_normalized` sigue siendo B-tree común y maneja nulos.

## Acceptance Criteria

- [ ] Un transportista puede publicar una `TransportWindow` sin especificar destino (request spec verde + form FE).
- [ ] La búsqueda US4 incluye ventanas de destino abierto cuando el expedidor filtra por destino (request spec con seed: 1 ventana destino fijo "Córdoba" + 1 ventana destino abierto → filtrar "Córdoba" devuelve ambas).
- [ ] La búsqueda US4 sigue respetando el filtro de origen y demás criterios (no se relaja origen).
- [ ] El listado US4/US5 muestra el label de destino abierto vía i18n key (`transport_window.destination.any`) cuando la ventana no tiene destino.
- [ ] El detalle público de la ventana muestra el mismo label.
- [ ] Las ventanas con destino fijo siguen comportándose igual — no hay regresión en US4/US5 (existing specs verdes).
- [ ] La migración corre limpia en SQLite (CI verde).
- [ ] Vitest cubre el render condicional del label en componentes afectados.
- [ ] Playwright e2e cubre el flujo de publicar una ventana de destino abierto (si el form de publicación ya está accesible end-to-end).
- [ ] Glossary actualizado con la entrada "Destino abierto" si no existe.

## Related

- US fuente: US4 (`docs/artifacts/backlog-us.typ:86`), US5 (`docs/artifacts/backlog-us.typ:109`).
- Modelo / schema tocados: `backend/app/models/transport_window.rb`, `backend/db/schema.rb` (tabla `transport_windows`).
- Controller tocado: `backend/app/controllers/api/transport_windows_controller.rb`.
- Sin dependencias bloqueantes — US4/US5 ya están implementadas y verdes; este fix amplía su alcance.
- Política aplicable: CLAUDE.md § Database policy (SQLite forever) + § Language policy (i18n keys).

## PR Notes (para cuando se abra el PR)

- Branch: `feature/FIX-BE-00001-tw-nullable-destination` (o similar — no `[TAG]` en el título).
- Título PR: debe arrancar con tipo Conventional (ej.: `fix(marketplace): allow nullable destination on TransportWindow`). Sin prefijo `[FIX-BE-00001]` — esa referencia va en el body como `Closes #<n>`.
- `gh pr create --assignee @me`.
- Quality gate pre-PR (CLAUDE.md): `/critique` → `/polish` → `/audit` sobre el form y los componentes de listado/detalle; luego `just lint`, `just frontend-test-coverage`, `just frontend-test-e2e`, `just backend-test`.
