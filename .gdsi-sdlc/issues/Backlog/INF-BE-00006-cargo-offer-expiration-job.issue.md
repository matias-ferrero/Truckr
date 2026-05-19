---
tag: INF-BE-00006
title: CargoOfferExpirationJob — auto-expira `pending` a las 48 h y flipea Window a `open` (mismo tx)
priority: P1
status: backlog
created: '2026-05-19'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/200
author: Claude Code
github_issue: 200
github_repo: tcorzo/fiuba-gestion-tp
labels:
- INF
- BE
- marketplace
- mvp
- us7
---

## Summary

ActiveJob que, 48 horas después de la creación de una `CargoOffer` con status `pending`, marca la oferta como `expired` y revierte la `TransportWindow` destino de `pending_offer` a `open` en la misma transacción. Cubre la mitad asíncrona del comportamiento Window-locks-on-Offer (el flip síncrono `open → pending_offer` en `POST /api/cargos/:cargo_id/offers` queda con `REQ-FE-00015` / `REF-BE-00002`).

## Problem Statement / Current Behavior

`REQ-FE-00015` AC original incluía dos comportamientos del lock de Window:

1. **Síncrono** (en creación): `Window.open → pending_offer` en la misma DB tx que crear el `CargoOffer`.
2. **Asíncrono** (en timeout): si el Carrier no responde en 48h, el `CargoOffer` pasa a `expired` y la Window vuelve a `open`.

El segundo comportamiento requiere un job programado (ActiveJob + scheduler) que no encaja en el alcance del wizard de creación. Vale la pena tratarlo como issue separado para no inflar PR #193 ni demorar US7 mientras se diseña el scheduler.

> **Importante**: este issue es el complemento del flip síncrono. Ambos deben coexistir antes de poder cerrar formalmente la AC "Window-locks-on-Offer" de US7.

## Expected Behavior

### Backend

- **Job**: `CargoOfferExpirationJob`. Recibe un `cargo_offer_id`. Idempotente: re-encolarlo después de que ya expiró debe ser un no-op.
- **Scheduling**: al crear un `CargoOffer` con status `pending`, encolar el job con `wait: 48.hours` (o `wait_until: cargo_offer.created_at + 48.hours` para resiliencia ante retries).
- **Transición**: dentro de un `ActiveRecord::Base.transaction`:
  - Re-cargar el `CargoOffer` con lock (`lock!`) — si su status ya no es `pending`, retornar.
  - `cargo_offer.update!(status: "expired")`.
  - `transport_window.update!(status: "open")` (solo si su status es `pending_offer` y el `CargoOffer` expirado es el último que la bloqueaba).
- **Notificación**: enviar mail al Shipper ("Tu oferta expiró sin respuesta del transportista") — stub aceptable hasta `INF-BE-00005`.
- **Cancelación temprana**: si el Carrier acepta o rechaza antes de las 48h, el job debe encontrar el `CargoOffer` ya no `pending` y ser no-op. No requiere `Job#cancel` explícito.

### Concurrencia

- El backend ya garantiza (vía `REQ-FE-00015` / `REF-BE-00002`) que solo un `CargoOffer` `pending` puede existir contra una Window a la vez. Por lo tanto la transición `pending_offer → open` en el job no necesita coordinar con otros offers — basta con verificar que la Window apunta al `CargoOffer` que acaba de expirar.

### Frontend

- No hay UI nueva en este issue. La pantalla "Esperando respuesta" de US7 hace polling y eventualmente verá el status `expired` cuando el job corra.

## Technical Notes

- **Stack**: ActiveJob backed por el queue adapter actual (por ahora el default; cuando aparezca un backend real como `solid_queue` o `good_job`, este job lo hereda — no diseñar el job alrededor de un backend específico).
- **Test strategy**: `perform_now` con `ActiveSupport::Testing::TimeHelpers.travel_to` para simular la ventana de 48h; aserciones sobre status del `CargoOffer` + status de la Window + mail enviado.
- **Regression spec**: cubrir el AC "En reject del Carrier o expiración a 48h, la Window vuelve a `open` automáticamente" — incluye los dos paths (Carrier rechaza, y 48h timeout).
- **SQLite-friendly**: usar `lock!` (que en SQLite produce un `BEGIN EXCLUSIVE`) o un re-check + `update!` con guardas. No requiere PostgreSQL.
- **Window state**: lifecycle `open / pending_offer / reserved / closed`. Solo `pending_offer → open` aplica acá.

## Related

- **Blocks**: cierre formal de US7 (`REQ-FE-00015` / #121).
- **Blocked by**: `REF-BE-00002` (#197) — el rename `Quote → CargoOffer` debe aterrizar antes para que este job opere sobre el nombre canónico. (Si entra antes del rename, se puede llamar `QuoteExpirationJob` y renombrar en bloque con REF-BE-00002.)
- **Sibling**: el flip síncrono `Window.open → pending_offer` en `POST /api/cargos/:cargo_id/offers` — vive en `REQ-FE-00015` / `REF-BE-00002`, no acá.
- **Hijos**: `INF-BE-00005` (template real del mailer; este issue manda stub).

## Acceptance Criteria

- [ ] Clase `CargoOfferExpirationJob < ApplicationJob` con método `perform(cargo_offer_id)` implementada.
- [ ] `CargoOffersController#create` (o equivalente post-rename) encola el job con `set(wait_until: cargo_offer.created_at + 48.hours).perform_later(cargo_offer.id)`.
- [ ] El job, ejecutado a las 48h, marca el `CargoOffer` como `expired` **solo si** sigue `pending` (idempotente).
- [ ] El job, en la misma transacción, revierte la `TransportWindow` de `pending_offer → open` solo si seguía bloqueada por este `CargoOffer`.
- [ ] El job envía un mail al Shipper notificando expiración (stub, `INF-BE-00005`).
- [ ] Spec del job cubre: (a) happy path expiration, (b) no-op si el Carrier ya respondió, (c) Window no se toca si su status ya no es `pending_offer`.
- [ ] Regression spec compartida con `REQ-FE-00015`: "En reject del Carrier o expiración a 48h, la Window vuelve a `open` automáticamente".

## Origin

Split de `REQ-FE-00015` (#121) en review de PR #193 (2026-05-19). La AC original "En reject del Carrier o expiración a 48h, la Window vuelve a `open` automáticamente (regression spec)" se separa acá para tratar el job asíncrono como pieza independiente, dado que requiere scheduler y vive en un horizonte temporal distinto al wizard de creación.
