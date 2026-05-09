---
tag: REQ-BE-00015
title: Reseñas — enforcement de "una reseña por viaje completado"
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/95
author: Claude Code
github_issue: 95
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCOA
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:24:24.737959+00:00Z
labels:
- REQ
- BE
- reviews
- post-mvp
- us20
---

## Summary

Asegurar que un cliente solo puede dejar **una** reseña por viaje completado. Tercera y última rebanada de US20. Pequeña pero crítica para evitar abuso.

## Problem Statement

US20 AC: "un cliente solo puede dejar una reseña por viaje completado". Sin esta regla, un mismo Shipper puede inflar/deflar artificialmente el rating de un Carrier desde un único viaje.

## Expected Behavior

- Constraint a nivel DB: `unique index on (shipment_id, shipper_id)` en la tabla `reviews`.
- Validación a nivel modelo: `validates :shipper_id, uniqueness: { scope: :shipment_id }`.
- Endpoint `POST /api/shipments/:id/review` retorna `409 Conflict` con mensaje claro si ya existe una reseña.
- UI: el form de reseña está deshabilitado / oculto si la reseña ya existe (en su lugar, mostrar la reseña existente con CTA "Editar" — link al issue de US26).

## Technical Notes

- **Race condition**: la unique index protege contra creates concurrentes. La validación AR es solo para mejor UX en el error.
- **Mensaje de error**: `{ error: { code: "review_already_exists", message: "...", details: { review_id } } }` (consistente con la convención recomendada en el HLD).

## Related

- US fuente: US20.
- Padres: `REQ-BE-00013`, `REQ-BE-00014`.

## Acceptance Criteria

- [ ] Migración agrega `unique index (shipment_id, shipper_id)`.
- [ ] Validación AR + manejo de `RecordNotUnique` con 409.
- [ ] UI deshabilita el form si ya existe una reseña.
- [ ] Test cubre el caso de doble post (segunda llamada → 409).
