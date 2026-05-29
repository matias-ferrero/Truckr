---
tag: REQ-BE-00042
title: US20 — Crear Reseña de Transportista (Shipper→Carrier, fullstack)
priority: P2
status: backlog
created: '2026-05-29'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/281
author: Claude Code
github_issue: 281
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
- us20
- fulfilment
---

## Summary

El Expedidor puede escribir una reseña sobre un Transportista una vez que el envío se completó. Incluye rating de 1 a 5 estrellas y comentario de texto opcional. Un Expedidor solo puede dejar una reseña por envío completado. Issue fullstack: migración + modelo `Review` + endpoint de creación + formulario en la pantalla de detalle de envío (US39).

El modelo `Review` es compartido con US26 ([[REQ-BE-00043]]), US30 ([[REQ-BE-00044]]) y US54 ([[REQ-BE-00045]]). Este issue crea la migración y el modelo base; los demás lo consumen.

## User story (fuente)

`docs/artifacts/backlog-us/US020.typ`:

> **US20 — Crear Reseña de Transportista.** Como expedidor, quiero poder escribir reseñas sobre los transportistas, para compartir mi experiencia.

## Acceptance Criteria

- [ ] **AC1** — Un expedidor puede escribir una reseña sobre un transportista una vez que el envío se completó.
- [ ] **AC2** — La reseña incluye una puntuación (1 a 5 estrellas) y un comentario de texto (opcional, max 1000 chars).
- [ ] **AC3** — Un expedidor solo puede dejar una reseña por envío completado (`409` si ya existe).
- [ ] **AC4** — Solo el Shipper propietario del Shipment puede crear la reseña. Otros usuarios → `403`.
- [ ] **AC5** — Solo se puede crear la reseña si el Shipment está en estado `delivered`. Sino → `409`.
- [ ] **AC6** — Todas las claves de error pasan por `I18n.t(...)`. Cero literales en controllers.
- [ ] **AC7** — FE muestra el formulario de reseña en la pantalla de detalle del envío ([[REQ-FE-00024]]) solo cuando `state == 'delivered'` y el viewer es el Shipper. Tras submit exitoso el formulario se deshabilita y muestra la reseña creada.
- [ ] **AC8** — RSpec cubre: happy-path, guard de estado (`409`), guard de unicidad (`409`), guard de autorización (`403`). SimpleCov no baja del baseline.

## API contract

### `POST /api/shipments/:id/reviews`

- **Authz**: `ReviewPolicy#create?` — `current_shipper.present? && current_shipper.id == shipment.shipper_id`.
- **Guards**: `shipment.state_delivered?` → `409` (`errors.reviews.create.shipment_not_delivered`). `Review.shipper_authored.exists?(shipment_id: shipment.id)` → `409` (`errors.reviews.create.already_reviewed`).
- **Body**: `{ "rating": integer 1-5, "body": string|null }`.
- **Side effect**: `Review.create!(shipment:, shipper: current_shipper, carrier: shipment.carrier, rating:, body:, authored_by: :shipper_authored)`.
- **Response**: `201 Created` con `ReviewResource`.
- **Errors**: `403`, `404`, `409`, `422` (validaciones).

## Domain model

### Migración — tabla `reviews` (nueva, compartida con [[REQ-BE-00043]], [[REQ-BE-00044]], [[REQ-BE-00045]])

| Column | Type | Null | Notes |
|---|---|---|---|
| `shipment_id` | `bigint` | no | FK `shipments.id` |
| `shipper_id` | `bigint` | no | FK `shippers.id` |
| `carrier_id` | `bigint` | no | FK `carriers.id` |
| `rating` | `integer` | no | 1-5 |
| `body` | `text` | yes | max 1000 chars |
| `authored_by` | `string` | no | enum: `'shipper'` \| `'carrier'` |

Índices: `unique (shipment_id, authored_by)`, `index (carrier_id, authored_by)`, `index (shipper_id, authored_by)`.

## Frontend scope

Agregar sección "Dejar reseña" en `/shipments/:id` ([[REQ-FE-00024]]): visible solo cuando `state === 'delivered'` y el viewer es el Shipper. Selector de estrellas + textarea opcional + botón submit.

## Related

- **Construye sobre**: [[REQ-BE-00038]] (Shipment llega a `delivered`).
- **Extiende**: [[REQ-FE-00024]] (US39 — detalle de envío).
- **Continuación**: [[REQ-BE-00043]] (US26), [[REQ-BE-00044]] (US30), [[REQ-BE-00045]] (US54).
- **Backlog**: `docs/artifacts/backlog-us/US020.typ`.

## Implementation notes

- **Branch**: `feature/REQ-BE-00042-us20-crear-resena-transportista`.
- **PR title**: `feat(reviews): US20 — Shipper creates Carrier review (fullstack)`.
- **Assignee**: `@LucasDondo`.
- **Pre-PR gate**: `just lint`, `just frontend-test-coverage`, `just frontend-test-e2e`, `just backend-test`.
- **Impeccable**: `/critique`, `/polish`, `/audit` sobre el formulario antes de abrir el PR.
