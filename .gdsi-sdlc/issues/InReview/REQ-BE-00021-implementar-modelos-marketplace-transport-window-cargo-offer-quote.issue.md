---
tag: REQ-BE-00021
title: Implementar contexto Marketplace — TransportWindow, CargoOffer, Quote (migraciones
  + AR)
priority: P0
status: in_review
plan: docs/features/REQ/REQ-BE-00021/REQ-BE-00021-implementar-contexto-marketplace.plan.md
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/101
author: Claude Code
github_issue: 101
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCZA
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:25:38.502656+00:00Z
labels:
- REQ
- BE
- domain-model
- marketplace
- foundation
---

## Summary

Implementar las entidades del bounded context **Marketplace** (`TransportWindow`, `CargoOffer`, `Quote`) tal como las especifica el draft de `REQ-BE-00005`. Sin estos modelos no hay matching entre `Carrier` y `Shipper`, ni publicación de disponibilidad ni ofertas de viaje.

## Problem Statement

El draft de dominio describe estas entidades a nivel conceptual, pero ningún issue las pone en código. Bloquean: US4 (búsqueda), US5 (filtrado), US6 (detalle), US7 (oferta), US9 (publicar), US10 (inbox), US11 (filtrar ofertas), US12 (aceptar), y todo el flujo de pago.

## Expected Behavior

- Migraciones para: `transport_windows`, `cargo_offers`, `quotes`.
- `TransportWindow`: `carrier_id` (FK), `origin_zone`, `destination_zone`, `price_per_km` (decimal), `max_km` (integer), `available_from`, `available_to`, `active` (boolean default true), timestamps.
- `CargoOffer`: `shipper_id` (FK), `pickup_address`, `delivery_address`, `pickup_date`, `cargo_description`, `weight_kg`, `volume_cm3`, `declared_value_cents`, timestamps. (No FK directo a `Carrier` todavía — el matching se hace por `Quote`.)
- `Quote`: `cargo_offer_id` (FK), `carrier_id` (FK), `transport_window_id` (FK), `amount_cents`, `currency` (default `ARS`), `status` (string: `pending → accepted → paid → expired/cancelled`), `expires_at`, timestamps.
- Asociaciones bidireccionales con dependent/inverse_of correctos.
- Validaciones: precios positivos, fechas coherentes (from < to), zonas presentes, `weight_kg > 0`, etc.
- Scopes útiles: `TransportWindow.active`, `TransportWindow.matching(origin:, destination:)`, `Quote.pending`, `Quote.expired`.
- ActiveAdmin expone los tres modelos en read-only.
- Factories + seeds que crean un escenario mínimo (2 windows, 2 offers, 2 quotes).
- Model specs cubren validaciones y scopes.

## Technical Notes

- **State machine de `Quote`**: la transición `pending → accepted` la dispara US12; `accepted → paid` la dispara `REQ-BE-00007`; `expired` la dispara `QuotePaymentTimeoutJob` también de `REQ-BE-00007`. Documentar las transiciones permitidas en el modelo aunque la lógica que las invoca venga después.
- **Geo**: `origin_zone`/`destination_zone` y direcciones son strings libres en Phase 0/1. La decisión de PostGIS está diferida (ADR de `REQ-BE-00005`).
- **Currency**: por ahora solo `ARS`; columna existe para no atarse.
- **Matching naive**: el scope `matching(...)` en MVP es case-insensitive substring match. Suficiente para demos.

## Related

- Padres: `REQ-BE-00005` (diseño), `REQ-BE-00020` (Identity tiene que existir antes — `Carrier` y `Shipper` son FKs).
- Bloquea: `REQ-FE-00006/7/8`, US5/6/7/9/10/11/12, todo el flujo de payment/insurance.

## Acceptance Criteria

- [ ] Migraciones aplicadas para `transport_windows`, `cargo_offers`, `quotes`.
- [ ] Modelos AR con validaciones + asociaciones + scopes documentados.
- [ ] State machine de `Quote` documentada en el modelo (constants + transition table).
- [ ] ActiveAdmin lista los tres modelos read-only.
- [ ] Factories + seeds funcionan.
- [ ] Model specs ≥80% coverage.
- [ ] Identifiers en inglés.
