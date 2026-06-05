---
tag: REQ-FE-00030
title: Notificación en tiempo real al Expedidor cuando el Transportista acepta o rechaza su oferta de carga
priority: P2
status: in_review
plan: docs/features/REQ/REQ-FE-00030/REQ-FE-00030-shipper-offer-resolution-notifications.plan.md
created: '2026-06-02'
source: manual
source_url: 'https://github.com/tcorzo/fiuba-gestion-tp/issues/304'
author: Claude Code
github_issue: 304
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgujPJU
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-06-03T00:30:53.387834+00:00Z
labels:
- REQ
- FE
- BE
- notifications
- marketplace
- shipper
---

## Summary

Primer consumer de negocio del framework de notificaciones en tiempo real ([[INF-FE-00005]]). Cuando un **Transportista (Carrier)** acepta o rechaza la **oferta de carga (`CargoOffer`)** que un **Expedidor (Shipper)** le envió, el Expedidor debe recibir una **notificación in-app en tiempo real** (toast + badge), además del email que ya se envía hoy. Cubre tanto el rechazo explícito (`POST /api/carriers/me/cargo-offers/:id/reject`) como la aceptación (`POST .../:id/accept`) y el **auto-rechazo en cascada** de las ofertas hermanas `pending` de la misma `Cargo` cuando una es aceptada.

Es trabajo fullstack acotado: registrar dos tipos nuevos en el whitelist del backend, llamar a `Notifications::Publisher.publish` en los puntos donde hoy se encola el mailer, y agregar los renderers + copy en el frontend. **No** introduce lógica de dominio nueva — el accept/reject y sus transiciones de estado ya existen y están testeados.

## Problem Statement

Hoy, cuando el Carrier resuelve una oferta, el Shipper sólo se entera por **email diferido** (`CargoOfferMailer.notify_shipper_offer_accepted` / `notify_shipper_offer_rejected`, `deliver_later`). Si el Shipper está con la sesión abierta esperando respuesta, no hay feedback inmediato en la app: tiene que refrescar o salir a su correo. El framework de [[INF-FE-00005]] dejó el transporte (Action Cable + Solid Cable), el contrato del publisher y los primitivos de UI (toast, badge) listos y probados end-to-end con un único tipo de prueba `:ping`. El plan de ese issue lista explícitamente "oferta…, pago confirmado, cambio de estado de envío, payout liberado, reseña recibida" como **consumers reales a entregar en issues separados** (sprints 4+). Éste es el primero de esa lista.

### Aclaración de dirección del dominio (importante)

A pesar de comentarios desactualizados en el modelo (`cargo_offer.rb` header dice "Carrier's bid" y la línea ~24 dice "shipper accepts"), la implementación real es la inversa y coincide con el título de este issue:

- **El Shipper crea la `CargoOffer`** — `CargoOfferPolicy#create? = user&.shipper.present?` (`backend/app/policies/cargo_offer_policy.rb`). El Shipper ofrece su carga contra una `TransportWindow` del Carrier.
- **El Carrier acepta/rechaza** — `accept? = reject? = owner_carrier?`; rutas bajo `carriers/me/cargo-offers/:id/{accept,reject}` (`config/routes.rb:59-62`), controller con `require_carrier!`.
- **El Shipper es el destinatario** de la notificación (es quien hizo la oferta).

> Nota de cleanup (no bloqueante): los comentarios de `cargo_offer.rb` están desincronizados con la policy. Señalarlos en el próximo barrido de docs/código; no corregir en este PR salvo que sea trivial.

## Expected Behavior

### Disparadores (backend)

Emitir una notificación al Shipper destinatario en **cada** uno de estos puntos, en el mismo lugar donde hoy se encola el mailer:

1. **Aceptación** — `Marketplace::CargoOfferAcceptanceService#enqueue_notifications` (`backend/app/services/marketplace/cargo_offer_acceptance_service.rb:72-80`):
   - Tipo `cargo_offer_accepted` al Shipper de la oferta aceptada.
   - Tipo `cargo_offer_rejected` al Shipper de **cada** oferta hermana auto-rechazada (`rejected_siblings`). Ojo: las hermanas pueden pertenecer a **otros** Shippers — cada uno recibe su propia notificación, dirigida a su `user_id`.
2. **Rechazo explícito** — `Api::Carriers::Me::CargoOffersController#reject` (`backend/app/controllers/api/carriers/me/cargo_offers_controller.rb:53`):
   - Tipo `cargo_offer_rejected` al Shipper de la oferta rechazada.

Destinatario = `cargo_offer.cargo.shipper.user.id`. Usar `Notifications::Publisher.publish(user_id:, type:, payload:)`.

### Tipos nuevos (whitelist cerrado)

Registrar en `Notifications::Type` (`backend/app/services/notifications/type.rb`):

- `CARGO_OFFER_ACCEPTED = :cargo_offer_accepted`
- `CARGO_OFFER_REJECTED = :cargo_offer_rejected`

