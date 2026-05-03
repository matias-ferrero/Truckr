---
tag: INF-INFRA-00002
title: Agregar workflow de Frontend CI (Vitest + vite build + Playwright)
priority: P2
status: backlog
created: '2026-05-03'
source: manual
author: Claude Code
labels:
- INF
- INFRA
- ci
- frontend
---

## Summary

Crear `<repo-root>/.github/workflows/frontend-ci.yml` que corra el pipeline del frontend en cada PR/push: type-check (`tsc --noEmit`), Vitest (unit + component con coverage), `vite build` (smoke de bundle) y Playwright E2E en Chromium. Filtrado por `paths: ["frontend/**", ".github/workflows/frontend-ci.yml"]` para que cambios fuera del frontend no lo disparen.

## Problem Statement

El frontend tiene la red de testing armada (Vitest, RTL, MSW, Playwright, coverage v8 con target ≥ 80%) pero no hay automatización: ningún PR ejecuta `deno task test:run` ni `deno task test:e2e`. Hoy:

- Una regresión en `App.tsx` que rompa el smoke de Vitest pasa desapercibida hasta que alguien corre el comando localmente.
- Un cambio que rompe el bundle de producción (`vite build`) no se detecta hasta el primer despliegue real.
- Playwright nunca se ejecuta en CI — el smoke `e2e/smoke.spec.ts` es el único E2E y no protege nada porque no corre.
- TypeScript `strict: true` no se valida en PRs; un type error puede mergearse si el desarrollador no corre `deno task build` antes de pushear.

`docs/onboarding/05-testing-strategy.md` enumera esto explícitamente como gap (paso 1 del CI Roadmap). El issue companion `INF-INFRA-00001` resuelve la pieza de backend; este lo cierra para frontend.

## Expected Behavior

- `<repo-root>/.github/workflows/frontend-ci.yml` existe y se dispara por:
  - `pull_request` con `paths: ["frontend/**", ".github/workflows/frontend-ci.yml"]`.
  - `push` a `main` con los mismos paths.
- Versiones de tooling tomadas de `mise.toml` (single source of truth: deno 2.x). El job NO declara la versión de deno hardcodeada — la lee con `mise install` o usando `jdx/mise-action@v2`.
- Jobs propuestos (decididos durante implementación, posiblemente unificados o split por velocidad):
  1. **`typecheck`** — `deno task build` o `deno run -A npm:typescript --noEmit` (decidir si separar `tsc` puro del bundle build).
  2. **`unit`** — `deno task test:coverage`; sube reporte de coverage como artifact; falla si < 80% sobre `src/` (la config ya lo enforza vía `vitest.config.ts`).
  3. **`build`** — `deno task build`; sube `dist/` como artifact (útil para inspección manual).
  4. **`e2e`** — `deno task test:e2e:install` (con cache de browsers de Playwright) + `deno task test:e2e` (Chromium por default; Firefox/WebKit no se corren en CI según `frontend/TESTING.md`). Sube reporte HTML de Playwright como artifact en falla.
- `working-directory: frontend` aplicado por `defaults.run` o por step.
- Cache:
  - Deno cache (`~/.cache/deno`).
  - `frontend/node_modules` (Deno con `nodeModulesDir: auto`).
  - Browsers de Playwright (`~/.cache/ms-playwright`) keyed por la versión de `@playwright/test` que aparece en `frontend/deno.json`.
- En PRs que solo tocan `backend/**`, `docs/**` o `.gdsi-sdlc/**`, el workflow no corre.
- Decisión documentada sobre paralelización: unit + build + typecheck en paralelo; E2E en job separado dependiente del build.
- Si E2E falla, el reporte HTML queda accesible para descargar desde la pestaña de Actions.

## Current Behavior

- `<repo-root>/.github/workflows/` solo contiene `release-please.yml`.
- No hay automatización de Vitest ni Playwright; `deno task test:run` y `deno task test:e2e` solo corren localmente.
- `tsc --strict` solo se valida cuando alguien hace `deno task build` localmente.
- El smoke E2E (`frontend/e2e/smoke.spec.ts`) y los specs de Vitest (`frontend/src/App.test.tsx`) viven en el repo pero su valor protector es nulo en CI.

## Reproduction Steps

1. Abrir un PR que rompa intencionalmente `frontend/src/App.tsx` (p. ej. romper un type, eliminar un test que pasa).
2. Observar la lista de checks del PR: solo aparece `release-please` (si aplica).
3. Mergear el PR — la regresión llega a `main` sin alertas.

## Impact

- **Calidad**: regresiones en frontend se filtran a `main` sin barrera automatizada.
- **Confianza para refactors**: el plan de descomponer `App.tsx` (~620 LOC) cuando aparezca una segunda ruta requiere CI verde como red de seguridad.
- **Onboarding**: nuevos colaboradores no reciben feedback inmediato del estado de su PR.
- **Coverage gate**: el target ≥ 80% configurado en `vitest.config.ts` no aporta nada hoy porque nadie lo verifica en PR.
- **E2E budget**: Playwright tarda — necesita cache bien configurado o cada PR del frontend agregará ~2-3 min al ciclo (de ahí la importancia del filtro `paths:`).

## Technical Notes

