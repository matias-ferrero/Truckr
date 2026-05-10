---
tag: REQ-BE-00009
title: Registro de vehículo — datos básicos + fotos
priority: P1
status: in_review
pr_url: https://github.com/tcorzo/fiuba-gestion-tp/pull/144
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/85
author: Claude Code
github_issue: 85
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrs6xs
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-09T13:35:40.078556+00:00Z
plan: docs/features/REQ/REQ-BE-00009/REQ-BE-00009-and-00010-vehicle-fleet.plan.md
labels:
- BE
- FE
- REQ
- mvp
- vehicle
- us14
---

## Summary

Permitir al transportista (`Carrier`) registrar **un** vehículo con sus datos (modelo, año, capacidad de carga, dimensiones) y fotos. Primera rebanada de US14, restringida al caso "1 transportista = 1 vehículo". El soporte multi-vehículo (flota) vive en el issue hermano `REQ-BE-00010`.

## Problem Statement

US14 mezcla la registración básica con el manejo de flota (más de un vehículo). El caso del 80% es 1:1 — un transportista con un solo camión — y conviene resolverlo primero. La flota agrega complejidad (UI de listado, vehículo "activo" para una publicación, etc.) que retrasa la habilitación de la US si se trata como un solo bloque.

## Expected Behavior

- Modelo `Vehicle` con: `carrier_id` (FK), `make`, `model`, `year`, `plate`, `max_load_kg` (decimal), `length_cm`, `width_cm`, `height_cm`, `volume_cm3` (computed), `description` (text), timestamps.
- Endpoints:
  - `POST /api/carriers/me/vehicle` — crear el vehículo del carrier autenticado (cuando exista auth; mientras tanto un parámetro explícito `carrier_id`).
  - `PATCH /api/carriers/me/vehicle` — actualizar.
  - `GET /api/carriers/:id/vehicle` — leer (público para que el cliente vea las specs).
- Fotos: subida via `ActiveStorage` con S3-compatible o disk storage (decisión de adapter en `INF-` separado si no existe). Hasta `N=5` fotos por vehículo.
- UI: pantalla `/transportista/vehiculo` con form de datos + uploader de fotos (drag & drop, preview, borrar).
- Las fotos del vehículo se muestran en el detalle de carrier (US6, futuro).

## Technical Notes

- **ActiveStorage**: ya viene out-of-the-box con Rails 8. El `disk` service alcanza para dev; el adapter S3 es decisión separada (`INF-` issue).
- **Image processing**: usar `image_processing` gem para variantes (thumbnail 200x200, full 1200x800).
- **Validaciones**: dimensiones positivas, año razonable (>1980, <= año actual + 1), `max_load_kg > 0`.
- **Naming**: `Vehicle` (no `Camion`). Tabla `vehicles`. Columnas en inglés.
- **Constraint**: este issue limita a 1 vehículo por carrier (`unique index on carrier_id`). El hermano `REQ-BE-00010` levanta esta restricción.

## Related

- US fuente: US14.
- Hermano: `REQ-BE-00010` (multi-vehicle / flota).
- Dependiente: `REQ-BE-00005` (modelo `Vehicle` ya esbozado en el bounded context Identity).

## Acceptance Criteria

- [ ] Modelo `Vehicle` con migración aplicada.
- [ ] Endpoints `POST/PATCH/GET` implementados con request specs.
- [ ] ActiveStorage configurado, hasta 5 fotos por vehículo.
- [ ] Pantalla `/transportista/vehiculo` con form + uploader.
- [ ] Validaciones de datos (year, dimensions, plate).
- [ ] `unique index on carrier_id` (1 vehicle máx por carrier en este issue).
- [ ] Identifiers en inglés.
- [ ] Test: feature spec del happy path (crear, ver, editar).
