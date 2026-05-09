---
tag: REQ-BE-00011
title: Payout vía Mercado Pago al transportista tras confirmación de entrega
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/90
author: Claude Code
github_issue: 90
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtB80
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:22:59.819149+00:00Z
labels:
- REQ
- BE
- payments
- payout
- mercadopago
- mvp
- us15
---

## Summary

Cuando un viaje se marca como entregado (US19), se libera el escrow y se transfiere el monto al transportista (`Carrier`) vía Mercado Pago. Primera rebanada de US15: la transferencia automática.

## Problem Statement

US15 ("Pago al transportista") incluye: integración con MP, transferencia tras entrega, vista de pagos recibidos, manejo de errores. Las dos primeras (integración + transferencia) son lo crítico que habilita el modelo de negocio; la vista del transportista y la notificación de error se aíslan en el hermano `REQ-BE-00012`.

La integración de MP al lado del cliente (`REQ-BE-00006`) ya da cuenta del pago entrante. Falta el flujo de **transfer** (split payment / payout) hacia el carrier, que en MP se modela con **Marketplace** o **Money Out** dependiendo del esquema de cuenta.

## Expected Behavior

- Cuando un `Shipment` pasa a `delivered` (US19), un job `CarrierPayoutJob` calcula el monto a transferir (precio total - comisión de la plataforma) y crea una transferencia a la cuenta MP del carrier.
- El carrier debe haber linkeado su cuenta MP previamente (`Carrier.mp_user_id`); si no, el payout queda en estado `pending_setup` y se notifica al carrier para que complete el linkeo.
- Endpoint `POST /api/carriers/me/mp_link` que recibe el OAuth callback de MP y guarda `mp_user_id` + tokens.
- El `Payment` original (entrada del cliente) queda con un `Payout` asociado (modelo nuevo o atributo) con estado (`pending`, `processed`, `failed`).
- Webhook updates: el webhook de `REQ-BE-00006` se extiende para escuchar eventos de payout (`money_release`).
- Comisión de la plataforma configurable (`PLATFORM_FEE_PCT`, default 5%).

## Technical Notes

- **Modo Marketplace de MP**: requiere ser una "Marketplace" en MP (vs solo aceptar pagos). Documentar el setup en `docs/05-appendices/payments.md`.
- **Cuentas split**: alternativa es crear pagos con `marketplace_fee` y `payer.id`, que MP divide automáticamente. Más simple que payouts manuales. **Recomendado** para MVP. Revisar si el modelo de Mercado Pago Argentina lo soporta.
- **Idempotencia**: el job no debe procesar el mismo Shipment dos veces. Lock + check de estado previo.
- **Reconciliación**: job nocturno chequea Payouts en estado `pending` por más de N horas y los marca como sospechosos.
- **Naming**: `Payout` (no `Pago`). `Carrier.mp_user_id`.

## Related

- US fuente: US15.
- Hermano: `REQ-BE-00012` (vista del transportista + notificación de error).
- Dependiente: `REQ-BE-00006` (integración MP), `REQ-BE-00005` (modelo Shipment con state machine).

## Acceptance Criteria

- [ ] Modelo `Payout` (o atributos en `Payment`) con estados.
- [ ] `Carrier.mp_user_id` + endpoint OAuth callback.
- [ ] `CarrierPayoutJob` se dispara al transitar `Shipment.delivered`, idempotente.
- [ ] Comisión de plataforma calculada y configurable.
- [ ] Webhook de payout maneja `money_release`.
- [ ] Job de reconciliación nocturno.
- [ ] Tests cubren happy path + carrier sin MP linkeado + double-fire idempotencia.
- [ ] Decisión "Marketplace mode vs split payment" registrada en `docs/05-appendices/payments.md`.
