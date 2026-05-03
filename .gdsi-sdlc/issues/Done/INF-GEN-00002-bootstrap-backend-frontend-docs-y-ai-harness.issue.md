---
tag: INF-GEN-00002
title: Bootstrap backend, frontend, docs y AI harness
priority: P1
status: done
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/62
author: Claude Code
github_issue: 62
github_repo: tcorzo/fiuba-gestion-tp
labels:
- INF
- GEN
- bootstrap
---

## Summary

Pasar el repo de "planning-only" a estado ejecutable: dejar el backend Rails y el frontend React+Deno corriendo end-to-end con un slice mínimo, alinear los docs (`CLAUDE.md`, `README.md`, artifacts) con la nueva realidad del código, y actualizar el AI harness (configuración de agentes/harness en `.gdsi-sdlc/`, `.agents/`, hooks de Claude Code) para que el flujo automatizado de issues/PR funcione contra los nuevos componentes.

## Problem Statement

Hoy el repo es mayormente documentación Typst. El backend Rails y el frontend React+Deno+Vite fueron scaffoldeados pero no arrancan un flujo real: no hay integración BE↔FE, ni datos de ejemplo, ni guía de "cómo correr la app". Además, el AI harness (`.gdsi-sdlc/`, prompts, agentes) fue diseñado cuando el repo era 100% docs y no contempla los nuevos paths `backend/` y `frontend/`. Sin este bootstrap, no se puede empezar el Sprint 1 con US reales.

## Expected Behavior

- `just backend-dev` levanta Rails con un endpoint healthcheck o seed mínimo.
- `just frontend-dev` levanta Vite y la landing consume al menos un endpoint del backend (puede ser mock proxy + un fetch real).
- `CLAUDE.md` y `README.md` documentan: cómo arrancar BE+FE, dónde viven los nuevos archivos `frontend/src/api.ts` y `frontend/src/landingContent.ts`, y la convención de scopes para issues que tocan código (no solo docs).
- Los artifacts en `docs/` reflejan el estado actual (HLD/arch coherente con el stack realmente scaffoldeado).
- AI harness actualizado:
  - `.gdsi-sdlc/config.json` y plantillas de issues conscientes de scopes `BE`/`FE` aplicados a código real (no solo a "secciones del doc").
  - Prompts/skills `c9y-sdlc:*` siguen funcionando con los nuevos paths.
  - `.agents/` y hooks de Claude Code revisados (permisos, allowlists para `bundle`, `deno`, `rails`).

## Current Behavior

- Backend Rails scaffoldeado, sin rutas ni controladores propios.
- Frontend con landing self-sustaining (commit `4247ad1`) pero sin wiring real al BE; hay archivos untracked (`frontend/src/api.ts`, `frontend/src/landingContent.ts`) que todavía no se commitearon ni se documentaron.
- `CLAUDE.md` describe el repo como "greenfield, mostly docs" — desactualizado respecto al `justfile` que ya tiene recipes `backend-dev`/`frontend-dev`.
- AI harness asume issues mayormente de scope `DOC`; la triage hacia `BE`/`FE` no tiene contexto de código real.

## Reproduction Steps

1. `git clone` + `mise install` + `prek install`.
2. Intentar levantar la app end-to-end siguiendo solo `README.md`/`CLAUDE.md`.
3. Observar que no hay paso a paso para BE+FE corriendo juntos ni un endpoint que el FE consuma.

## Impact

- **Equipo**: bloquea el arranque del Sprint 1 con US ejecutables.
- **AI harness**: `c9y-sdlc:issues:plan` y `c9y-sdlc:issues:implement` no tienen contexto suficiente para issues de código.
- **Onboarding**: cualquier nuevo colaborador (humano o agente) no puede correr la app.

## Technical Notes

- Stack ya fijado: Rails 3.4 (`backend/`), React + Deno + Vite + TS (`frontend/`, `:5173`).
- `justfile` ya tiene `backend-dev` y `frontend-dev` (commit `c116e77`) — usarlas como contrato.
- Archivos untracked relevantes:
  - `frontend/src/api.ts` — capa cliente HTTP (revisar y commitear como parte de este issue).
  - `frontend/src/landingContent.ts` — contenido estático separado de la landing.
- Mantener consistencia con releases automatizados (Conventional Commits): cada PR de este bootstrap debe ir con `feat:` / `chore:` / `docs:` según corresponda.
- El AI harness vive en `.gdsi-sdlc/` (no `.c9y-sdlc/`) — los prompts del plugin deben adaptarse o se debe documentar el alias.

## Origin

Manual — solicitado por el owner del repo para destrabar el desarrollo real.

## Related

- Commits recientes: `c116e77` (justfile recipes), `4247ad1` (landing self-sustaining), `8141ff1` (CLAUDE.md), `42e90af` (gdsi-sdlc scaffold).
- Issue relacionado: `INF-FE-00001` (cierre de artifacts y próximos pasos).
- Paths: `backend/`, `frontend/`, `docs/`, `.gdsi-sdlc/`, `.agents/`, `CLAUDE.md`, `README.md`, `justfile`.

## Acceptance Criteria

- [ ] Backend Rails expone al menos un endpoint healthcheck (`GET /up` o `/api/health`) y arranca con `just backend-dev`.
- [ ] Frontend consume ese endpoint desde `frontend/src/api.ts` y muestra el estado en la landing (o componente de debug).
- [ ] `frontend/src/api.ts` y `frontend/src/landingContent.ts` están commiteados y documentados.
- [ ] `README.md` tiene una sección "Running the app" con BE+FE end-to-end.
- [ ] `CLAUDE.md` actualizado: ya no describe el repo como "mostly docs", incluye guía para tocar `backend/` y `frontend/`, y referencia el AI harness en `.gdsi-sdlc/`.
- [ ] `docs/` revisado: HLD / architecture artifacts coherentes con el stack actual.
- [ ] AI harness actualizado:
  - [ ] `.gdsi-sdlc/config.json` y plantillas reflejan scopes `BE`/`FE` aplicados a código.
  - [ ] `.agents/` y hooks/permisos de Claude Code permiten `bundle`, `deno`, `rails` sin prompts repetidos.
  - [ ] Skills `c9y-sdlc:*` validadas contra los nuevos paths (smoke test: `triage` + `plan` sobre un issue dummy de BE o FE).
- [ ] Conventional Commits respetados; release-please sigue funcionando tras el merge.
