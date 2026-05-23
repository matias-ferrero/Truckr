---
tag: INF-FE-00002
title: Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y
  env files)
priority: P2
status: done
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/209
author: Claude Code
github_issue: 209
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtlAHg
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-22T23:12:40.705771+00:00Z
labels:
- correction
- INF
- FE
plan: docs/features/INF/INF-FE-00002/INF-FE-00002-actualizar-frontend-gitignore.plan.md
---

## Summary

Hardenear `frontend/.gitignore` para que cubra los artefactos típicos de un proyecto Vite + TypeScript + Deno + Playwright. Hoy aparecen como cambios sin trackear `frontend/.vite/deps_temp_<hash>/` (cache de pre-bundling de Vite), y faltan reglas estándar para archivos de entorno (`.env*`, `*.local`), incrementales de TS (`*.tsbuildinfo`) y caches de tooling, lo que abre la puerta a commits accidentales (incluyendo secretos en `.env*`).

## Problem Statement

`frontend/.gitignore` (formato actual, 35 líneas) cubre lo básico (`dist/`, `node_modules/`, logs, `.vscode/*` con excepciones, `.idea`, `deno.lock`, `coverage/`, reportes de Playwright) pero no contempla:

1. **`.vite/`** — directorio que Vite genera automáticamente para el cache de dependencias optimizadas. En este repo se vio `frontend/.vite/deps_temp_d48254a8/package.json` apareciendo como untracked tras correr el dev server. Estos archivos NUNCA deben commitearse: cambian con cada arranque de Vite y son específicos de la máquina.
2. **Archivos de entorno** — `.env`, `.env.local`, `.env.*.local`, `.env.development.local`, `.env.production.local`. Riesgo concreto de filtrar secretos cuando aparezcan (hoy no existen, pero se van a necesitar para apuntar al backend en distintos entornos).
3. **`*.local`** — convención general de Vite/Node para overrides locales (config personal, scripts dev). Vite lo recomienda en su template oficial.
4. **`*.tsbuildinfo`** — output incremental de `tsc` (`tsconfig.json` con `"incremental": true` o flags equivalentes). Aparece en builds locales y polluta diffs.
5. **Caches de tooling** — `.eslintcache`, `.stylelintcache`, `.cache/`, `.parcel-cache/`, `.turbo/`. Aunque hoy no se usen todos, agregarlos es preventivo y barato.
6. **`tmp/` / `temp/`** — directorios temporales que algunos scripts generan.
7. **`.deno/`** — cache local de Deno cuando se configura `nodeModulesDir` con paths relativos.
8. **`*.pid`, `*.seed`, `*.pid.lock`, `.npm/`, `.yarn/`** — artefactos npm/yarn que pueden aparecer aunque el proyecto use Deno (interoperabilidad con `npm:` specifiers).

El template oficial que `npm create vite@latest` genera para React+TS hoy incluye explícitamente `.vite/` y todas las variantes de `.env*` — el `.gitignore` actual quedó por detrás de ese baseline.

## Expected Behavior

`frontend/.gitignore` cubre los siguientes grupos (ordenados y con headers tipo el archivo actual):

- **Vite**: `dist/`, `dist-ssr/`, `.vite/`, `*.local`.
- **TypeScript**: `*.tsbuildinfo`.
- **Dependencies**: `node_modules/`, `.pnp/`, `.pnp.js`, `.npm/`, `.yarn/cache/`, `.yarn/install-state.gz`.
- **Environment**: `.env`, `.env.local`, `.env.development.local`, `.env.test.local`, `.env.production.local`, `.env.*.local`. Con excepción explícita de `.env.example` (`!.env.example`) si se decide commitearlo.
- **Logs**: las entradas actuales (`*.log`, `npm-debug.log*`, `yarn-*`, `pnpm-debug.log*`, `lerna-debug.log*`).
- **Tooling caches**: `.eslintcache`, `.stylelintcache`, `.cache/`, `.parcel-cache/`, `.turbo/`.
- **Editor**: las entradas actuales (`.vscode/*` con `!.vscode/extensions.json`, `.idea`, `.DS_Store`, `*.suo`, `*.ntvs*`, `*.njsproj`, `*.sln`, `*.sw?`).
- **Deno**: `deno.lock` (decisión actual del repo — preservar), `.deno/`.
- **Test outputs**: `coverage/`, `playwright-report/`, `test-results/`, `.playwright/`, `blob-report/` (Playwright sharded reports).
- **Misc**: `tmp/`, `temp/`, `*.pid`, `*.seed`, `*.pid.lock`, `*.tgz`.

Tras la actualización:

- `git status` en una checkout limpia con dev server arrancado no muestra archivos en `frontend/.vite/`.
- Cualquier `.env*` (excepto `.env.example` si se introduce) queda automáticamente ignorado.
- El archivo está organizado por secciones con headers (`# Vite`, `# Environment`, etc.) coherentes con el formato existente.

## Current Behavior

Contenido actual de `frontend/.gitignore` (35 líneas):

```gitignore
# Vite
dist/
dist-ssr/

# Dependencies
node_modules/

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Deno
deno.lock

# Test outputs
coverage/
playwright-report/
test-results/
.playwright/
```

No cubre `.vite/`, ningún `.env*`, `*.local`, `*.tsbuildinfo`, ni caches de tooling.

## Reproduction Steps

1. Desde una checkout limpia: `cd frontend && deno task dev`.
2. Esperar a que Vite haga pre-bundling de deps.
3. Ctrl-C y volver a la raíz del repo.
4. `git status` muestra `frontend/.vite/deps_temp_<hash>/` como untracked.
5. Si alguien ejecuta `git add frontend/` o `git add .` sin revisar, esos archivos terminan trackeados.

