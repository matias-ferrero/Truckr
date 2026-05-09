---
tag: REQ-BE-00006
title: Integración con Mercado Pago — checkout (cliente paga reserva)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/82
author: Claude Code
github_issue: 82
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrs6pk
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T01:41:46.628948+00:00Z
labels:
- REQ
- BE
- payments
- mercadopago
- mvp
- us8
---

## Summary

Integrar el SDK de **Mercado Pago Checkout** para habilitar el pago de la reserva de un viaje por parte del cliente (`Shipper`). Esta es la rebanada de **integración** de US8: configurar el SDK, manejar credenciales (test + prod), abrir un Preference de pago y procesar el callback de éxito/fallo. El flujo de UX (cuándo se dispara, qué se muestra al confirmar) y la lógica de revelación de contacto post-pago viven en issues hermanos.

## Problem Statement

US8 ("Realizar Pago") junta tres preocupaciones distintas:
1. **Integración con un proveedor de pagos externo** (Mercado Pago) — credenciales, SDK, webhooks, idempotencia.
2. **Flujo de checkout** — cuándo se inicia (al confirmar oferta), cómo se redirige al gateway, cómo se maneja el retorno.
3. **Reserva instantánea + revelación de contacto** — efectos del pago confirmado (qué se le muestra al cliente luego de pagar, qué datos se exponen).

Tratado como una sola pieza, cualquier issue se vuelve inestimable y se contamina entre temas (cambios de SDK afectan al UI; cambios al UI afectan al estado del Payment, etc). Este issue se ocupa **solo** del primero: dejar instalado y operativo el SDK + un endpoint que cree Preferences + un endpoint webhook que recibe notificaciones de MP.

## Expected Behavior

- Gem `mercadopago-sdk` (o equivalente oficial) instalada y configurada en `backend/`.
- Credenciales en variables de entorno: `MP_ACCESS_TOKEN_TEST`, `MP_ACCESS_TOKEN_PROD`. El controller selecciona según `Rails.env`.
- Modelo `Payment` (definido por `REQ-BE-00005`) guarda `mp_preference_id`, `mp_payment_id`, `status` (`pending`, `approved`, `rejected`, `refunded`), `external_reference` (= `Quote.id`).
- Endpoint `POST /api/payments` que toma un `quote_id`, crea una `Preference` en MP, devuelve `{ init_point: <url>, preference_id }` para que el frontend redirija al checkout MP.
- Endpoint webhook `POST /api/webhooks/mercadopago` que recibe notificaciones de pago, valida origen (firma o IP), actualiza `Payment.status`. Idempotente.
- Logging tagged: `Rails.logger.tagged("mp")`.
- Job de fallback `MercadoPagoReconcileJob` (cada hora) que consulta el estado de Payments `pending` para casos donde el webhook se perdió.

## Technical Notes

- **Sandbox first**: usar credenciales de test exclusivamente hasta que haya una decisión de despliegue. Documentar en `docs/05-appendices/` cómo correr el sandbox local.
- **Webhook seguridad**: MP firma los webhooks; validar la firma (`x-signature` header) para evitar spoofing. Documentar el secreto en `MP_WEBHOOK_SECRET`.
- **Idempotencia**: dos llamadas al webhook con el mismo `data.id` no deben crear pagos duplicados; usar `find_or_create_by(mp_payment_id: ...)`.
- **Solid Queue**: el job de reconciliación va por solid_queue (regla del proyecto: jobs en `backend/app/jobs/` heredan de `ApplicationJob`).
- **No tocar UI todavía**: este issue es BE-only. El issue `REQ-BE-00007` agrega el flujo de checkout consumido desde el frontend.

## Related

- US fuente: US8 (cliente) y US15 (transportista). Este issue habilita la pieza compartida (integración SDK).
- Issue dependiente: `REQ-BE-00005` (modelo de dominio define `Payment`).
- Issues hermanos: `REQ-BE-00007` (flujo de checkout sobre offer-accept), `REQ-BE-00008` (revelar contacto post-pago).
- Issue gemelo: `REQ-BE-00011` (payout al transportista — usa la misma integración pero el flujo opuesto).

## Acceptance Criteria

- [ ] SDK de Mercado Pago instalado, gem en `Gemfile`, configurado vía `Rails.application.credentials` o ENV.
- [ ] Modelo `Payment` con migración aplicada (columnas mínimas: `quote_id`, `mp_preference_id`, `mp_payment_id`, `status`, `amount`, `currency`, `external_reference`, timestamps).
- [ ] `POST /api/payments` crea Preference y devuelve `init_point` + `preference_id`.
- [ ] `POST /api/webhooks/mercadopago` valida firma, actualiza `Payment.status`, es idempotente.
- [ ] `MercadoPagoReconcileJob` programado y testeado.
- [ ] README de la integración en `docs/05-appendices/payments.md` (cómo configurar sandbox, cómo testear).
- [ ] Tests: request specs para `POST /api/payments` y `POST /api/webhooks/mercadopago`; job spec con MP API mockeada.
- [ ] Log tags: cada operación contra MP queda con `tagged("mp")`.
- [ ] Identifiers en inglés (`Payment`, `mp_preference_id`).
