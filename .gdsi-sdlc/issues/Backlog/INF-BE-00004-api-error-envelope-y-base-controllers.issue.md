---
tag: INF-BE-00004
title: API error envelope estándar + base controller helpers (rescue_from, JSON shape)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/87
author: Claude Code
github_issue: 87
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtB2Q
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-09T13:35:40.075274+00:00Z
labels:
- INF
- BE
- api
- foundation
---

## Summary

Implementar el envelope de errores de la API recomendado en `docs/02-high-level-design/high-level-design.md` (`{ error: { code, message, details } }`) más helpers de `ApplicationController` para serializar errores comunes consistentemente. Es la cola que pega todos los demás endpoints.

## Problem Statement

Hoy `Api::HealthController#show` (lo poco que existe) devuelve JSON sin shape estándar. Cada endpoint que se vaya agregando va a inventar su propio formato si no se define ahora. El HLD ya recomienda la shape; falta materializarla.

## Expected Behavior

- `ApplicationController` (la base de `Api::*Controller`) tiene un `rescue_from` que mapea:
  - `ActiveRecord::RecordNotFound` → 404 + `error: { code: "not_found", message: "..." }`.
  - `ActiveRecord::RecordInvalid` → 422 + `error: { code: "validation_failed", message: "...", details: { errors: [...] } }`.
  - `ActiveRecord::RecordNotUnique` → 409 + `error: { code: "conflict", message: "...", details: {...} }`.
  - `ActionController::ParameterMissing` → 400 + `error: { code: "missing_parameter", ... }`.
  - `Pundit::NotAuthorizedError` (si se usa más adelante) → 403.
  - `StandardError` (último resorte, solo en producción) → 500 + `error: { code: "internal_error", ... }` con request ID.
- Helper `render_error(status:, code:, message:, details: nil)` para errores manuales.
- Cada response de error incluye `request_id` (de `Rails.application.config.log_tags`) y un timestamp.
- Logger tagged: errores 5xx logean stack trace; 4xx logean en `info` con código de error.
- Tests cubren cada uno de los rescues con request specs.

## Technical Notes

- **Request ID**: Rails ya emite un request ID en los logs; exponerlo en el header `X-Request-Id` y en el body del error es trivial.
- **Locale-aware messages**: usar I18n para los mensajes (es-AR + en). No hardcodear strings en español en los rescues.
- **Backwards-compat**: `Api::HealthController#show` se queda como está (la respuesta de health no necesita envelope).
- **No envolverver successes**: el envelope es solo para errores. Los success responses devuelven la representación del recurso directamente, en línea con la convención REST estándar.

## Related

- Padre: ninguno (es self-contained, solo depende del scaffolding existente).
- Bloquea (parcialmente): todos los endpoints — sin estandarizar la shape, los issues de feature van a inventar la suya.

## Acceptance Criteria

- [ ] `ApplicationController` con `rescue_from` para los casos enumerados.
- [ ] Helper `render_error` disponible en cualquier controller.
- [ ] Header `X-Request-Id` en cada response.
- [ ] I18n para mensajes (es-AR como default).
- [ ] Tests cubren los 5 rescues principales.
- [ ] Documentación en `docs/02-high-level-design/high-level-design.md` § "Error Handling" actualizada con el shape final.
- [ ] Conventional commit: `feat(api): add standard error envelope and base controller`.
