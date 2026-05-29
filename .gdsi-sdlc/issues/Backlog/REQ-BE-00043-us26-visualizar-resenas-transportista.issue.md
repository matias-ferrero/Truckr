---
tag: REQ-BE-00043
title: US26 — Visualizar Reseñas de Transportista (fullstack)
priority: P2
status: backlog
created: '2026-05-29'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/282
author: Claude Code
github_issue: 282
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
- us26
- fulfilment
---

## Summary

Las reseñas de un Transportista son visibles en su perfil para todos los usuarios autenticados. Se muestra el promedio de puntuación junto a las reseñas individuales. Issue fullstack: endpoint de listado + extensión del `CarrierResource` con `rating_avg` y `reviews_count` + sección de reseñas en el perfil del Carrier.

Depende de la tabla `reviews` y el modelo `Review` creados en US20 ([[REQ-BE-00042]]).

## User story (fuente)

`docs/artifacts/backlog-us/US026.typ`:

> **US26 — Visualizar Reseñas de Transportista.** Como expedidor, quiero leer reseñas sobre los transportistas, para consultar las experiencias de otros antes de contratar un servicio.

## Acceptance Criteria

- [ ] **AC1** — Las reseñas de un transportista son visibles en su perfil para todos los usuarios autenticados.
- [ ] **AC2** — Se muestra el promedio de puntuación del transportista junto a las reseñas individuales.
- [ ] **AC3** — `GET /api/carriers/:id/reviews` soporta paginación (10 por página, `created_at desc`).
- [ ] **AC4** — `GET /api/carriers/:id` incluye `rating_avg` (decimal|null) y `reviews_count` (integer).
- [ ] **AC5** — FE muestra la sección "Reseñas" en el perfil del Carrier ([[REQ-FE-00014]]) con promedio visual (estrellas) y cards individuales (rating, fecha, texto). Estado vacío con clave i18n `reviews.carrier.empty`.
- [ ] **AC6** — RSpec cubre: listado paginado, `rating_avg` calculado correctamente, acceso de usuario no autenticado → `401`. SimpleCov no baja del baseline.

## API contract

### `GET /api/carriers/:id/reviews`

- **Authz**: cualquier usuario autenticado.
- **Params**: `page` (integer, default 1).
- **Scope**: `Review.shipper_authored.where(carrier_id: carrier.id).order(created_at: :desc).page(params[:page]).per(10)`.
- **Response**: `200 OK` con array de `ReviewResource` + metadatos de paginación.
- **Errors**: `404` si el Carrier no existe.

### `GET /api/carriers/:id` — extensión

- `rating_avg`: `Review.shipper_authored.where(carrier_id: id).average(:rating)&.round(1)`.
- `reviews_count`: `Review.shipper_authored.where(carrier_id: id).count`.

## Frontend scope

Agregar sección "Reseñas" en `/carriers/:id` ([[REQ-FE-00014]]): `rating_avg` con representación visual de estrellas + `reviews_count` + lista de cards (rating, fecha, texto). Estado vacío con i18n `reviews.carrier.empty`.

## Related

- **Depende de**: [[REQ-BE-00042]] (US20 — crea tabla `reviews` y modelo).
- **Extiende**: [[REQ-FE-00014]] (US6 — perfil del Carrier).
- **Simétrico a**: [[REQ-BE-00045]] (US54 — visualizar reseñas del Expedidor).
- **Backlog**: `docs/artifacts/backlog-us/US026.typ`.

## Implementation notes

- **Branch**: `feature/REQ-BE-00043-us26-visualizar-resenas-transportista`.
- **PR title**: `feat(reviews): US26 — Carrier review display + avg rating in profile (fullstack)`.
- **Assignee**: `@LucasDondo`.
- **Pre-PR gate**: `just lint`, `just frontend-test-coverage`, `just frontend-test-e2e`, `just backend-test`.
- **Impeccable**: `/critique`, `/polish`, `/audit` sobre la sección de reseñas en el perfil antes de abrir el PR.
