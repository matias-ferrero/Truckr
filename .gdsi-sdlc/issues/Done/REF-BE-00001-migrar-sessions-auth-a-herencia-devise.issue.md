---
tag: REF-BE-00001
title: Migrar Api::AuthController a Devise + devise-jwt (login/logout/me con JWT); mantener register custom
priority: P1
status: done
created: '2026-05-11'
source: manual
author: Claude Code
github_issue: 166
github_repo: tcorzo/fiuba-gestion-tp
plan: docs/features/REF/REF-BE-00001/REF-BE-00001-migrar-sessions-auth-a-herencia-devise.plan.md
labels:
  - REF
  - BE
  - auth
  - security
  - devise
  - jwt
---

## Summary

Reemplazar el manejo de sesiones hand-rolled en `Api::AuthController` (login/logout/csrf + cookies de sesión) por autenticación **stateless basada en JWT** vía la gema `devise-jwt`, conservando `register` custom (porque tiene side-effect dominio-específico — `attach_role!` crea el perfil `Carrier` o `Shipper`). Sessions delegan a `Api::SessionsController < Devise::SessionsController` envuelto por `devise-jwt`. Revocación vía estrategia **JTI Matcher** (una columna `jti` en `users`).

## Problem Statement

`backend/app/controllers/api/auth_controller.rb` (88 líneas) implementa login/logout a mano y expone un endpoint bespoke `GET /api/auth/csrf` para bootstrap del token CSRF. El comentario en líneas 4-8 documenta una decisión deliberada de no heredar de `Devise::SessionsController`. Esa decisión queda invertida: se opta por **autenticación stateless con JWT** (no por session-cookie inheritance), porque:

- Es el patrón nativo para una API Rails con `config.api_only = true` (ya documentado en ADR-002).
- Elimina toda la complejidad CSRF — sin cookies de sesión no hay vector CSRF que mitigar. Endpoint `/api/auth/csrf` se borra; `protect_from_forgery` se saca del API namespace.
- Reduce la superficie de auth custom a casi cero — Warden + devise-jwt manejan el dispatch del token, la verificación del header `Authorization: Bearer ...`, y la revocación.
- Stateless = no hay session storage que cachear (ya tenemos SolidCache, pero ahorra trips a DB).

Estado actual relevante:

- Devise v5.0.3 + Warden 1.2.9 instalados (ActiveAdmin los usa). `devise-jwt` NO está instalado todavía — se agrega.
- `Api::BaseController` (`ActionController::API`) tiene `protect_from_forgery with: :exception`, `ActionController::Cookies`, y `Devise::Controllers::Helpers`. Tras JWT: sin CSRF, sin cookies de sesión en el API path.
- Modelo `User` carga `:database_authenticatable, :registerable, :validatable`. Falta `:jwt_authenticatable` + include de `Devise::JWT::RevocationStrategies::JTIMatcher`.
- Routes: `devise_for :users, skip: :all` + bloque manual en `namespace :api`. La ruta `/api/auth/csrf` se elimina.
- FE (`frontend/src/auth/AuthContext.tsx`): hoy hace `GET /api/auth/csrf` al boot y manda header `X-CSRF-Token` con cada mutación. Tras JWT: guarda el token en `localStorage`, manda `Authorization: Bearer <jwt>` con cada request.
- Specs rswag en `backend/spec/requests/api/auth_spec.rb` pinean el contrato — todos los assertions migran a JWT (header `Authorization` en lugar de cookie de sesión).
- Rack::Attack throttle sobre POST `/api/auth/login` se mantiene tal cual.

## Expected Behavior

- `POST /api/auth/login` resuelto por `Api::SessionsController < Devise::SessionsController`. Respuesta: 200 + body `MeResource.new(user).serialize` + header de respuesta `Authorization: Bearer <jwt>` (devise-jwt lo inyecta automáticamente vía `Warden::JWTAuth::Middleware::Dispatcher`).
- `POST /api/auth/register` resuelto por `Api::AuthController#register` (sin cambios estructurales en su lógica `attach_role!`). Respuesta: 201 + body `MeResource` + header `Authorization: Bearer <jwt>` (se dispara el dispatcher al hacer `sign_in`).
- `DELETE /api/auth/logout` resuelto por `Api::SessionsController#destroy`. Requiere header `Authorization: Bearer <jwt>`. Devise-jwt corre la estrategia JTI Matcher → rota el `jti` del User → todos los tokens previos del usuario son inválidos. Respuesta: 204.
- `GET /api/auth/me` resuelto por `Api::AuthController#me`. Requiere header `Authorization: Bearer <jwt>`. Respuesta: 200 + `MeResource`.
- 401 con envelope `{ error: { code: "invalid_credentials" | "unauthorized" } }` para todo fallo de auth (login con creds inválidas, request a endpoint protegido sin/con JWT inválido o revocado).
- Endpoint `GET /api/auth/csrf` eliminado. No queda CSRF en el API path: `Api::BaseController` no incluye `RequestForgeryProtection` ni hace `protect_from_forgery`.
- Storage del JWT en el cliente: `localStorage["truckr.jwt"]`. Boot del `AuthProvider` lee el token, hidrata `me` vía `GET /api/auth/me`, y limpia el storage si el server devuelve 401.

