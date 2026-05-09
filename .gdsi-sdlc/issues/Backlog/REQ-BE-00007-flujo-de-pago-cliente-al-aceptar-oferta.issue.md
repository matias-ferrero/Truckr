---
tag: REQ-BE-00007
title: Flujo de pago del cliente al aceptar la oferta (post-aceptación del transportista)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/83
author: Claude Code
github_issue: 83
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrs6sg
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-09T13:35:40.077277+00:00Z
labels:
- BE
- FE
- REQ
- payments
- mvp
- us8
- checkout
---

## Summary

Cablear el flujo de pago de US8: cuando el transportista acepta una oferta (US12), notificar al cliente y permitirle pagar la reserva via Mercado Pago. Cubre disparador, redirect al checkout, retorno (success/failure/pending) y actualización del estado del `Quote` / `Shipment`.

## Problem Statement

Una vez que existe la integración con MP (`REQ-BE-00006`), falta orquestar **cuándo** el cliente paga, **cómo** se le notifica que su oferta fue aceptada, y **qué** pasa en el dominio cuando el pago se confirma o se rechaza.

US8 menciona "una vez que el transportista aceptó mi viaje". No hay especificado un timeout, retry, ni qué pasa si el cliente no paga en N horas — este issue debe definir estas reglas.

## Expected Behavior

- Cuando un `Quote` pasa a `accepted` (US12), el sistema dispara una notificación al cliente (email + in-app si aplica) con un link para pagar.
- Pantalla `/quotes/:id/pay` (frontend) que verifica el estado del Quote, dispara `POST /api/payments`, redirige al `init_point` de MP.
- Tras el retorno desde MP (success_url / failure_url / pending_url):
  - **success**: muestra confirmación, `Quote.status` → `paid`, `Shipment` se crea (`status: accepted` o equivalente per state machine de `REQ-BE-00005`).
  - **failure**: muestra error con CTA para reintentar.
  - **pending**: muestra "procesando", invita a chequear más tarde; el webhook (en `REQ-BE-00006`) eventualmente actualiza el estado.
- Timeout: si el cliente no paga en `N` horas (default 24h, configurable), `Quote.status` → `expired` y se libera la reserva del transportista (job `QuotePaymentTimeoutJob`).
- Email transaccional con link de pago (template básico, ActionMailer + Solid Queue para envío).

## Technical Notes

- **Estados**: este issue forza una decisión sobre la state machine de `Quote` (al menos: `pending → accepted → paid → expired/cancelled`). Coordinar con `REQ-BE-00005`.
- **Mailer**: ActionMailer en modo dev usa `letter_opener` o similar; en prod queda como decisión diferida (proveedor de email no está definido en el roadmap).
- **Race conditions**: dos clientes pagando el mismo Quote (no debería pasar pero lock para defenderse). Usar `with_lock` en el Quote al actualizar.

## Related

- US fuente: US8.
- Issue dependiente: `REQ-BE-00006` (integración MP), `REQ-BE-00005` (modelo Quote/Shipment con state machine).
- Hermano: `REQ-BE-00008` (revelación de contacto post-pago).

## Acceptance Criteria

- [ ] Notificación al cliente cuando el `Quote` pasa a `accepted`.
- [ ] Pantalla `/quotes/:id/pay` redirige a MP correctamente.
- [ ] Retorno success/failure/pending manejado en frontend con UX clara.
- [ ] `Quote.status` se actualiza atómicamente al confirmarse el pago.
- [ ] `QuotePaymentTimeoutJob` programado y testeado (timeout default 24h).
- [ ] Email de notificación se envía vía Solid Queue.
- [ ] Tests: feature spec del happy path + spec del timeout.
- [ ] State machine de `Quote` documentada (mínimo en código + comentario en el modelo).
