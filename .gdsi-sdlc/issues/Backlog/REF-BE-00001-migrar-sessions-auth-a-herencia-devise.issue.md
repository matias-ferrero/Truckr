---
tag: REF-BE-00001
title: Migrar Api::AuthController de sesiones a herencia de Devise (login/logout); mantener register custom
priority: P1
status: backlog
created: '2026-05-11'
source: manual
author: Claude Code
labels:
  - REF
  - BE
  - auth
  - security
  - devise
---

## Summary

Reemplazar el manejo de login/logout hand-rolled en `Api::AuthController` por herencia de `Devise::SessionsController`, manteniendo el endpoint de registro custom (porque `register` tiene un side-effect específico — `attach_role!` crea el perfil `Carrier` o `Shipper`). Objetivo: reducir superficie de código de autenticación custom y delegar el flujo a las primitivas probadas de Devise + Warden.

## Problem Statement

Actualmente `backend/app/controllers/api/auth_controller.rb` ya usa primitivas Devise/Warden a nivel modelo (`find_for_authentication`, `valid_password?`, `sign_in`, `sign_out`, `authenticate_user!`), pero implementa controllers a mano con comentario explícito (líneas 4-8):

> "We deliberately ship our own controller instead of subclassing Devise::SessionsController/RegistrationsController: those defaults are too HTML-centric for the JSON contract the FE expects."

Esta decisión deja superficie custom en:

- `login` — repite manualmente la búsqueda + verificación de password en lugar de delegar la estrategia `:database_authenticatable` de Warden.
- `logout` — `sign_out(current_user) + reset_session + head :no_content` reemplazando el flow de Devise.
- `csrf` — endpoint bespoke `GET /api/auth/csrf` que skipea `verify_authenticity_token` y devuelve `form_authenticity_token`. Resolver el "chicken-and-egg" a mano en lugar de adoptar el flow estándar de Devise (CSRF se setea en sesión al hacer GET a cualquier ruta autenticada, o vía cookie en API mode).
- Rutas: `devise_for :users, skip: :all` indica explícitamente que no se usan los controllers de Devise. Tras la migración deben mapearse `:sessions` al subclass custom (manteniendo el namespace `/api/auth/...`).

El registro (`register`) NO se migra: tiene lógica de role-attach (crear `Carrier` o `Shipper` en transacción) que no encaja limpiamente en `Devise::RegistrationsController#create`. Mantener un controller custom para `register` es más claro que sobreescribir Devise.

## Expected Behavior

- `POST /api/auth/login` y `DELETE /api/auth/logout` resueltos por una clase que herede de `Devise::SessionsController` (e.g. `Api::SessionsController < Devise::SessionsController`).
- El subclass override únicamente `respond_with` / `respond_to_on_destroy` para responder JSON con el shape `MeResource.new(user).serialize` (y el error envelope estándar `{ error: { code, message, details } }` para 401).
- Endpoint `GET /api/auth/csrf` eliminado. CSRF se entrega vía cookie (`config.action_controller.default_protect_from_forgery + cookie_csrf_strategy`) o vía header en la primera response autenticada — definir cuál en el plan de implementación.
- `Api::AuthController` se reduce a `register` + `me` (o se splittea en dos: `Api::RegistrationsController` y `Api::AuthController#me`).
- Tests de request specs cubren happy path + 401 + email no encontrado + password inválido para login/logout, sin regresiones contra el contrato actual.

## Current Behavior

Login y logout custom, con duplicación de la lógica que Devise ya provee. CSRF endpoint bespoke. Comentario en código que documenta la decisión de NO heredar de Devise — esta migración revierte explícitamente esa decisión.

## Reproduction Steps

N/A (refactor, no bug). Para auditar la superficie actual:

1. `cat backend/app/controllers/api/auth_controller.rb` — ver implementación custom.
2. `grep -nE "devise_for|skip: :all" backend/config/routes.rb` — ver el skip explícito.
3. `cd backend && bundle exec rspec spec/requests/auth_spec.rb` (si existe) — establecer baseline.

## Impact

**Quién**: equipo de backend; indirectamente todos los endpoints autenticados de la API y el `frontend/src/lib/api/*` que consume `/api/auth/*`.

**Cómo**:

- **Seguridad**: reduce superficie de código auth custom (motivación principal). Hand-rolled auth es fuente común de bugs sutiles (timing attacks, session fixation, CSRF mishandling). Delegar a Devise + Warden — librerías mainstream con auditorías — minimiza riesgo.
- **Mantenibilidad**: una sola fuente de verdad para el flow de sesión (Devise). ActiveAdmin ya usa Devise (`devise_for :admin_users, ActiveAdmin::Devise.config`), entonces se elimina la divergencia entre los dos stacks de auth del proyecto.
- **Habilita módulos futuros**: agregar `:lockable`, `:recoverable`, `:trackable` se vuelve drop-in en lugar de bolt-on.

