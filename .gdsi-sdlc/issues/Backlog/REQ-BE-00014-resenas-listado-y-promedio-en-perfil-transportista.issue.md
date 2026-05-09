---
tag: REQ-BE-00014
title: Reseñas — listado y promedio de puntuación en perfil del transportista
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/94
author: Claude Code
github_issue: 94
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCL4
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:24:13.392398+00:00Z
labels:
- REQ
- BE
- FE
- reviews
- post-mvp
- us20
---

## Summary

Mostrar las reseñas de un transportista en su perfil (US6 / Detalle de Transportista) y el promedio de puntuación. Segunda rebanada de US20.

## Problem Statement

Una reseña sin display es ruido. US20 prescribe "las reseñas son visibles en su perfil" + "se muestra el promedio de puntuación". El cálculo del average y su persistencia (¿columna desnormalizada en `Carrier`? ¿query on-the-fly?) son una decisión.

## Expected Behavior

- Endpoint `GET /api/carriers/:id/reviews?page=1` con paginación (default 10/page, ordenadas por `created_at desc`).
- `Carrier` expone `rating_avg` (decimal 2,1) y `reviews_count` (integer) en `GET /api/carriers/:id` (para evitar query extra al renderizar el listado de búsqueda).
- Estos campos se actualizan automáticamente al crear una reseña (callback `after_commit` o counter cache estilo Rails).
- UI: en el perfil del carrier (US6), sección "Reseñas" con cards (autor anonimizado, rating, fecha, texto) + average destacado en el header del perfil.
- En el listado de búsqueda (US4), la card del carrier muestra el rating como estrellas + count.

## Technical Notes

- **Recompute on write**: `after_commit` en `Review#create` y `Review#destroy` (anticipando US26 — eliminación) recalcula. Para volúmenes MVP es OK; si crece, async via Solid Queue.
- **Decimal vs float**: usar `decimal(3,2)` para `rating_avg` (rango 0.00..5.00).
- **Counter cache**: alternativa más simple: usar `counter_cache: true` para `reviews_count` y un callback explícito para `rating_avg`.

## Related

- US fuente: US20.
- Padre: `REQ-BE-00013`.
- Hermano: `REQ-BE-00015`.
- Consumidor: US6 (Detalles de transportista — futuro), US4 (búsqueda — `REQ-FE-00006`).

## Acceptance Criteria

- [ ] `Carrier` tiene `rating_avg` y `reviews_count` actualizados en write.
- [ ] `GET /api/carriers/:id/reviews` con paginación.
- [ ] Card de reseña en UI del perfil + average en header.
- [ ] Estrellas + count en card de búsqueda.
- [ ] Test que verifica que crear una reseña actualiza `rating_avg` y `reviews_count`.