Reproducción adicional para `.env`:

1. Crear `frontend/.env.local` con `VITE_API_BASE_URL=http://localhost:3000` (escenario realista cuando se conecte la app al backend).
2. `git status` lo lista como untracked — riesgo de commitear secretos.

## Impact

- **Higiene del repo**: archivos volátiles (`.vite/`) podrían terminar commiteados, generando ruido en diffs y conflictos de merge sin razón.
- **Seguridad**: cuando se introduzcan secretos vía `.env*` (inevitable al conectar con backend, eventualmente con keys de Maps/ARCA/MercadoPago), el `.gitignore` actual NO los protege. Esto es el mayor riesgo del bug.
- **DX**: `git status` "sucio" después de cada `deno task dev` enseña a los desarrolladores a ignorar los untracked, lo cual es exactamente cuando algo importante (un archivo nuevo legítimo) se pierde.
- **CI**: el workflow planeado en `INF-INFRA-00002` corre `deno task test:e2e`, que genera `playwright-report/`, `test-results/`, y arranca un Vite preview server. Ya cubierto, pero la categoría `*.tsbuildinfo` puede aparecer en el cache job si se activa `incremental` en `tsconfig`.

## Technical Notes

- **Referencia industrial**: el template oficial generado por `npm create vite@latest <name> -- --template react-ts` incluye `.vite/`, `.env*` y `*.local`. Comparar con ese baseline es la forma más rápida de validar el resultado.
- **`deno.lock`**: el repo lo tiene gitignoreado actualmente. Esto contradice la recomendación general de Deno (commitear `deno.lock` para reproducibilidad). NO cambiar como parte de este issue — si se quiere revisitar, abrir un issue separado con su propio análisis (impacto en CI, en `mise.toml`, en `INF-INFRA-00002`).
- **`.env.example`**: si en algún momento se introduce un `.env.example` con placeholders no sensibles, asegurarse de excluirlo de la regla con `!.env.example` (ya contemplado en el expected behavior).
- **Negaciones**: el `.gitignore` actual ya usa el patrón `.vscode/*` + `!.vscode/extensions.json`. Mantener esa convención cuando se agreguen nuevas excepciones.
- **Orden importa**: en `.gitignore`, una negación (`!pattern`) debe ir DESPUÉS del pattern que ignora. Validar el orden tras editar.
- **Verificación**: usar `git check-ignore -v <path>` para auditar qué regla matchea un path dado. Útil para confirmar que `.vite/deps_temp_xxx/package.json` queda ignorado tras el cambio.
- **No tocar root `.gitignore`**: el archivo de la raíz está generado por toptal/gitignore.io para visualstudiocode/linux/python y no aplica a frontend. Mantener separación de scopes.
- **Limpieza retroactiva**: tras editar `frontend/.gitignore`, los archivos de `.vite/` que ya estén untracked desaparecerán de `git status` automáticamente. Si alguno hubiera sido commiteado por error en el pasado (verificar con `git log --all --full-history -- 'frontend/.vite/**'`), removerlo en el mismo PR con `git rm -r --cached frontend/.vite`.

## Origin

Manual — el owner del repo notó `frontend/.vite/deps_temp_d48254a8/package.json` apareciendo como cambio no trackeado y pidió revisar el `.gitignore` del frontend contra estándares industriales.

## Related

- Path principal: `frontend/.gitignore`.
- Referencia: template oficial Vite + React + TS (`npm create vite@latest -- --template react-ts`).
- Issue relacionado: `INF-INFRA-00002` (Frontend CI) — comparte el área `frontend/` y se beneficia de un `.gitignore` correcto para que los artifacts de CI (coverage, playwright reports) no se mezclen con archivos legítimos.
- Documento relacionado: `docs/onboarding/03-module-reference.md` — describe la estructura `frontend/` que este issue limpia.

## Acceptance Criteria

- [ ] `frontend/.gitignore` ignora `.vite/` (verificable con `git check-ignore -v frontend/.vite/deps_temp_xxx/package.json`).
- [ ] `frontend/.gitignore` ignora `.env`, `.env.local`, `.env.*.local`, y todas las variantes de entornos estándar (development, test, production), preservando la posibilidad de commitear `.env.example` con `!.env.example`.
- [ ] `frontend/.gitignore` ignora `*.local` y `*.tsbuildinfo`.
- [ ] `frontend/.gitignore` incluye categorías para tooling caches comunes: `.eslintcache`, `.stylelintcache`, `.cache/`, `.parcel-cache/`, `.turbo/`.
- [ ] `frontend/.gitignore` incluye `blob-report/` (Playwright sharded reports) además de los outputs ya cubiertos.
- [ ] `frontend/.gitignore` está organizado por secciones con headers claros, manteniendo la convención existente.
- [ ] Tras el cambio, `git status` en una checkout limpia con `deno task dev` corrido al menos una vez NO muestra archivos en `frontend/.vite/`.
- [ ] Si existieran archivos de `.vite/` o equivalentes ya trackeados en historia (verificar con `git log --all --full-history -- 'frontend/.vite/**'`), se remueven con `git rm -r --cached` en el mismo PR.
- [ ] `deno.lock` permanece gitignoreado (no cambia en este issue — decisión separada).
- [ ] Conventional Commits: `chore(frontend): harden .gitignore with vite cache, env files, and tooling caches` o similar (`chore` o `fix` aceptables; NO `feat`).
- [ ] PR describe el delta y referencia el template oficial de Vite como baseline.
