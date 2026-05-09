---
tag: REQ-FE-00012
title: Modificar perfil de usuario (datos personales y datos de camión si es transportista)
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/118
author: Claude Code
github_issue: 118
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDAg
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:28:58.348974+00:00Z
labels:
- REQ
- FE
- BE
- profile
- mvp
- us3
---

## Summary

Permitir al usuario logueado modificar sus datos personales (nombre, email, teléfono) y, si es transportista, los datos de su camión (delegado a la pantalla de Vehicle si existe — link). Cubre US3 fullstack.

## Problem Statement

US3 ("Modificar Perfil") AC: campos editables, validación antes de enviar, confirmación visual, persistencia. Hoy solo existe `auth/me` (lectura) tras `REQ-BE-00023`; falta el `PATCH`.

## Expected Behavior

### Backend
- `PATCH /api/auth/me` — recibe campos modificables (`name`, `phone`, `email`). Valida unicidad de `email`. Si cambia el email, marca `email_verified: false` y envía mail de re-verificación (cuando exista US22).
- Endpoint protegido por `authenticate_user!`.

### Frontend
- Pantalla `/perfil` (o `/cuenta`) con form pre-poblado con los datos del `currentUser`.
- Validaciones inline (formato de email, teléfono).
- Botón "Guardar" deshabilitado hasta que haya cambios.
- Toast de confirmación al guardar exitoso; errores inline si validación falla.
- Si el usuario es Carrier, link a `/transportista/vehiculo` (cubierto por `REQ-BE-00009`).

## Related

- US fuente: US3.
- Padres: `REQ-BE-00023` (auth), `REQ-BE-00020` (User model), `INF-FE-00003` (routing).

## Acceptance Criteria

- [ ] `PATCH /api/auth/me` con request specs (happy path + validación + email change → unverified).
- [ ] Pantalla `/perfil` con form, validaciones y feedback.
- [ ] Test E2E: editar nombre, persistir, re-leer, ver el cambio.
- [ ] Sin regresiones en `GET /api/auth/me` ni en login.
- [ ] Conventional commit `feat(profile): allow user to update profile`.
