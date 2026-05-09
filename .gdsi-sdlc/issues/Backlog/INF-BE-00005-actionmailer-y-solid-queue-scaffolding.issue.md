---
tag: INF-BE-00005
title: ActionMailer + Solid Queue — scaffolding de emails transaccionales
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/88
author: Claude Code
github_issue: 88
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtB3s
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-09T13:35:40.075943+00:00Z
labels:
- INF
- BE
- foundation
- mailer
---

## Summary

Configurar ActionMailer + Solid Queue para enviar emails transaccionales desde el backend. Establecer la base + un mailer template para que features posteriores (auth welcome, notificaciones de pago, payouts fallidos, reseñas, claims, etc.) tengan un esqueleto donde colgarse.

## Problem Statement

Múltiples issues mencionan "se notifica por email" como AC: auth welcome (`REQ-BE-00023`), notificación al cliente cuando se acepta una oferta (`REQ-BE-00007`), payout fallido al carrier (`REQ-BE-00012`), reseñas, claims, etc. Sin scaffolding de mailer, cada uno va a inventar su propio adapter.

## Expected Behavior

- Configuración de ActionMailer en `config/environments/{development,test,production}.rb`:
  - **dev**: `letter_opener_web` (emails se previsualizan en `/letter_opener` mounted en routes).
  - **test**: in-memory delivery (no `letter_opener`).
  - **prod**: SMTP configurable por ENV (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM`). Si las vars no están seteadas, prod usa `letter_opener` también para que dev-deploys no rompan; documentado.
- `ApplicationMailer` con `default from: ENV.fetch("MAIL_FROM", "no-reply@truckr.local")`, layouts y helpers compartidos.
- Mailer ejemplo: `WelcomeMailer#welcome` con template HTML + texto plano (placeholder, lo usa `REQ-BE-00023`).
- Job wrapper: usar `deliver_later` con Solid Queue (default ya en Rails 8).
- Layouts: `app/views/layouts/mailer.{html,text}.erb` con header/footer mínimo de Truckr.
- I18n: templates leen de `config/locales/mailer.{es,en}.yml`.
- Specs: mailer specs (`WelcomeMailer.welcome(user).body` contiene los datos esperados) + un job spec que verifica `deliver_later` agrega al queue.
- README en `docs/05-appendices/mailer.md`: cómo agregar un nuevo mailer, dónde se previsualizan los emails en dev.

## Technical Notes

- **letter_opener_web**: gem `letter_opener_web`, mount en `routes.rb` solo en dev. No hay riesgo en test/prod.
- **No proveedor real todavía**: SMTP es la baseline; cambiar a SendGrid/Postmark/etc. queda como decisión diferida con su ADR.
- **From-address**: `MAIL_FROM` por ENV; default a `no-reply@truckr.local` en dev/test.
- **Bounce handling**: out of scope para MVP.

## Related

- Bloquea: `REQ-BE-00023` (welcome), `REQ-BE-00007` (notify on offer accept), `REQ-BE-00012` (payout fail), `REQ-BE-00018` (insurance policy email), `REQ-BE-00019` (claim status).

## Acceptance Criteria

- [ ] ActionMailer configurado en los tres environments.
- [ ] `letter_opener_web` mounted en dev.
- [ ] `ApplicationMailer` + layout HTML/text.
- [ ] `WelcomeMailer` ejemplo + spec.
- [ ] I18n locales para mailer.
- [ ] README en `docs/05-appendices/mailer.md`.
- [ ] `deliver_later` ruteado por Solid Queue (verificar en spec).
- [ ] Identifiers en inglés.
