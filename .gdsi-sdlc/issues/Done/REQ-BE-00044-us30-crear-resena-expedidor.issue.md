---
tag: REQ-BE-00044
title: US30 — Crear Reseña de Expedidor (Carrier→Shipper, fullstack)
priority: P2
status: backlog
created: '2026-05-29'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/283
author: Claude Code
github_issue: 283
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
- us30
- fulfilment
---

## Summary

El Transportista puede escribir una reseña sobre un Expedidor una vez que el envío se completó. Incluye rating de 1 a 5 estrellas y comentario de texto opcional. Un Transportista solo puede dejar una reseña por envío completado. Issue fullstack: endpoint de creación + formulario en la pantalla de detalle de envío (US39).

Usa la tabla `reviews` y el modelo `Review` creados en US20 ([[REQ-BE-00042]]). Implementa la dirección `authored_by: 'carrier'` (Carrier→Shipper).

## User story (fuente)

`docs/artifacts/backlog-us/US030.typ`:

> **US30 — Crear Reseña de Expedidor.** Como transportista, quiero poder escribir reseñas sobre los Expedidores, para compartir mi experiencia.

## Acceptance Criteria

- [ ] **AC1** — Un transportista puede escribir una reseña sobre un expedidor una vez que el envío se completó.
- [ ] **AC2** — La reseña incluye una puntuación (1 a 5 estrellas) y un comentario de texto (opcional, max 1000 chars).
- [ ] **AC3** — Un transportista solo puede dejar una reseña por envío completado (`409` si ya existe).
- [ ] **AC4** — Solo el Carrier asignado al Shipment puede crear la reseña. Otros usuarios → `403`.
- [ ] **AC5** — Solo se puede crear la reseña si el Shipment está en estado `delivered`. Sino → `409`.
- [ ] **AC6** — Todas las claves de error pasan por `I18n.t(...)`. Cero literales en controllers.
- [ ] **AC7** — FE muestra el formulario de reseña en la pantalla de detalle del envío ([[REQ-FE-00024]]) solo cuando `state == 'delivered'` y el viewer es el Carrier. Tras submit exitoso el formulario se deshabilita y muestra la reseña creada.
- [ ] **AC8** — RSpec cubre: happy-path, guard de estado (`409`), guard de unicidad (`409`), guard de autorización (`403`). SimpleCov no baja del baseline.

## API contract

### `POST /api/shipments/:id/carrier_reviews`

- **Authz**: `ReviewPolicy#create_carrier_review?` — `current_carrier.present? && current_carrier.id == shipment.carrier_id`.
- **Guards**: `shipment.state_delivered?` → `409` (`errors.reviews.create.shipment_not_delivered`). `Review.carrier_authored.exists?(shipment_id: shipment.id)` → `409` (`errors.reviews.create.already_reviewed`).
- **Body**: `{ "rating": integer 1-5, "body": string|null }`.
- **Side effect**: `Review.create!(shipment:, carrier: current_carrier, shipper: shipment.shipper, rating:, body:, authored_by: :carrier_authored)`.
- **Response**: `201 Created` con `ReviewResource`.
- **Errors**: `403`, `404`, `409`, `422` (validaciones).

## Frontend scope

Agregar sección "Reseñar al expedidor" en `/shipments/:id` ([[REQ-FE-00024]]): visible solo cuando `state === 'delivered'` y el viewer es el Carrier. Selector de estrellas + textarea opcional + botón submit.

## Related

- **Depende de**: [[REQ-BE-00042]] (US20 — crea tabla `reviews` y modelo).
- **Construye sobre**: [[REQ-BE-00038]] (Shipment llega a `delivered`).
- **Extiende**: [[REQ-FE-00024]] (US39 — detalle de envío).
- **Continuación**: [[REQ-BE-00045]] (US54 — visualizar reseñas del Expedidor).
- **Simétrico a**: [[REQ-BE-00042]] (US20 — Shipper crea reseña del Carrier).
- **Backlog**: `docs/artifacts/backlog-us/US030.typ`.

## Implementation notes

- **Branch**: `feature/REQ-BE-00044-us30-crear-resena-expedidor`.
- **PR title**: `feat(reviews): US30 — Carrier creates Shipper review (fullstack)`.
- **Assignee**: `@bcespedes`.
- **Pre-PR gate**: `just lint`, `just frontend-test-coverage`, `just frontend-test-e2e`, `just backend-test`.
- **Impeccable**: `/critique`, `/polish`, `/audit` sobre el formulario antes de abrir el PR.