## Current Behavior

Login/logout hand-rolled; CSRF endpoint bespoke; session cookies; FE hace dance de CSRF token cookie. Comentario explicativo en código que justifica no usar Devise — esta migración invierte la decisión.

## Reproduction Steps

N/A (refactor, no bug). Para auditar la superficie actual:

1. `cat backend/app/controllers/api/auth_controller.rb` — implementación custom.
2. `grep -nE "csrf|cookies|protect_from_forgery" backend/app/controllers/api/base_controller.rb` — superficie CSRF actual.
3. `grep -rE "csrf|XSRF" frontend/src/auth/` — superficie CSRF en FE.

## Impact

**Quién**: equipo de backend; todos los endpoints autenticados de la API; `frontend/src/auth/*` y todo callsite de `apiFetch`.

**Cómo**:

- **Seguridad**: elimina vector CSRF entero (al sacar cookies de sesión del API path). Trade-off: el JWT en `localStorage` es exfiltrable vía XSS — riesgo aceptado para coursework (sin usuarios reales, sin PII real). Documentado en ADR-011.
- **Mantenibilidad**: una sola fuente de verdad para auth (Devise + devise-jwt). El FE deja de hacer dance de cookie/header CSRF.
- **Performance**: stateless — server no consulta session storage en cada request autenticado. JWT trae el `user_id` y `jti` embebidos; Devise busca el User una vez por request y valida `jti` contra DB (esa lookup queda).
- **Habilita módulos futuros**: agregar `:lockable`, `:trackable` queda drop-in. Mobile/PWA queda viable sin re-tocar la auth.

**Riesgos**:

- `localStorage` + XSS = exfiltración. Mitigación: CSP estricta (no en scope de este issue), code-review de FE para evitar `dangerouslySetInnerHTML` con input no-trustado. Riesgo aceptado para coursework.
- `jti` rotation = logout invalida TODOS los devices del usuario (single-device-effective logout). Aceptable — el proyecto no tiene multi-device como requisito.
- JWT secret rotation requiere downtime o doble-secret. Para coursework no es problema.

## Technical Notes

- Gema: `devise-jwt ~> 0.12` (compatible con Devise 5).
- Secret JWT: `Rails.application.credentials.devise_jwt_secret_key` (nuevo). En dev/test: fallback a `Rails.application.secret_key_base`. Documentado en ADR-011.
- Expiración: 24 horas (course project — no hace falta refresh token).
- Estrategia de revocación: **JTI Matcher**. Una columna `jti :string NOT NULL` en `users`, con índice único. `before_create` setea `SecureRandom.uuid`. Logout rota el `jti` del user.
- Migración: agrega `jti` nullable → backfill con `SecureRandom.uuid` por row → `change_column_null :users, :jti, false`. SQLite-friendly (sin `gen_random_uuid()`).
- Session middleware: deshabilitar para el API path. Opciones: `Api::BaseController.include(ActionController::API::SessionMiddlewareDisabled)` (no existe builtin); más simple: NO incluir `ActionController::Cookies` ni `Session` en `BaseController` (ya es `ActionController::API` — los cookies se incluyen explícitamente hoy, se sacan).
- Failure app: `Api::DeviseFailureApp < Devise::FailureApp` emite envelope JSON 401 (mismo patrón que el plan anterior; aplica a `:invalid` y `:expired_session` y `:unauthenticated`).
- Errores hardcoded en español dentro de `BaseController` y `AuthController` violan la regla i18n del CLAUDE.md — se migran a `I18n.t("errors.*")` como fix colateral (in-scope).
- Frontend: `apiFetch` se actualiza para leer JWT de `localStorage` y mandarlo en `Authorization`. CSRF dance entero desaparece de `AuthContext.tsx` y MSW handlers.

