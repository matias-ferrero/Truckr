---
tag: REQ-BE-00029
title: Editar y eliminar reseña (mantiene unicidad por viaje, recalcula promedio)
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/109
author: Claude Code
github_issue: 109
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCpU
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:27:12.684655+00:00Z
labels:
- REQ
- BE
- FE
- reviews
- post-mvp
- us26
---

## Summary

Permitir al cliente editar o eliminar una reseña previamente creada. Al editar, marca como modificada; al eliminar, recalcula el promedio del transportista; pide confirmación antes de eliminar. Cubre US26 fullstack.

## Problem Statement

US26 AC: cliente puede editar texto y rating; eliminar disponible; visual "editada" tras modificación; recalcular promedio al eliminar; confirmación antes de eliminar.

## Expected Behavior

### Backend
- `PATCH /api/reviews/:id` — solo el shipper autor puede editar. Permite cambiar `rating` y `body`. Set `edited_at` en cada update.
- `DELETE /api/reviews/:id` — solo el autor; recalcula `Carrier.rating_avg` y `reviews_count` (consistente con `REQ-BE-00014`).
- Edición/eliminación no afecta la regla "1 por viaje" (`REQ-BE-00015`): si el shipper elimina, puede crear una nueva sobre el mismo shipment.

### Frontend
- En el listado de reseñas del propio shipper (parte de `REQ-FE-00020` historial), cada reseña tiene "Editar" y "Eliminar".
- Editar abre el form pre-poblado.
- Eliminar pide confirmación con modal.
- Reseñas editadas muestran indicador "(editada)".

## Related

- US fuente: US26.
- Padres: `REQ-BE-00013` (review create), `REQ-BE-00014` (avg recompute), `REQ-BE-00015` (1-per-trip).

## Acceptance Criteria

- [ ] `PATCH` y `DELETE /api/reviews/:id` con request specs (autor + no-autor).
- [ ] Recálculo de `rating_avg` y `reviews_count` tras delete.
- [ ] Indicador "(editada)" en el frontend.
- [ ] Confirmación antes de eliminar.
- [ ] E2E: crear reseña, editar, ver indicador, eliminar, ver promedio actualizado.
