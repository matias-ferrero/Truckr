---
tag: REQ-BE-00007
title: Flujo de pago del expedidor al aceptar la oferta (post-aceptación del transportista)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/83
author: Claude Code
github_issue: 83
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrs6sg
github_repo: tcorzo/fiuba-gestion-tp
labels:
- BE
- FE
- REQ
- payments
- mvp
- us8
- checkout
- cargo-offer
---

## Summary

Cablear el flujo de pago de US8: cuando el transportista acepta una `CargoOffer` (US12), notificar al expedidor y permitirle pagar la reserva vía Mercado Pago. Cubre disparador, redirect al checkout, retorno (success/failure/pending) y actualización del estado del `Payment` asociado y del `Shipment` derivado.

## Problem Statement

Una vez que existe la integración con MP (`REQ-BE-00006`), falta orquestar **cuándo** el expedidor paga, **cómo** se le notifica que su `CargoOffer` fue aceptada por el transportista, y **qué** pasa en el dominio cuando el pago se confirma, se rechaza o nunca llega.

US8 dice "una vez que el transportista aceptó mi viaje". No hay especificado un timeout de pago, retry, ni qué pasa si el expedidor no paga en N horas — este issue define esas reglas.

Nota de modelo (locked 2026-05-19): tras el rename, **no existe una entidad `Quote` separada de `CargoOffer`**. La `CargoOffer` (bid del transportista sobre un `Cargo`) es la única FSM que sostiene el estado del flujo de pago. El `Payment` cuelga de la `CargoOffer` vía `payments.cargo_offer_id`.

## Expected Behavior

- Cuando una `CargoOffer` pasa a `accepted` (US12 — ver `REQ-BE-00024`), el sistema dispara una notificación al expedidor (email + in-app si aplica) con un link para pagar.
- Pantalla `/cargo-offers/:id/pay` (frontend) verifica el estado de la `CargoOffer`, dispara `POST /api/cargo-offers/:id/payments`, y redirige al `init_point` de MP.
- En MP, `Payment.external_reference = CargoOffer.id` (string).
- Tras el retorno desde MP (success_url / failure_url / pending_url):
  - **success**: muestra confirmación; `Payment.status` → `approved`; la `CargoOffer` permanece en `accepted` (el pago no la mueve de estado, solo desbloquea el contrato); se crea el `Shipment` derivado (`status: accepted` o equivalente per `REQ-BE-00005`).
  - **failure**: muestra error con CTA para reintentar; `Payment.status` → `rejected`; la `CargoOffer` sigue `accepted` y se vuelve a habilitar el botón de pago hasta el timeout.
  - **pending**: muestra "procesando"; `Payment.status` queda en `pending`; el webhook (`REQ-BE-00006`) eventualmente lo reconcilia.
- Timeout de pago: si el expedidor no paga en `N` horas (default 24h, configurable) tras la aceptación, el job `CargoOfferPaymentTimeoutJob` ejecuta — **en una sola DB transaction** — la cascada de expiración: `Payment.status → expired` (con `payments.expired_at` timestamp) **y** `CargoOffer.status → expired`. Ambas filas transicionan a `expired`. Además libera la reserva del transportista y revierte el `TransportWindow` asociado de `reserved` → disponible (coordinar con `REQ-BE-00024`).
- Email transaccional con link de pago (template básico, ActionMailer + Solid Queue).

## Technical Notes

- **State machine — `CargoOffer.status`** (única FSM del flujo de pago, post-rename, locked 2026-05-19 a 4 valores): `pending | accepted | rejected | expired`. Transiciones: `pending → accepted` (US12), `pending → rejected` (rechazo explícito del Carrier), `pending → expired` (TTL 48h de `INF-BE-00006`, inacción del Carrier), `accepted → expired` (timeout de pago de este issue, inacción del Shipper post-aceptación). **No existe un 5to estado `payment_expired`** — ambos caminos de expiración colapsan en el mismo valor `expired`; la traceabilidad pre-aceptación vs post-aceptación se distingue por `payments.expired_at` + telemetría/event-type, no por enum. El éxito del pago **no** introduce un nuevo estado `paid` en `CargoOffer`; vive en `Payment.status` (`pending → approved | rejected | expired`).
- **Dos TTLs distintos — mismo enum value, distinto path de auditoría:**
  - `CargoOfferExpirationJob` (`INF-BE-00006`): TTL de **48h** sobre `CargoOffer.status = pending` (oferta del transportista sin respuesta del expedidor) → mueve a `expired`. No tiene nada que ver con pagos; `Payment` no existe todavía en este path.
  - `CargoOfferPaymentTimeoutJob` (este issue): TTL de **24h por default** sobre `CargoOffer.status = accepted` cuyo `Payment` asociado no llegó a `approved`. En una sola tx setea `Payment.status = expired` (sellando `payments.expired_at`) **y** `CargoOffer.status = expired`, y libera el `TransportWindow`. La presencia/ausencia de `Payment` + `payments.expired_at` permite distinguir auditoría post-aceptación vs pre-aceptación sin un 5to enum value.