y agregarlos a `ALL`. Espejar el union de tipos en el frontend (`notificationsRegistry.ts`).

### Payload

JSON mínimo, en inglés snake_case, suficiente para renderizar el toast y (opcionalmente) linkear:

```json
{
  "cargo_offer_id": 123,
  "cargo_id": 45,
  "amount_cents": 1500000,
  "currency": "ARS"
}
```

Para `cargo_offer_accepted`, incluir además `"shipment_id"` si está disponible (la aceptación crea un `Shipment`) para permitir un deep-link futuro al detalle del envío. El renderer no debe romper si un campo opcional falta (ver harden).

### Comportamiento (frontend)

- Registrar renderers para `cargo_offer_accepted` y `cargo_offer_rejected` en `frontend/src/components/notifications/notificationsRegistry.ts`, devolviendo `{ title, body }` desde el bundle i18n.
- Agregar el copy a `frontend/src/landingContent.ts` bajo `notifications` (carve-out de CLAUDE.md: es el bundle i18n stopgap). Sin literales en JSX.
- El toast aparece vía el `NotificationsProvider`/`NotificationsToast` ya existentes — **no** se modifica la UI de chrome, sólo se agregan tipos+copy.
- Tipo desconocido sigue siendo ignorado por `isKnownNotificationType()` (comportamiento ya provisto por el framework).

### Entrega best-effort (no persistencia)

Por ADR-013 / [[INF-FE-00005]], las notificaciones son **best-effort live delivery**: si el Shipper no tiene sesión/WebSocket abierto en ese momento, no las recibe — y eso está bien, el email sigue siendo el canal durable. **No** agregar tabla de notificaciones ni historial persistente en este issue.

## Current Behavior

Sólo se envía email diferido al Shipper (`deliver_later`). No hay feedback in-app en tiempo real. El framework de tiempo real existe y funciona pero sólo conoce el tipo de prueba `:ping`.

## Reproduction Steps

1. Shipper A publica una carga y crea una `CargoOffer` contra la `TransportWindow` de un Carrier.
2. Shipper A deja la app abierta.
3. El Carrier hace `POST /api/carriers/me/cargo-offers/:id/accept` (o `/reject`).
4. **Hoy:** Shipper A no ve nada en la app; sólo le llega un email.
5. **Esperado:** Shipper A ve un toast inmediato + badge incrementado.

## Impact

Expedidores que esperan respuesta del Transportista. Mejora el feedback inmediato del flujo central del marketplace (oferta → resolución) sin depender del correo. Riesgo bajo: el email durable permanece como fallback, y la feature se apoya en infra ya probada.

## Technical Notes

**Backend**
- Publisher: `Notifications::Publisher.publish(user_id:, type:, payload:)` (`backend/app/services/notifications/publisher.rb`). Lanza `Notifications::UnknownTypeError` si el tipo no está en el whitelist → registrar los tipos primero.
- Emitir **fuera** del `with_lock`/dentro del bloque de notificaciones, junto al mailer, para no extender la transacción ni el lock con I/O de broadcast. En `accept` el patrón actual ya separa `enqueue_notifications` post-transición; en `reject` el mailer se encola dentro de la `transaction` pero después del bloque `with_lock` — emitir la notificación en el mismo punto que el mailer.
- Cascada: iterar `rejected_siblings` y publicar `cargo_offer_rejected` por cada hermana efectivamente `rejected` (mismo `next unless sibling.status == "rejected"` que el mailer).
- Cargar la asociación del Shipper para evitar N+1 al resolver `cargo.shipper.user_id` (las hermanas ya vienen con `includes(:transport_window)`; sumar `cargo: { shipper: :user }` si hace falta).

**Frontend**
- Union de tipos: extender `NotificationType` en `notificationsRegistry.ts` (hoy `"ping"`).
- Copy en `landingContent.ts` → `notifications.cargo_offer_accepted` / `notifications.cargo_offer_rejected` con `{ title, body }`.
- Sin cambios en `NotificationsProvider`/`Toast`/`Badge` salvo que el registry los consuma.

**Lenguaje / política**
- Tipos, payload keys y rutas en inglés; copy de UI en español vía bundle i18n. Sin literales españoles en JSX ni en código.
- Mensajes de error / subjects backend vía `I18n.t`. Gap conocido a tener en cuenta: `es.yml` no tiene los subjects `notify_shipper_offer_accepted/rejected` que sí están en `en.yml` — si se toca el área de copy, completar la traducción (no es estrictamente parte de este issue pero es barata de cerrar).

**DB / infra**
- Nada nuevo. SQLite, sin tablas, sin persistencia de notificaciones (ADR-013). Solid Cable ya configurado sobre la DB primaria.

## Origin
<!-- No linkeado a inbox. Entrada manual del PM derivada del task "show notification when shipper's cargo offer is accepted or rejected by the carrier". -->

