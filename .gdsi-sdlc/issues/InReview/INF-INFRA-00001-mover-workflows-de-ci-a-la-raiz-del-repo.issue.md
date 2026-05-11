---
tag: INF-INFRA-00001
title: Mover workflows de CI a la raíz del repo con filtros por paths
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/70
author: Claude Code
github_issue: 70
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrrFqQ
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T14:46:07.399970+00:00Z
labels:
- INF
- INFRA
- ci
---

## Summary

Mover `backend/.github/workflows/ci.yml` (y los workflows de frontend cuando existan) al directorio canónico `.github/workflows/` en la raíz del repo, agregando filtros `paths:` para que los pipelines de backend y frontend solo se disparen ante cambios en sus respectivas áreas.

## Problem Statement

GitHub Actions únicamente lee workflows ubicados en `<repo-root>/.github/workflows/`. El archivo actual `backend/.github/workflows/ci.yml` (generado por el scaffolder de Rails 8) **nunca se ejecuta**: los jobs `scan_ruby` (brakeman), `scan_js` (importmap audit), `bundler-audit` y `lint` (rubocop) están definidos pero invisibles para Actions. Esto deja al repo sin la red de seguridad que el scaffolder asume:

- PRs que rompen rubocop o introducen vulnerabilidades detectables por brakeman se mergean sin alerta.
- El CI roadmap de `docs/onboarding/05-testing-strategy.md` (paso 1: agregar `.github/workflows/test.yml`) está bloqueado por la confusión sobre qué workflow corre dónde.
- Cuando aparezca un workflow de frontend equivalente (vitest + playwright + tsc), el patrón actual lo dejaría también colgado en `frontend/.github/workflows/`.

Adicionalmente, sin filtros `paths:` un cambio puramente de docs (`docs/**`) o de frontend (`frontend/**`) dispararía el pipeline pesado de backend (bundle install + brakeman + bundler-audit + rubocop), gastando minutos de Actions y demorando feedback.

## Expected Behavior

- Un único árbol de workflows en `<repo-root>/.github/workflows/`:
  - `release-please.yml` (existente, sin cambios funcionales).
  - `backend-ci.yml` — equivalente al `ci.yml` actual (`scan_ruby`, `scan_js` / importmap audit, `lint`).
  - Hueco previsto para `frontend-ci.yml` cuando se agregue (no es alcance de este issue, pero el patrón debe estar listo para extenderlo).
- Filtros `paths:` en cada workflow para que solo corran ante cambios relevantes:
  - `backend-ci.yml` se dispara con cambios en `backend/**` y en su propio `.github/workflows/backend-ci.yml`.
  - `frontend-ci.yml` (futuro) se disparará con cambios en `frontend/**` y en su propio archivo de workflow.
- Los `working-directory: backend` / `defaults.run.working-directory` se ajustan para que los pasos sigan ejecutándose en el subdirectorio correcto desde la raíz del repo.
- `backend/.github/workflows/ci.yml` se elimina (o el directorio entero `backend/.github/` si queda vacío salvo `dependabot.yml` — ver Technical Notes).
- En un PR que solo toca `docs/**` o `.gdsi-sdlc/**`, ningún workflow de backend/frontend corre. En un PR que toca `backend/**`, corre solo `backend-ci.yml`.

## Current Behavior

- `backend/.github/workflows/ci.yml` existe pero GitHub Actions lo ignora — los runs de `brakeman`, `bundler-audit` y `rubocop` no aparecen en la UI de checks de los PRs.
- `<repo-root>/.github/workflows/` solo contiene `release-please.yml`.
- `backend/.github/dependabot.yml` está en el subdirectorio (válido para Dependabot, que sí lee de cualquier `.github/`, a diferencia de Actions — confirmar antes de mover).
- No hay filtros por path; cualquier futuro workflow correría siempre.

## Reproduction Steps

1. Abrir un PR que modifique `backend/Gemfile` o `backend/app/**`.
2. Observar la lista de checks: solo aparece `release-please` (si aplica). No hay rubocop / brakeman / bundler-audit.
3. Verificar en `Actions` del repo en GitHub: el workflow `CI` definido en `backend/.github/workflows/ci.yml` no figura.

## Impact

- **Seguridad**: brakeman y bundler-audit no protegen el código. Una vulnerabilidad introducida queda sin detectar hasta que alguien corra `bin/brakeman` localmente.
- **Calidad**: rubocop no gatekeea PRs; convenciones de estilo derivan en silencio.
- **Costos / tiempos**: cuando se mueva el workflow sin `paths:`, todo PR de docs disparará el bundle de backend (~minutos). Con el filtro, queda acotado.
- **Confusión**: nuevos colaboradores asumen que el CI corre porque ven el archivo; el bug es invisible hasta auditar Actions.

## Technical Notes

