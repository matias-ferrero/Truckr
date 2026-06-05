---
tag: REQ-FE-00031
title: Notificación en tiempo real al Transportista cuando un Expedidor le envía una oferta de carga
priority: P2
status: in_review
plan: docs/features/REQ/REQ-FE-00031/REQ-FE-00031-carrier-offer-received-notification.plan.md
created: '2026-06-02'
source: manual
source_url: 'https://github.com/tcorzo/fiuba-gestion-tp/issues/306'
author: Claude Code
github_issue: 306
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgujssI
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-06-03T02:42:37.183813+00:00Z
labels:
- REQ
- FE
- BE
- notifications
- marketplace
- carrier
---

## Summary

Consumer de negocio del framework de notificaciones en tiempo real ([[INF-FE-00005]]) y **simétrico inverso** de [[REQ-FE-00030]]. Cuando un **Expedidor (Shipper)** crea una **oferta de carga (`CargoOffer`)** contra una `TransportWindow` de un **Transportista (Carrier)**, el Carrier debe recibir una **notificación in-app en tiempo real** (toast + badge) avisándole que tiene una oferta nueva para resolver (aceptar/rechazar).

Trabajo fullstack acotado: registrar un tipo nuevo en el whitelist del backend, llamar a `Notifications::Publisher.publish` en el punto donde hoy se encola `notify_carrier`, y agregar el renderer + copy en el frontend. **No** introduce lógica de dominio nueva — la creación de la oferta, el window-lock y la transición de la `TransportWindow` a `pending_offer` ya existen y están testeados.

## Problem Statement

Hoy, cuando un Shipper le envía una oferta a un Carrier, el Carrier no tiene feedback inmediato en la app. El único canal previsto es `CargoOfferMailer.notify_carrier`, que **es un stub** (`backend/app/mailers/cargo_offer_mailer.rb:9-17`, marcado "INF-BE-00005 pending") — loguea y manda un placeholder, sin email real. Es decir: el Carrier hoy efectivamente **no se entera** salvo que entre a su bandeja `/api/carriers/me/cargo-offers?status=pending` y refresque. La notificación en tiempo real sería, en la práctica, el **primer aviso real** que recibe el Carrier de una oferta nueva.

El framework de [[INF-FE-00005]] dejó el transporte (Action Cable + Solid Cable), el contrato del publisher y los primitivos de UI (toast, badge) listos y probados end-to-end con un único tipo `:ping`. El plan de ese issue lista "**oferta recibida**, pago confirmado, cambio de estado de envío, payout liberado, reseña recibida" como consumers reales en issues separados. Éste cubre "oferta recibida" (lado Carrier); [[REQ-FE-00030]] cubre la resolución (lado Shipper).

### Dirección del dominio (recordatorio)

Igual que en [[REQ-FE-00030]], a pesar de comentarios desactualizados en `cargo_offer.rb`:

- **El Shipper crea la `CargoOffer`** — `CargoOfferPolicy#create? = user&.shipper.present?`; controller `Api::CargoOffersController#create` con `require_shipper!` (`backend/app/controllers/api/cargo_offers_controller.rb:18,30`). El body lleva `cargo_id` + `transport_window_id` (US7 / REQ-FE-00015, remediado por REQ-BE-00032 §2.7).
- **El Carrier es el destinatario** de esta notificación — es el dueño de la `TransportWindow` ofertada. Luego él acepta/rechaza (eso dispara [[REQ-FE-00030]] hacia el Shipper).

## Expected Behavior

### Disparador (backend)

Emitir la notificación al Carrier en `Api::CargoOffersController#create`, en el mismo punto donde hoy se encola el mailer (`cargo_offers_controller.rb:54`, `CargoOfferMailer.notify_carrier(cargo_offer).deliver_later`), **después** de que la transacción que crea la oferta haya commiteado.

Destinatario = `cargo_offer.carrier.user.id` (la `CargoOffer` `belongs_to :carrier`; el mailer ya resuelve `cargo_offer.carrier.user.email`). Usar `Notifications::Publisher.publish(user_id:, type:, payload:)`.

### Tipo nuevo (whitelist cerrado)

Registrar en `Notifications::Type` (`backend/app/services/notifications/type.rb`):

- `CARGO_OFFER_RECEIVED = :cargo_offer_received`