## Related

- Código: `backend/app/controllers/api/auth_controller.rb`, `backend/app/controllers/api/base_controller.rb`
- Código: `backend/app/models/user.rb`
- Código: `backend/config/routes.rb`, `backend/config/initializers/devise.rb`
- Código: `frontend/src/auth/AuthContext.tsx`, `frontend/src/test/mocks/handlers.ts`
- Issue previa: `REQ-BE-00023` (Done) — implementación inicial de auth fullstack.
- Issue previa: `REQ-BE-00020` (Done) — modelo `User` con módulos Devise.
- ADRs relacionadas: ADR-002 (Rails API-only), ADR-007 (PK strategy — `jti` es columna estándar string).
- Convención: CLAUDE.md § "Database policy" — `jti` es un `:string`, SQLite-friendly, sin `uuid` nativo.

## Acceptance Criteria

- [ ] Gema `devise-jwt` agregada al `Gemfile`. `bundle install` corrido y `Gemfile.lock` commiteado.
- [ ] Migración crea columna `jti` en `users` (string, NOT NULL post-backfill, índice único).
- [ ] `User` incluye `:jwt_authenticatable`, `include Devise::JWT::RevocationStrategies::JTIMatcher`, `before_create :set_jti`.
- [ ] `Devise.setup` configura `jwt.secret`, `jwt.expiration_time = 24.hours`, `jwt.dispatch_requests` para `POST /api/auth/login` y `POST /api/auth/register`, `jwt.revocation_requests` para `DELETE /api/auth/logout`.
- [ ] `Api::SessionsController < Devise::SessionsController` con `respond_with` y `respond_to_on_destroy` overrideados a JSON.
- [ ] `Api::AuthController` reducido a `register` + `me`. `register` sigue creando User + Carrier/Shipper en transacción y devuelve `MeResource`. La respuesta debe incluir header `Authorization: Bearer <jwt>` (validar en spec).
- [ ] `Api::BaseController` SIN `protect_from_forgery`, SIN `ActionController::Cookies`, SIN `RequestForgeryProtection`. `authenticate_user!` queda como wrapper que delega a Warden y devuelve envelope 401 JSON cuando falla.
- [ ] Ruta `GET /api/auth/csrf` eliminada de `config/routes.rb`. Método `Api::AuthController#csrf` eliminado.
- [ ] `Api::DeviseFailureApp < Devise::FailureApp` emite `{ error: { code: "invalid_credentials" | "unauthorized" } }` con 401. Configurado en `devise.rb` vía `manager.failure_app`.
- [ ] Strings hardcoded en `BaseController` y `AuthController` (`"Autenticación requerida"`, `"Email o contraseña inválidos"`, `"Acceso denegado"`, `"Recurso no encontrado"`, `"Carrier role required"`) migradas a `I18n.t("errors.*")`. Locales `en.yml` y `es.yml` actualizados.
- [ ] Specs RSpec: `spec/requests/api/sessions_spec.rb` cubre login OK (con header Authorization en respuesta), login con email inexistente (401), login con password inválida (401), logout OK (con JWT válido → 204), logout con JWT inválido (401), JWT revocado tras logout (request post-logout con mismo JWT → 401). `spec/requests/api/auth_spec.rb` reducido (register + me, sin CSRF, sin login, sin logout).
- [ ] Spec de modelo `User`: `User#jti` se setea en create; `jti` único; logout rota `jti`.
- [ ] FE `AuthContext.tsx` guarda JWT en `localStorage["truckr.jwt"]`. `apiFetch` envía `Authorization: Bearer ${jwt}` cuando hay token. Sin CSRF reads. Sin `fetchCsrf`.
- [ ] FE MSW handlers actualizados: handler `/api/auth/csrf` eliminado; `/api/auth/login` y `/api/auth/register` emiten header `Authorization` en respuesta; `/api/auth/me` 401 si falta el header.
- [ ] Playwright smoke E2E: register → home → logout → login → home → reload → siguen logueado → logout → reload → en home anónimo.
- [ ] Brakeman + bundler-audit + rubocop + rspec + vitest + playwright (chromium) pasan en CI.
- [ ] ADR-011 escrita y mergeada en el mismo PR.
- [ ] Comentario obsoleto en `auth_controller.rb:4-8` reemplazado por nota corta apuntando a ADR-011.
