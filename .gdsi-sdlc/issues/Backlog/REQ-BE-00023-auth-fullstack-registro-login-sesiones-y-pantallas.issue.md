---
tag: REQ-BE-00023
title: Auth fullstack — registro, login, sesiones + pantallas en frontend
priority: P0
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/103
author: Claude Code
github_issue: 103
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCd0
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:26:01.513502+00:00Z
labels:
- REQ
- BE
- FE
- auth
- foundation
- mvp
---

## Summary

Implementar autenticación end-to-end: endpoints de registro/login/logout/sesión actual en el backend, pantallas correspondientes en el frontend, persistencia de sesión, y exposición de `current_user` a todos los `Api::*Controller`s. Cubre US1 (Registrarse), US2 (Login) y prepara el terreno para US3 (Modificar Perfil) y US16 (Cambiar Contraseña). Es bloqueante de **cualquier** endpoint `/me/*`.

## Problem Statement

`CLAUDE.md` y el roadmap declaran "no auth yet". Pero todos los issues que creé asumen `current_user` (los endpoints `carriers/me/...`, payouts, reseñas, etc.). Este issue cierra esa brecha y deja un sistema usable end-to-end: alguien se registra como Shipper o Carrier, se loguea, opera con su perfil.

## Expected Behavior

### Backend
- Estrategia de sesión: **session cookie** httpOnly + SameSite=Lax (no JWT — Rails session store + Solid Cache es suficiente y elimina la complejidad de refresh tokens). Decisión registrada en un ADR breve si todavía no existe.
- Endpoints:
  - `POST /api/auth/register` — body: `{ email, password, name, role: "carrier"|"shipper"|"both" }`. Crea `User` + la fila de `Carrier`/`Shipper` correspondiente (o ambas).
  - `POST /api/auth/login` — body: `{ email, password }`. Setea cookie de sesión.
  - `DELETE /api/auth/logout` — borra cookie.
  - `GET /api/auth/me` — devuelve `User` + roles + datos básicos del Carrier/Shipper.
- `ApplicationController` expone `current_user`, `authenticate_user!`, `current_carrier`, `current_shipper` (helpers).
- Rate limiting básico en login (5 intentos / 15min por IP) — usar `rack-attack` o equivalente.
- Validaciones de password: mínimo 8 caracteres, al menos una mayúscula, una minúscula y un número (los AC de US1).
- Envío de email de bienvenida (depende de `INF-BE-00005` mailer scaffolding).

### Frontend
- Pantallas: `/registro`, `/login`, `/logout` (action), header con CTA "Iniciar sesión" / "Salir" según estado.
- Form de registro con los campos requeridos + selector de rol (Cliente / Transportista / Ambos).
- Validación client-side de password match + reglas; errores server-side mostrados inline.
- Guardado del estado de sesión: poll inicial a `GET /api/auth/me`; React Context para `useCurrentUser()`.
- Redirect post-login al "home" del rol correspondiente (placeholder hasta que existan US10 / US4).
- Cierre de sesión disponible desde header en cualquier pantalla.
- Cobertura E2E: registro + login + logout happy path en Playwright.

### Cross-cutting
- CORS ajustado para que las cookies funcionen en dev (`localhost:5173` ↔ `localhost:3000`), `credentials: include` en fetch.
- CSRF: dado que es API session-cookie, hace falta CSRF token. Endpoint `GET /api/csrf` que devuelve el token; el frontend lo agrega como header `X-CSRF-Token` en POSTs.

## Technical Notes

- **Session store**: Solid Cache (DB-backed), no Redis. Coherente con el stack del proyecto.
- **Password digest**: `User` ya tiene `password_digest` por `REQ-BE-00020`; esto solo lo activa con `has_secure_password validations: true`.
- **Roles**: la fila de `Carrier`/`Shipper` es el estado de rol. No se agregan booleans desnormalizados (regla del proyecto).
- **Email verification**: NO se incluye acá. La verificación por email es US22 (Release 3); este issue acepta usuarios sin verificar y los marca como `email_verified: false`.
- **Sin auth UI bonita todavía**: los formularios siguen `frontend/.impeccable.md` pero no requieren skill `polish`/`critique` corrida en este issue (eso es post-MVP).

## Related

- Padres: `REQ-BE-00020` (Identity models), `INF-BE-00005` (mailer — para email de bienvenida; opcional, el welcome puede agregarse luego).
- US fuente: US1, US2 (cubre las dos completas en un issue fullstack).
- Bloquea: US3 (modificar perfil), US16 (cambiar contraseña), US22 (verify email), todos los endpoints `/me/*`.

## Acceptance Criteria

- [ ] Endpoints `/api/auth/{register,login,logout,me,csrf}` implementados con request specs.
- [ ] `ApplicationController` expone `current_user`, `current_carrier`, `current_shipper`, `authenticate_user!`.
- [ ] Rate limiting de login funcional.
- [ ] Pantallas `/registro` y `/login` implementadas y conectadas al BE.
- [ ] Header con estado de sesión + logout en cualquier ruta.
- [ ] Validaciones de password (los 4 AC de US1) cubiertas en BE y FE.
- [ ] CORS + CSRF configurados, fetch con `credentials: include` funciona.
- [ ] E2E (Playwright): registro → login → me → logout.
- [ ] Backend specs ≥80% sobre `app/controllers/api/auth_controller.rb`.
- [ ] Frontend tests ≥80% sobre los componentes de auth.
- [ ] Conventional commit `feat(auth): implement registration and login`.
- [ ] Identifiers en inglés.
