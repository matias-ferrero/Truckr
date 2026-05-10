---
tag: REQ-BE-00010
title: Soporte multi-vehículo (flota) por transportista
priority: P3
status: in_review
pr_url: https://github.com/tcorzo/fiuba-gestion-tp/pull/144
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/89
author: Claude Code
github_issue: 89
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtB60
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-09T13:35:40.079177+00:00Z
plan: docs/features/REQ/REQ-BE-00010/REQ-BE-00010-fleet-support.plan.md
labels:
- BE
- FE
- REQ
- mvp
- vehicle
- us14
- fleet
---

## Summary

Permitir que un transportista (`Carrier`) registre **más de un** vehículo. Levanta la restricción 1:1 impuesta por `REQ-BE-00009`. Última rebanada de US14.

## Problem Statement

US14 menciona como AC: "se puede registrar más de un vehículo si el transportista tiene una flota". Implementarlo agrega afordances de UI (listar, agregar, eliminar) y de dominio (¿qué vehículo se asocia a una `TransportWindow` específica? ¿el carrier elige al publicar?). Aislar esta complejidad evita inflar `REQ-BE-00009`.

## Expected Behavior

- Eliminar el `unique index on carrier_id` de `vehicles` y reemplazarlo por un index normal.
- Endpoints `POST /api/carriers/me/vehicles`, `GET /api/carriers/me/vehicles`, `DELETE /api/carriers/me/vehicles/:id`.
- Pantalla `/transportista/vehiculos` (listado) con CTA "Agregar vehículo".
- Cuando el carrier publica una `TransportWindow`, elige a qué vehículo aplica (FK `vehicle_id` en `transport_windows`).
- Si solo hay un vehículo, el dropdown se autocompleta (no rompe el flujo de un único vehículo).
- En el detalle del carrier (US6), se muestra una galería con todos los vehículos.

## Technical Notes

- **Migración**: drop unique index, agregar `vehicle_id` a `transport_windows` (nullable hasta backfill, luego NOT NULL).
- **Backfill**: si ya hay `transport_windows` cuando se aplica la migración, hay que asignar el único vehículo del carrier. Documentar el script de backfill.
- **UX**: el caso multi-vehículo es minoritario en MVP. Priorizar que el caso 1-vehículo no degrade.

## Related

- US fuente: US14.
- Padre: `REQ-BE-00009`.

## Acceptance Criteria

- [ ] Migración elimina constraint 1:1 y agrega `vehicle_id` a `transport_windows`.
- [ ] Endpoints CRUD de vehículos funcionan con N > 1.
- [ ] Pantalla de listado + agregar + eliminar.
- [ ] Selector de vehículo al crear `TransportWindow`.
- [ ] Caso 1-vehículo sin regresión.
- [ ] Detalle del carrier muestra todos los vehículos.
- [ ] Tests cubren creación de un segundo vehículo y la asignación a una window.
