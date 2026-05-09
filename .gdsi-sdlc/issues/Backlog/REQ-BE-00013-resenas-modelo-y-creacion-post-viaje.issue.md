---
tag: REQ-BE-00013
title: Reseñas — modelo + creación de reseña post-viaje
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/93
author: Claude Code
github_issue: 93
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCJo
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:24:01.261860+00:00Z
labels:
- REQ
- BE
- reviews
- post-mvp
- us20
---

## Summary

Permitir al cliente (`Shipper`) escribir una reseña sobre un transportista (`Carrier`) una vez completado un viaje. Primera rebanada de US20: modelo + creación. Visualización + average rating viven en `REQ-BE-00014`. La regla "1 reseña por viaje" se aísla en `REQ-BE-00015`.

## Problem Statement

US20 ("Reseñas") junta: crear, listar, mostrar promedio, una por viaje, edición/eliminación. Tratado como un solo bloque, las decisiones (¿dónde se muestran las reseñas? ¿qué pasa si el carrier las disputa? ¿se ocultan reseñas con palabras prohibidas?) se mezclan. Esta rebanada se ocupa solo de la **mecánica de creación**.

## Expected Behavior

- Modelo `Review`: `shipper_id`, `carrier_id`, `shipment_id` (FK), `rating` (integer 1-5), `body` (text, opcional), timestamps.
- Endpoint `POST /api/shipments/:id/review` que crea la reseña. Solo el `Shipper` dueño del shipment puede crearla, y solo si el shipment está `delivered`.
- UI: pantalla `/shipments/:id/review` con form (rating con estrellas + comentario opcional). Disparada por una notificación post-entrega.

## Technical Notes

- **Validaciones**: `rating` entero 1..5; `body.length <= 1000`.
- **Tiempo**: por ahora cualquier shipment delivered puede ser reseñado. Documentar para futuro: cap a N días post-entrega.
- **Naming**: `Review`, `reviews`. Columnas en inglés.
- **No moderación**: contenido se persiste tal cual; moderación queda como decisión diferida.

## Related

- US fuente: US20.
- Hermanos: `REQ-BE-00014` (display + average), `REQ-BE-00015` (1-per-trip enforcement).
- Dependiente: `REQ-BE-00005` (modelos `Shipment`/`Shipper`/`Carrier`).

## Acceptance Criteria

- [ ] Modelo `Review` con migración.
- [ ] `POST /api/shipments/:id/review` con autorización (solo el Shipper, solo shipment delivered).
- [ ] Pantalla con form de rating + comentario.
- [ ] Validaciones implementadas y testeadas.
- [ ] Identifiers en inglés.