- **Toolchain**: el proyecto usa `mise` para pinear versiones (`mise.toml` declara `deno`). Recomendación: usar `jdx/mise-action@v2` para activar el toolchain con la misma versión que devs locales, evitando drift entre `setup-deno@v2` hardcodeado y `mise.toml`.
- **Deno tasks** (de `frontend/deno.json`):
  - `test:run` — `deno run -A npm:vitest run`
  - `test:coverage` — `deno run -A npm:vitest run --coverage`
  - `test:e2e:install` — `deno run -A npm:playwright install --with-deps`
  - `test:e2e` — `deno run -A npm:@playwright/test test --project=chromium`
  - `build` — `deno run ... npm:vite build`
- **Playwright en Deno**: la config (`frontend/playwright.config.ts`) ya tiene `retries: 2` y `workers: 1` cuando `process.env.CI`. Los browsers se descargan con `--with-deps` (incluye libs del sistema necesarias en ubuntu-latest). Cache key debe incluir la versión exacta de `@playwright/test` para invalidar al actualizar.
- **Coverage**: `vitest.config.ts` configura v8 + thresholds. El job de unit debe correr con `--coverage` para subir el reporte; la falla por threshold viene de Vitest, no del workflow.
- **`vite preview` port**: Playwright levanta su propio webServer (`deno task build && deno task preview --port 4173`). En CI, `webServer.reuseExistingServer = false` (Playwright lo maneja). No hace falta exponer el puerto en el workflow.
- **TS check**: `deno task build` ya hace type-check (Vite usa `tsc` vía plugin). Si se quiere un `tsc --noEmit` separado y rápido, agregar una task `typecheck` en `deno.json`. Decisión: dejarlo dentro de `build` por simplicidad, salvo que el feedback time crezca.
- **Filtro paths sintaxis**:

  ```yaml
  on:
    pull_request:
      paths:
        - "frontend/**"
        - ".github/workflows/frontend-ci.yml"
    push:
      branches: [ main ]
      paths:
        - "frontend/**"
        - ".github/workflows/frontend-ci.yml"
  ```

- **Naming**: usar `name: Frontend CI` (no `CI` a secas) para complementar `Backend CI` propuesto en `INF-INFRA-00001`.
- **Branch protection**: una vez que el workflow esté verde 2-3 PRs seguidos, considerar marcar `Frontend CI / unit` y `Frontend CI / build` como required checks. E2E NO debería ser required al inicio (recomendación de `docs/onboarding/05-testing-strategy.md`: "Don't gate every PR on E2E from day one").
- **Concurrency**: agregar `concurrency: { group: frontend-ci-${{ github.ref }}, cancel-in-progress: true }` para cancelar runs viejos cuando se pushea un fixup al PR.

## Origin

Manual — solicitado por el owner del repo: "Add a frontend CI workflow (Vitest + vite build, Playwright)".

## Related

- Issue dependiente / hermano: `INF-INFRA-00001` (mover workflows a la raíz con filtros por paths) — establece el patrón que este issue replica para frontend. Idealmente se mergea primero o en el mismo PR para mantener consistencia.
- Documento relacionado: `docs/onboarding/05-testing-strategy.md` — sección "CI Roadmap" paso 1 ("Add a test workflow"). Este issue cierra la mitad frontend de ese paso.
- Documento relacionado: `frontend/TESTING.md` — modus operandi de las dos capas de test que este pipeline ejecuta.
- Paths involucrados: `<repo-root>/.github/workflows/frontend-ci.yml` (nuevo), `frontend/deno.json`, `frontend/playwright.config.ts`, `frontend/vitest.config.ts`, `mise.toml`.

## Acceptance Criteria

- [ ] `<repo-root>/.github/workflows/frontend-ci.yml` existe con `name: Frontend CI`.
- [ ] Triggers: `pull_request` y `push` a `main`, ambos con `paths: ["frontend/**", ".github/workflows/frontend-ci.yml"]`.
- [ ] `defaults.run.working-directory: frontend` (o equivalente por step).
- [ ] Toolchain activado vía `jdx/mise-action@v2` (o `denoland/setup-deno@v2` si se descarta `mise` por algún motivo, dejando registrado por qué en el PR).
- [ ] Job `unit` corre `deno task test:coverage`. El coverage v8 reporta y falla si baja del threshold configurado en `vitest.config.ts` (≥ 80% sobre `src/`).
- [ ] Job `build` corre `deno task build`; el output `frontend/dist` se sube como artifact con retención corta (≤ 7 días).
- [ ] Job `e2e` corre `deno task test:e2e:install` + `deno task test:e2e` (Chromium). Reporte HTML de Playwright se sube como artifact en falla.
- [ ] Cache configurado para: Deno (`~/.cache/deno`), Playwright browsers (`~/.cache/ms-playwright`, key incluyendo versión de `@playwright/test`), y opcionalmente `frontend/node_modules`.
- [ ] `concurrency` group por `${{ github.ref }}` con `cancel-in-progress: true`.
- [ ] Verificación en un PR de prueba: el workflow corre sobre cambios en `frontend/**` y NO corre sobre cambios en `backend/**`, `docs/**` o `.gdsi-sdlc/**`.
- [ ] Cross-browser E2E (Firefox/WebKit) NO se corre por default en este workflow (queda como opt-in manual via `workflow_dispatch` o un workflow separado, según se decida).
- [ ] `docs/onboarding/05-testing-strategy.md` actualizado: paso 1 del CI Roadmap marcado como hecho cuando este issue + `INF-INFRA-00001` estén ambos cerrados.
- [ ] Conventional Commits respetados: `ci(frontend): add Vitest + build + Playwright workflow` o similar.