- **`Cargo.status`**: queda en `open / accepted / cancelled` (sin `offered`). El `Cargo` ya transicionó a `accepted` en US12, antes de este flujo. El pago **no** toca el `Cargo`.
- **`TransportWindow`**: ya quedó `reserved` por US12. El pago exitoso **no** mueve la Window. El timeout de pago **sí** la revierte.
- **Mailer**: ActionMailer en dev con `letter_opener` o similar; el proveedor de email en prod es decisión diferida (no está en el roadmap).
- **Race conditions**: dos requests intentando confirmar el mismo `Payment` (webhook + retorno del usuario). Usar `CargoOffer.with_lock { ... }` al actualizar `Payment.status` y derivar el `Shipment` para evitar doble creación.
- **FKs**: `payments.cargo_offer_id` (FK a `cargo_offers.id`), `shipments.cargo_offer_id` (FK a `cargo_offers.id`).
- **Job paths**: `app/jobs/cargo_offer_payment_timeout_job.rb` (este issue), `app/jobs/cargo_offer_expiration_job.rb` (`INF-BE-00006`, separado).

## Acceptance Criteria

- [ ] Notificación al expedidor cuando la `CargoOffer` pasa a `accepted` (email + in-app si aplica).
- [ ] Pantalla `/cargo-offers/:id/pay` (frontend) verifica estado y redirige a MP correctamente.
- [ ] Retorno success / failure / pending manejado en frontend con UX clara.
- [ ] `Payment.status` se actualiza atómicamente al confirmarse el pago, dentro de `CargoOffer.with_lock`.
- [ ] `Payment.external_reference == CargoOffer.id` verificado en la creación de la preferencia y en el webhook.
- [ ] `CargoOfferPaymentTimeoutJob` programado y testeado (timeout default 24h, configurable); al disparar, en una sola DB transaction setea `Payment.status = expired` (con `payments.expired_at`) **y** `CargoOffer.status = expired`, y revierte `TransportWindow` de `reserved` a disponible. Spec verifica que ambas filas transicionan atómicamente.
- [ ] **`CargoOffer.status` enum permanece en 4 valores** (`pending | accepted | rejected | expired`) — no se introduce `payment_expired`. Spec verifica que el timeout post-aceptación produce `CargoOffer.status == 'expired'` distinguible del path 48h vía `payments.expired_at` y/o event-type emitido.
- [ ] **Separación explícita** entre `CargoOfferExpirationJob` (48h sobre `pending`, propiedad de `INF-BE-00006`) y `CargoOfferPaymentTimeoutJob` (24h sobre `accepted` sin pago) — tests cubren que cada job solo toca `CargoOffer`s en el estado correcto, y que la auditoría los puede separar (presencia de `Payment` + `payments.expired_at` vs ausencia de `Payment`).
- [ ] Email transaccional con link `/cargo-offers/:id/pay` enviado vía Solid Queue.
- [ ] Tests: feature spec del happy path (`accepted` → MP success → `Payment.approved` + `Shipment` creado) + spec del timeout de pago + spec de que el éxito de pago no toca `Cargo.status` ni `TransportWindow`.
- [ ] State machine de `CargoOffer` documentada (mínimo en código + comentario en el modelo, link a `domain-model.md § 8`).

## Related

- US fuente: US8.
- Upstream (dispara este flujo): `REQ-BE-00024` (US12, aceptación del transportista — transición `pending → accepted` y reserva del `TransportWindow`).
- Integración MP: `REQ-BE-00006` (cliente MP, preferencias, webhook).
- TTL hermano (distinto job, distinto SLA): `INF-BE-00006` (`CargoOfferExpirationJob`, 48h sobre `pending`).
- Post-pago: `REQ-BE-00008` (revelación de contacto del transportista tras `Payment.approved`).
- Modelo: `REQ-BE-00005` (Shipment derivado de la `CargoOffer` aprobada).

## Rename memo

Body refreshed 2026-05-19 — Quote→CargoOffer rename. The two-entity model (CargoOffer + Quote) collapsed into one. `QuotePaymentTimeoutJob` renamed to `CargoOfferPaymentTimeoutJob`. Source of truth: `docs/05-appendices/glossary.md`, `domain-model.md` § 3 + § 8.