- Confirmar el comportamiento de Dependabot antes de mover `backend/.github/dependabot.yml`. Dependabot lee únicamente `<repo-root>/.github/dependabot.yml`; el archivo en el subdirectorio del backend probablemente también esté inactivo y deba consolidarse en la raíz con múltiples `package-ecosystem:` (uno para `bundler` apuntando a `/backend`, otro para `npm`/futuro, otro para `github-actions`).
- Sintaxis del filtro:

  ```yaml
  on:
    pull_request:
      paths:
        - "backend/**"
        - ".github/workflows/backend-ci.yml"
    push:
      branches: [ main ]
      paths:
        - "backend/**"
        - ".github/workflows/backend-ci.yml"
  ```

- Para que `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit` y `bin/importmap` funcionen desde la raíz, agregar `defaults.run.working-directory: backend` en el job o `working-directory: backend` por step.
- `ruby/setup-ruby@v1` necesita encontrar `Gemfile`/`Gemfile.lock`; pasarle `working-directory: backend` o usar `bundler-cache: true` con `working-directory` correcto.
- El cache de rubocop (`tmp/rubocop`) ya es relativo al backend; con `working-directory: backend` la ruta `tmp/rubocop` resuelve a `backend/tmp/rubocop` — verificar que el `actions/cache@v4` use la ruta correcta (`backend/tmp/rubocop`).
- Si el patrón de `paths:` deja afuera cambios al propio workflow, agregarlo explícitamente (`.github/workflows/backend-ci.yml`) para que un edit del workflow lo re-ejecute.
- No usar `paths-ignore:` mezclado con `paths:` en el mismo trigger — son excluyentes.
- Decidir si se mantiene el nombre `CI` (corto, ambiguo cuando haya frontend) o se renombra a `Backend CI` desde ya. Recomendación: renombrar para evitar churn cuando llegue el frontend.
- Considerar protección de branch: una vez que el workflow corra, `main` puede requerir el check `Backend CI / lint` etc. — coordinar con `tcorzo` antes de marcar como required.
- Path alterno futuro: cuando exista `frontend-ci.yml`, replicar el patrón con `paths: ["frontend/**", ".github/workflows/frontend-ci.yml"]`.

## Origin

Manual — solicitado por el owner del repo: "Move backend/.github/workflows/ci.yml (and any frontend CI when added) up to repo-root .github/workflows/ so GitHub Actions actually executes the brakeman / bundler-audit / rubocop jobs on PRs. Ideally with a paths: filter so backend-only changes don't trigger frontend pipelines and vice versa."

## Related

- Issue relacionado: `INF-GEN-00002` (bootstrap BE/FE/docs/AI harness) — Done; introdujo el scaffold que dejó el workflow en el subdirectorio equivocado.
- Documento relacionado: `docs/onboarding/05-testing-strategy.md` — sección "CI Roadmap" paso 1 ("Add a test workflow") depende de tener el patrón de `.github/workflows/` resuelto antes de sumar specs.
- Paths involucrados: `backend/.github/workflows/ci.yml`, `backend/.github/dependabot.yml`, `.github/workflows/release-please.yml`.

## Acceptance Criteria

- [ ] `backend/.github/workflows/ci.yml` se elimina del repo.
- [ ] `<repo-root>/.github/workflows/backend-ci.yml` existe con los jobs `scan_ruby` (brakeman), `scan_js` / `bundler-audit` (importmap audit + bundler-audit), y `lint` (rubocop), funcionalmente equivalentes al original.
- [ ] El nuevo workflow declara `on.pull_request.paths` y `on.push.paths` que incluyen `backend/**` y `.github/workflows/backend-ci.yml`.
- [ ] Cada job usa `working-directory: backend` (o `defaults.run.working-directory`) y `ruby/setup-ruby@v1` con `working-directory: backend` y `bundler-cache: true`.
- [ ] El cache de rubocop apunta a la ruta correcta relativa a la raíz del repo (`backend/tmp/rubocop`).
- [ ] Verificación en un PR de prueba (o `act` local): el workflow `Backend CI` aparece y corre los 3 jobs sobre cambios en `backend/**`; no corre sobre cambios en `docs/**` o `.gdsi-sdlc/**`.
- [ ] Decisión sobre `backend/.github/dependabot.yml` registrada (mover/consolidar o dejar): si se consolida, `<repo-root>/.github/dependabot.yml` cubre `bundler` con `directory: /backend` y queda lista la entrada `npm`/`github-actions` para el futuro.
- [ ] Workflow renombrado a `Backend CI` (no `CI` a secas) para dejar lugar a `Frontend CI` sin colisión.
- [ ] Sección "CI Roadmap" en `docs/onboarding/05-testing-strategy.md` actualizada con el patrón establecido (root + paths filter) como precondición del paso "Add a test workflow".
- [ ] Conventional Commits respetados: `ci(backend): move workflow to repo root with paths filter` o similar.