y agregarlo a `ALL`. Espejar en el union de tipos del frontend (`notificationsRegistry.ts`).

### Payload

JSON mínimo, en inglés snake_case, suficiente para el toast y un deep-link futuro a la bandeja del Carrier:

```json
{
  "cargo_offer_id": 123,
  "cargo_id": 45,
  "transport_window_id": 9,
  "amount_cents": 1500000,
  "currency": "ARS"
}
```

El renderer no debe romper si un campo opcional falta (ver harden). No incluir datos personales del Shipper en el payload más allá de lo necesario para el aviso.

### Comportamiento (frontend)

- Registrar el renderer para `cargo_offer_received` en `frontend/src/components/notifications/notificationsRegistry.ts`, devolviendo `{ title, body }` desde el bundle i18n.
- Agregar el copy a `frontend/src/landingContent.ts` bajo `notifications` (carve-out de CLAUDE.md). Sin literales en JSX.
- El toast aparece vía el `NotificationsProvider`/`NotificationsToast` ya existentes — **no** se modifica la UI de chrome, sólo se agrega el tipo + copy.
- Tipo desconocido sigue siendo ignorado por `isKnownNotificationType()`.

### Entrega best-effort (no persistencia)

Por ADR-013 / [[INF-FE-00005]], best-effort live delivery: si el Carrier no tiene sesión/WebSocket abierto, no la recibe — el canal durable es el email (hoy stub, a cablear en INF-BE-00005). **No** agregar tabla de notificaciones ni historial persistente en este issue.

## Current Behavior

`notify_carrier` es un stub que loguea y manda un placeholder; no hay aviso real ni in-app ni por email. El Carrier sólo descubre ofertas nuevas entrando manualmente a su bandeja de ofertas pendientes.

## Reproduction Steps

1. El Carrier publica una `TransportWindow` y deja la app abierta.
2. Un Shipper publica una carga y crea una `CargoOffer` contra esa ventana (`POST /api/cargo_offers`).
3. **Hoy:** el Carrier no ve nada; sólo un log de placeholder en el servidor.
4. **Esperado:** el Carrier ve un toast inmediato + badge incrementado, y puede ir a su bandeja a aceptar/rechazar.

## Impact

Transportistas que esperan ofertas. Cierra el primer tramo del flujo central del marketplace (Shipper oferta → Carrier se entera → Carrier resuelve → [[REQ-FE-00030]] avisa al Shipper). Riesgo bajo: se apoya en infra ya probada y no altera la creación de la oferta (la emisión va fuera de la transacción).

## Technical Notes

**Backend**
- Publisher: `Notifications::Publisher.publish(user_id:, type:, payload:)` (`backend/app/services/notifications/publisher.rb`). Lanza `Notifications::UnknownTypeError` si el tipo no está registrado → registrar el tipo primero.
- Emitir **después del commit** de la transacción de creación (la transacción toma `window.lock!`); no meter I/O de broadcast dentro del lock. El mailer ya se llama post-transacción en la línea 54 — emitir la notificación en el mismo punto.
- El controller envuelve el mailer en `.deliver_later`; mantener el mismo espíritu best-effort para la notificación: un fallo de broadcast no debe romper el 201 de creación de la oferta.
- Resolver `cargo_offer.carrier.user_id` sin N+1 (la `TransportWindow` ya viene con `includes(vehicle: :carrier)`; sumar la asociación `user` si hace falta).

**Frontend**
- Union de tipos: extender `NotificationType` en `notificationsRegistry.ts`.
- Copy en `landingContent.ts` → `notifications.cargo_offer_received` con `{ title, body }`.
- Sin cambios en `NotificationsProvider`/`Toast`/`Badge` salvo que el registry consuma el tipo.

**Lenguaje / política**
- Tipos, payload keys y rutas en inglés; copy de UI en español vía bundle i18n. Sin literales españoles en JSX ni en código.

**DB / infra**
- Nada nuevo. SQLite, sin tablas, sin persistencia de notificaciones (ADR-013). Solid Cable ya configurado sobre la DB primaria.

**Coordinación**
- Comparte exactamente el mismo patrón de cambios que [[REQ-FE-00030]] (registrar tipo en `Type`, renderer en `notificationsRegistry`, copy en `landingContent`). Si ambos issues se implementan en paralelo, coordinar el orden de PRs para evitar conflictos triviales en esos tres archivos; el segundo rebasa.