**Riesgos**:

- Contract drift con el frontend si el JSON response cambia de shape. Mitigado con request specs antes/después.
- El endpoint `/api/auth/csrf` se elimina — el frontend lo consume al boot (verificar `frontend/src/lib/api/` antes de la implementación). La estrategia de delivery (cookie vs header) debe coordinarse FE/BE.
- `devise_for :users, skip: :all` debe cambiar para enrutar `:sessions` al subclass custom manteniendo los paths `/api/auth/login` y `/api/auth/logout` actuales (vía `path: "api/auth"` + `path_names`).

## Technical Notes

- Modelo `User` ya incluye los módulos Devise necesarios (a verificar en `backend/app/models/user.rb` — `find_for_authentication` y `valid_password?` ya funcionan, así que `:database_authenticatable` está activo).
- Devise v5.0.3 + Warden 1.2.9 instalados (`backend/Gemfile.lock`).
- Inicializador en `backend/config/initializers/devise.rb` con defaults Rails-generados — no requiere cambios para este refactor.
- API-only Rails: `ApplicationController < ActionController::API`. `BaseController` (no leído aún) debe permitir CSRF cuando session está en juego — verificar antes de planning si hay shenanigans con `protect_from_forgery` en modo API.
- Contrato JSON: `MeResource.new(user).serialize` es el shape esperado por el frontend en login exitoso (mantener idéntico).
- Errores: `{ error: { code: "invalid_credentials", message: "Email o contraseña inválidos" } }` con status 401 — el subclass debe replicar esto (con i18n: `I18n.t("errors.invalid_credentials")` — el literal en español actual viola la regla de "errores via i18n" del CLAUDE.md y se corrige en la migración).
- `auth_controller.rb:54` actualmente tiene `"Email o contraseña inválidos"` hardcoded — fix colateral incluido en la migración.

## Related

- Código: `backend/app/controllers/api/auth_controller.rb`
- Código: `backend/app/controllers/api/base_controller.rb` (a confirmar nombre/path)
- Código: `backend/config/routes.rb` (líneas con `devise_for :users, skip: :all` y bloque `/auth/*`)
- Config: `backend/config/initializers/devise.rb`
- Issue previa: `REQ-BE-00023` (Done) — implementación inicial de auth fullstack que estableció el shape actual.
- Issue previa: `REQ-BE-00020` (Done) — modelo `User` con módulos Devise.
- Convención: CLAUDE.md § "Language policy" — mensajes de error deben pasar por `I18n.t(...)`, no literales hardcoded en español.

## Acceptance Criteria

- [ ] `Api::SessionsController < Devise::SessionsController` creado bajo `backend/app/controllers/api/`.
- [ ] `Api::SessionsController#create` (login) y `#destroy` (logout) overridean solo `respond_with` / `respond_to_on_destroy` para emitir JSON con shape `MeResource.new(user).serialize` (en login) y `head :no_content` (en logout).
- [ ] Rutas: `devise_for :users` ahora monta sessions al subclass custom con `path: "api/auth"` y `path_names: { sign_in: "login", sign_out: "logout" }` — paths externos `/api/auth/login` y `/api/auth/logout` se mantienen idénticos.
- [ ] `Api::AuthController` ya no contiene `login` ni `logout`. Solo conserva `register` + `me` (o se splittea, decidir en plan).
- [ ] `GET /api/auth/csrf` eliminado. Estrategia CSRF para SPA documentada en el plan + ADR si la decisión amerita registrarse.
- [ ] Mensajes de error de auth pasan por `I18n.t("errors.*")`, no literales (`"Email o contraseña inválidos"` removido).
- [ ] Request specs en `backend/spec/requests/auth/sessions_spec.rb` cubren: login OK, login email inexistente (401), login password inválido (401), logout OK, logout sin sesión (401).
- [ ] Request specs en `backend/spec/requests/auth/registrations_spec.rb` (o equivalente) verifican que `register` sigue creando User + Carrier/Shipper en transacción y devuelve el mismo shape JSON.
- [ ] Frontend (`frontend/src/lib/api/auth.ts` o equivalente) actualizado para la nueva estrategia CSRF; smoke E2E de login/logout pasa.
- [ ] Brakeman y bundler-audit pasan sin nuevas advertencias.
- [ ] El comentario explicativo en `auth_controller.rb:4-8` se actualiza para reflejar la nueva decisión (o se elimina si el archivo se splittea).
