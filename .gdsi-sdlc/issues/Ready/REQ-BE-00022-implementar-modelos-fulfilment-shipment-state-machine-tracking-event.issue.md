---
tag: REQ-BE-00022
title: Implementar contexto Fulfilment — Shipment (state machine), TrackingEvent,
  Route
priority: P0
status: ready
plan: docs/features/REQ/REQ-BE-00022/REQ-BE-00022-implementar-contexto-fulfilment.plan.md
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/102
author: Claude Code
github_issue: 102
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCbY
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:25:49.628304+00:00Z
labels:
- REQ
- BE
- domain-model
- fulfilment
- foundation
---

## Summary

Implementar los modelos de **Fulfilment**: `Shipment` con su state machine completa, `TrackingEvent` (eventos auditables de cada transición y de updates de GPS), y `Route` (ruta calculada para un shipment). Sin esto, los flujos de retiro/entrega/tracking/payment no tienen un objeto sobre el cual operar.

## Problem Statement

`Shipment` es el corazón operativo del sistema: nace cuando un `Quote` se paga y vive hasta que se entrega y se settlea el pago. Su state machine (`draft → quoted → accepted → in_transit → delivered → settled` + branch `cancelled`) es invariante para US18 (mark picked-up), US19 (mark delivered), US21 (tracking), US15 (payout), US20 (review post-trip), US25 (insurance claims).

`TrackingEvent` es el log auditable de cada transición y de cada GPS update — necesario tanto para tracking en vivo (US21) como para reconstrucción post-mortem.

## Expected Behavior

- Migraciones para: `shipments`, `tracking_events`, `routes`.
- `Shipment`: `quote_id` (FK, unique), `status` (string), `picked_up_at`, `delivered_at`, `settled_at`, `cancelled_at`, `cancellation_reason`, timestamps.
- State machine documentada en `app/models/shipment.rb`:
  - Estados: `draft`, `quoted`, `accepted`, `in_transit`, `delivered`, `settled`, `cancelled`.
  - Transiciones permitidas y guards (a mano por ahora — sin gem; documentar la decisión).
  - Cada transición emite un `TrackingEvent`.
- `TrackingEvent`: `shipment_id` (FK), `kind` (`status_change`, `gps_update`, `note`), `from_status`, `to_status` (nullable para no-status events), `lat`, `lng` (nullable, para GPS updates), `metadata` (JSON), `recorded_at`.
- `Route`: `shipment_id` (FK), `polyline` (text — encoded polyline de Google Maps), `distance_m` (integer), `duration_s` (integer), `provider` (string, e.g. `google_maps_directions`), `calculated_at`. Nullable hasta que se calcule.
- Validaciones: transiciones de `Shipment.status` validadas (no permitir `delivered → in_transit`, etc.).
- Scopes: `Shipment.active`, `Shipment.completed`, `Shipment.in_progress`, `TrackingEvent.gps`, `TrackingEvent.recent(n)`.
- ActiveAdmin expone los tres modelos read-only con vista del tracking log inline en `Shipment`.
- Factories + seeds (un Shipment por estado para demos).
- Model specs cubren la state machine completa: cada transición permitida y al menos un caso de transición no permitida (debe levantar excepción / devolver false).

## Technical Notes

- **State machine sin gem**: usar un método `transition_to!(new_status)` en `Shipment` que valide contra una constante `ALLOWED_TRANSITIONS = { draft: [:quoted], quoted: [:accepted, :cancelled], ... }`. Agregar `with_lock` para race safety.
- **Side effects**: cada transición debería disparar un `TrackingEvent`. Mantenerlo en el método de transición, no en callbacks (más predecible para tests).
- **`settled` trigger**: la transición a `settled` la dispara `REQ-BE-00011` (carrier payout) y opcionalmente `REQ-BE-00018` (insurance contracting). Este issue solo deja la transición permitida; quien la invoca son issues posteriores.
- **GPS updates**: el endpoint `POST /api/trips/:id/locations` (consumido por `REQ-FE-00010`) crea `TrackingEvent` con `kind: gps_update`. El endpoint en sí lo crea uno de los issues de tracking; este issue solo asegura que el modelo lo admite.

## Related

- Padres: `REQ-BE-00005`, `REQ-BE-00020`, `REQ-BE-00021`.
- Bloquea: US18, US19, US21, REQ-BE-00006/7/11, REQ-FE-00010, todos los flujos de tracking/payment/review/insurance que dependen del Shipment.

## Acceptance Criteria

- [ ] Migraciones aplicadas para `shipments`, `tracking_events`, `routes`.
- [ ] `Shipment.transition_to!` con validación de transiciones permitidas + lock + emisión de `TrackingEvent`.
- [ ] State machine documentada en el modelo (constante `ALLOWED_TRANSITIONS` + comentario con diagrama).
- [ ] ActiveAdmin muestra `Shipment` con su tracking log.
- [ ] Factories + seeds.
- [ ] Specs cubren todas las transiciones permitidas + ≥1 transición rechazada.
- [ ] Identifiers en inglés.