## Related

- **Framework base (dependencia dura):** [[INF-FE-00005]] — transporte, publisher, primitivos de UI. Este issue es su primer consumer real. Debe estar mergeado (o este branch rebasea sobre él).
- **Dominio Marketplace:** [[REQ-BE-00021]] (modelos `CargoOffer`/`TransportWindow`), accept/reject ya implementados.
- **Hermanos futuros (otros consumers del framework):** pago confirmado, cambio de estado de envío, payout liberado, reseña recibida — issues separados.
- **Código relevante:**
  - `backend/app/services/notifications/type.rb` (registrar tipos).
  - `backend/app/services/notifications/publisher.rb` (entry point).
  - `backend/app/services/marketplace/cargo_offer_acceptance_service.rb` (disparador accept + cascada).
  - `backend/app/controllers/api/carriers/me/cargo_offers_controller.rb` (disparador reject).
  - `backend/app/mailers/cargo_offer_mailer.rb` (referencia: dónde se encola hoy el email).
  - `frontend/src/components/notifications/notificationsRegistry.ts` (renderers + union de tipos).
  - `frontend/src/landingContent.ts` (copy i18n).
- **Política:** [`CLAUDE.md`](../../../CLAUDE.md).

## Notas de implementación para el assignee

- **Branch:** parte de `feature/INF-FE-00005-notifications-framework` hasta que el framework mergee a `main`; luego rebasea sobre `main`.
- **PR title format** — prefijo conventional obligatorio (`feat(notifications): ...`), sin bracket `[REQ-FE-00030]`. Referenciar el TAG en el body y el branch.
- **`gh pr create --assignee @me`.**
- **No tocar `.gdsi-sdlc/config.json`.**
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit` sobre los cambios de toast/copy. Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`, y `just backend-test` (toca backend).

## Acceptance Criteria

- [ ] **AC1** — `Notifications::Type` registra `cargo_offer_accepted` y `cargo_offer_rejected` en `ALL`; el frontend espeja ambos en su union de tipos.
- [ ] **AC2** — Al aceptar una oferta (`POST .../accept`), el Shipper de la oferta aceptada recibe una notificación `cargo_offer_accepted` en tiempo real (toast + badge).
- [ ] **AC3** — Al rechazar explícitamente una oferta (`POST .../reject`), el Shipper de esa oferta recibe `cargo_offer_rejected`.
- [ ] **AC4** — Al aceptar una oferta, cada Shipper dueño de una oferta hermana auto-rechazada recibe `cargo_offer_rejected` dirigido a su propio `user_id` (cascada). No se notifica a hermanas que no terminaron en `rejected`.
- [ ] **AC5** — El payload incluye al menos `cargo_offer_id`, `cargo_id`, `amount_cents`, `currency` (y `shipment_id` en el caso `accepted` cuando exista). Keys en inglés snake_case.
- [ ] **AC6** — El email diferido existente (`deliver_later`) se sigue enviando sin cambios — la notificación in-app es aditiva, no reemplaza el canal durable.
- [ ] **AC7** — La emisión de la notificación ocurre fuera del `with_lock` (no extiende la transacción/lock con I/O de broadcast).
- [ ] **AC8** — Toda la copy de UI vía bundle i18n (`landingContent.ts`); sin literales españoles en JSX ni en código. Tipos/payload/rutas en inglés.
- [ ] **AC9** — Un tipo desconocido sigue siendo ignorado silenciosamente por el frontend (sin regresión del framework).
- [ ] **AC10** — Sin persistencia de notificaciones ni tablas nuevas (best-effort, ADR-013). Portable a SQLite.

### Tests requeridos

- [ ] RSpec — `CargoOfferAcceptanceService` publica `cargo_offer_accepted` al Shipper aceptado (mock/spy del Publisher).
- [ ] RSpec — `CargoOfferAcceptanceService` publica `cargo_offer_rejected` por cada hermana auto-rechazada, al `user_id` correcto (incluyendo caso multi-Shipper).
- [ ] RSpec — `CargoOffersController#reject` publica `cargo_offer_rejected` al Shipper de la oferta.
- [ ] RSpec — el email (`deliver_later`) se sigue encolando junto a la notificación (no-regresión).
- [ ] RSpec — publicar un tipo no registrado levanta `Notifications::UnknownTypeError` (guarda del whitelist).
- [ ] Vitest — el registry renderiza `{ title, body }` correctos para `cargo_offer_accepted` y `cargo_offer_rejected` desde el bundle i18n.
- [ ] Vitest — payload con campo opcional faltante (`shipment_id`) no rompe el renderer.
- [ ] Playwright e2e — golden path: Shipper con sesión abierta; el Carrier acepta su oferta; aparece el toast de aceptación. (Si el e2e no puede orquestar dos roles, usar el endpoint dev/seed para disparar el broadcast del tipo real.)