## Origin
<!-- No linkeado a inbox. Entrada manual del PM derivada del task "show notification when carrier receives offers from shippers". -->

## Related

- **Framework base (dependencia dura):** [[INF-FE-00005]] — transporte, publisher, primitivos de UI.
- **Hermano simétrico:** [[REQ-FE-00030]] (resolución de la oferta → aviso al Shipper). Juntos cubren el ciclo de vida oferta↔resolución en tiempo real.
- **Dominio Marketplace:** [[REQ-BE-00021]] (modelos), creación de oferta ya implementada en `Api::CargoOffersController#create`.
- **Hermanos futuros (otros consumers del framework):** pago confirmado, cambio de estado de envío, payout liberado, reseña recibida — issues separados.
- **Email durable (dependencia blanda):** INF-BE-00005 cableará el email real de `notify_carrier`; este issue no lo bloquea ni lo reemplaza.
- **Código relevante:**
  - `backend/app/controllers/api/cargo_offers_controller.rb:54` (disparador create).
  - `backend/app/services/notifications/type.rb` (registrar tipo).
  - `backend/app/services/notifications/publisher.rb` (entry point).
  - `backend/app/mailers/cargo_offer_mailer.rb:9-17` (referencia: dónde se encola hoy el aviso, stub).
  - `frontend/src/components/notifications/notificationsRegistry.ts` (renderer + union de tipos).
  - `frontend/src/landingContent.ts` (copy i18n).
- **Política:** [`CLAUDE.md`](../../../CLAUDE.md).

## Notas de implementación para el assignee

- **Branch:** parte de `feature/INF-FE-00005-notifications-framework` hasta que el framework mergee a `main`; luego rebasea sobre `main`.
- **PR title format** — prefijo conventional obligatorio (`feat(notifications): ...`), sin bracket `[REQ-FE-00031]`. Referenciar el TAG en el body y el branch.
- **`gh pr create --assignee @me`.**
- **No tocar `.gdsi-sdlc/config.json`.**
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit` sobre los cambios de toast/copy. Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`, y `just backend-test` (toca backend).

## Acceptance Criteria

- [ ] **AC1** — `Notifications::Type` registra `cargo_offer_received` en `ALL`; el frontend lo espeja en su union de tipos.
- [ ] **AC2** — Al crear una oferta (`POST /api/cargo_offers`), el Carrier dueño de la `TransportWindow` ofertada recibe una notificación `cargo_offer_received` en tiempo real (toast + badge).
- [ ] **AC3** — El payload incluye al menos `cargo_offer_id`, `cargo_id`, `transport_window_id`, `amount_cents`, `currency`. Keys en inglés snake_case.
- [ ] **AC4** — La emisión ocurre fuera de la transacción/lock de creación (no extiende el `window.lock!` con I/O de broadcast).
- [ ] **AC5** — Un fallo del broadcast no impide la creación de la oferta (el endpoint sigue devolviendo 201).
- [ ] **AC6** — Toda la copy de UI vía bundle i18n (`landingContent.ts`); sin literales españoles en JSX ni en código. Tipos/payload/rutas en inglés.
- [ ] **AC7** — Un tipo desconocido sigue siendo ignorado silenciosamente por el frontend (sin regresión del framework).
- [ ] **AC8** — Sin persistencia de notificaciones ni tablas nuevas (best-effort, ADR-013). Portable a SQLite.

### Tests requeridos

- [ ] RSpec — `Api::CargoOffersController#create` publica `cargo_offer_received` al `user_id` del Carrier dueño de la ventana (spy del Publisher).
- [ ] RSpec — la oferta se crea (201) aun si el Publisher levanta (no-regresión; broadcast best-effort).
- [ ] RSpec — publicar un tipo no registrado levanta `Notifications::UnknownTypeError` (guarda del whitelist) — si no está ya cubierto por [[REQ-FE-00030]].
- [ ] Vitest — el registry renderiza `{ title, body }` correctos para `cargo_offer_received` desde el bundle i18n.
- [ ] Vitest — payload con campo opcional faltante no rompe el renderer.
- [ ] Playwright e2e — golden path: Carrier con sesión abierta; un Shipper crea una oferta contra su ventana; aparece el toast de "oferta recibida". (Si el e2e no puede orquestar dos roles, disparar el broadcast del tipo real vía endpoint dev/seed.)
