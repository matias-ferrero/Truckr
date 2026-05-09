---
tag: REQ-BE-00025
title: Cambiar contraseña (validación de password actual + reglas de seguridad)
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/105
author: Claude Code
github_issue: 105
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtChk
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:26:25.303720+00:00Z
labels:
- REQ
- BE
- FE
- auth
- post-mvp
- us16
---

## Summary

Permitir al usuario logueado cambiar su contraseña: pide la actual, valida la nueva con las reglas del registro (US1), confirma con repetición. Cubre US16 fullstack.

## Problem Statement

US16 prescribe: pide password actual antes del cambio, nuevas con las mismas reglas que registro, confirmación visual al éxito, error si la actual es incorrecta.

## Expected Behavior

### Backend
- `PATCH /api/auth/password` — body: `{ current_password, new_password, new_password_confirmation }`.
- Valida `current_password` con `User#authenticate`. Si falla → 401.
- Valida `new_password` con las reglas (≥8 chars, mayúscula, minúscula, número).
- Valida `new_password == new_password_confirmation`.
- Al éxito, opcionalmente revoca otras sesiones activas (decisión a tomar — recomendado: sí).

### Frontend
- Pantalla `/cuenta/contrasena` (o sección dentro del perfil).
- Form con tres campos: actual, nueva, confirmación.
- Validaciones inline; hint visible con las reglas.
- Toast de éxito + redirección al perfil.

## Related

- US fuente: US16.
- Padres: `REQ-BE-00023` (auth).

## Acceptance Criteria

- [ ] `PATCH /api/auth/password` con request specs (happy + current incorrecto + nueva inválida + mismatch).
- [ ] Form en frontend con validaciones.
- [ ] Decisión sobre revocación de sesiones documentada en código.
- [ ] E2E: cambiar password, logout, login con nueva password.
