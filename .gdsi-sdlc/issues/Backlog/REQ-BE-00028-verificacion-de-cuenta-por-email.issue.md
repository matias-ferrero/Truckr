---
tag: REQ-BE-00028
title: Verificación de cuenta por email (token + reenvío + UI badge)
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/108
author: Claude Code
github_issue: 108
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCnI
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:27:00.849069+00:00Z
labels:
- REQ
- BE
- FE
- auth
- post-mvp
- us22
---

## Summary

Tras registrarse o cambiar de email, enviar al usuario un mail con un link de verificación. Al clickearlo, marcar la cuenta como verificada. Permite reenvío si el link expira. UI distingue cuentas verificadas. Cubre US22 fullstack.

## Problem Statement

US22 AC: email tras registro, click marca verificada, expira tras N horas, reenvío disponible, distinción visual en UI.

## Expected Behavior

### Backend
- Modelo `User` ya tiene `email_verified` (de `REQ-BE-00020`) + columnas `email_verification_token`, `email_verification_sent_at`.
- Tras `register` o cambio de email, generar token, persistir, enviar mail con link `/verificar-email?token=...`.
- `POST /api/auth/verify_email` — body `{ token }`. Si válido y no expirado (TTL 24h), set `email_verified: true`, limpia token.
- `POST /api/auth/resend_verification` — solo para usuarios logueados sin verificar; rate limit 1 por minuto.
- Job `EmailVerificationCleanupJob` nocturno limpia tokens expirados.

### Frontend
- Pantalla `/verificar-email?token=...` que dispara la verificación al montar; muestra success o error.
- Banner persistente en cabecera para usuarios no verificados con CTA "Reenviar email".
- Badge / icono en perfil que distingue cuenta verificada.
- En el detalle del carrier (`REQ-FE-00014`), badge visible para clientes que evalúan al transportista.

## Related

- US fuente: US22.
- Padres: `REQ-BE-00023` (auth), `INF-BE-00005` (mailer), `REQ-BE-00020` (User model con campos verificación).

## Acceptance Criteria

- [ ] Endpoints de verify + resend con request specs (válido, expirado, ya verificado, mismatch).
- [ ] Mail enviado tras register y tras cambio de email.
- [ ] Banner + badge en frontend.
- [ ] Job de cleanup nocturno.
- [ ] E2E: register → recibir email (letter_opener) → click link → cuenta verificada.
