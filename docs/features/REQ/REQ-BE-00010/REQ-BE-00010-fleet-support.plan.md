# REQ-BE-00010: Soporte multi-vehículo (flota) por transportista — STUB

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00010 |
| **Title** | Soporte multi-vehículo (flota) por transportista |
| **Priority** | P3 |
| **Status** | READY |
| **Created** | 2026-05-10 |
| **Author** | Claude Code |

---

## Plan consolidado

Esta plan está **consolidada** con `REQ-BE-00009`. Ambos issues se entregan en un solo PR (`feat/vehicle-fleet-crud`) con migraciones squashed para evitar el churn de agregar y luego remover el `unique index on carrier_id`.

Ver el plan completo: [`REQ-BE-00009-and-00010-vehicle-fleet.plan.md`](../REQ-BE-00009/REQ-BE-00009-and-00010-vehicle-fleet.plan.md).

### Tareas que cubre este issue (resumen)

- Endpoints `GET/DELETE /api/carriers/me/vehicles[/:id]` (CRUD multi-vehículo).
- Pantalla `/transportista/vehiculos` con add/edit/delete y empty state.
- Componente reusable `<VehicleSelect/>` (autocompleta cuando N=1).
- Endpoint público `GET /api/carriers/:id/vehicles` (consumido luego por US6/REQ-FE-00014).
- Tests E2E del happy path multi-vehículo (crear segundo vehículo, list, delete).

### Decisiones clave que justifican el merge

1. La columna `transport_windows.vehicle_id` **ya existe** desde la migración inicial — no requiere migration nueva.
2. El `unique index on carrier_id` que pedía 00009 **nunca se aplica**. Documentado en el plan conjunto, §2.2 Decisión A.

### Acceptance criteria

Ver §6 del plan conjunto. Los items marcados `[B]` son los que cierran este issue.
