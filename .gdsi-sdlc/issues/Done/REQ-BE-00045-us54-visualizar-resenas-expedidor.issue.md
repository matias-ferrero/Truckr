---
tag: REQ-BE-00045
title: US54 — Visualizar Reseñas de Expedidor (fullstack)
priority: P2
status: backlog
created: '2026-05-29'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/284
author: Claude Code
github_issue: 284
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-29T00:00:00.000000+00:00Z
labels:
- REQ
- BE
- FE
- P2
- post-mvp
- reviews
- carrier
- shipper
- us54
- fulfilment
---

## Summary

Las reseñas de un Expedidor son visibles en su perfil para todos los usuarios autenticados. Se muestra el promedio de puntuación junto a las reseñas individuales. Issue fullstack: endpoint de listado + extensión del `ShipperResource` con `rating_avg` y `reviews_count` + sección de reseñas en el perfil del Shipper.

Depende de la tabla `reviews` y el modelo `Review` creados en US20 ([[REQ-BE-00042]]) y del endpoint de creación de US30 ([[REQ-BE-00044]]).

## User story (fuente)

`docs/artifacts/backlog-us/US054.typ`:

> **US54 — Visualizar Reseñas de Expedidor.** Como transportista, quiero leer reseñas sobre los expedidores, para consultar las experiencias de otros antes de contratar un servicio.

## Acceptance Criteria

- [ ] **AC1** — Las reseñas de un expedidor son visibles en su perfil para todos los usuarios autenticados.
- [ ] **AC2** — Se muestra el promedio de puntuación del expedidor junto a las reseñas individuales.
- [ ] **AC3** — `GET /api/shippers/:id/reviews` soporta paginación (10 por página, `created_at desc`).
- [ ] **AC4** — `GET /api/shippers/:id` incluye `rating_avg` (decimal|null) y `reviews_count` (integer).
- [ ] **AC5** — FE muestra la sección "Reseñas" en el perfil del Expedidor con promedio visual (estrellas) y cards individuales (rating, fecha, texto). Estado vacío con clave i18n `reviews.shipper.empty`.
- [ ] **AC6** — RSpec cubre: listado paginado, `rating_avg` calculado correctamente, acceso de usuario no autenticado → `401`. SimpleCov no baja del baseline.

## API contract

### `GET /api/shippers/:id/reviews`

- **Authz**: cualquier usuario autenticado.
- **Params**: `page` (integer, default 1).
- **Scope**: `Review.carrier_authored.where(shipper_id: shipper.id).order(created_at: :desc).page(params[:page]).per(10)`.
- **Response**: `200 OK` con array de `ReviewResource` + metadatos de paginación.
- **Errors**: `404` si el Shipper no existe.

### `GET /api/shippers/:id` — extensión

- `rating_avg`: `Review.carrier_authored.where(shipper_id: id).average(:rating)&.round(1)`.
- `reviews_count`: `Review.carrier_authored.where(shipper_id: id).count`.

## Frontend scope

Agregar sección "Reseñas" en el perfil del Expedidor: `rating_avg` con representación visual de estrellas + `reviews_count` + lista de cards (rating, fecha, texto). Estado vacío con i18n `reviews.shipper.empty`.

## Related

- **Depende de**: [[REQ-BE-00042]] (US20 — crea tabla `reviews`), [[REQ-BE-00044]] (US30 — crea reseñas Carrier→Shipper).
- **Simétrico a**: [[REQ-BE-00043]] (US26 — visualizar reseñas del Transportista).
- **Backlog**: `docs/artifacts/backlog-us/US054.typ`.

## Implementation notes

- **Branch**: `feature/REQ-BE-00045-us54-visualizar-resenas-expedidor`.
- **PR title**: `feat(reviews): US54 — Shipper review display + avg rating in profile (fullstack)`.
- **Assignee**: `@bcespedes`.
- **Pre-PR gate**: `just lint`, `just frontend-test-coverage`, `just frontend-test-e2e`, `just backend-test`.
- **Impeccable**: `/critique`, `/polish`, `/audit` sobre la sección de reseñas en el perfil antes de abrir el PR.
