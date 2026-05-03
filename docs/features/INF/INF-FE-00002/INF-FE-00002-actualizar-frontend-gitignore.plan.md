# INF-FE-00002: Actualizar frontend/.gitignore a estándares industriales

| Field | Value |
|-------|-------|
| **Tag** | INF-FE-00002 |
| **Title** | Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y env files) |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-03 |
| **Updated** | 2026-05-03 |
| **Author** | Claude Code |
| **Depends On** | None (independiente; coordinar idealmente con `INF-INFRA-00002` para evitar conflictos en `frontend/`) |
| **Decision Doc** | N/A |
| **Selected Approach** | N/A — solución única clara |

---

## 1. Problem Statement

`frontend/.gitignore` (35 líneas) cubre lo básico (`dist/`, `node_modules/`, logs, editores, `coverage/`, reportes Playwright) pero queda por detrás del baseline que Vite genera con `npm create vite@latest -- --template react-ts`. Faltan:

- `.vite/` (cache de pre-bundling) — reproducible: tras `deno task dev`, `git status` muestra `frontend/.vite/deps_temp_<hash>/package.json` como untracked.
- `.env*` y `*.local` — riesgo de filtrar secretos cuando se conecten variables al backend / servicios externos (Maps, ARCA, MercadoPago).
- `*.tsbuildinfo` — cache incremental de TS.
- Caches de tooling (`.eslintcache`, `.stylelintcache`, `.cache/`, `.parcel-cache/`, `.turbo/`).
- `blob-report/` — Playwright sharded reports.
- Misceláneos (`tmp/`, `temp/`, `*.pid`, `*.tgz`).

El issue completo vive en `.gdsi-sdlc/issues/Backlog/INF-FE-00002-actualizar-frontend-gitignore-a-estandares-industriales.issue.md`.

---

## 2. Solution Design

Reemplazar `frontend/.gitignore` por una versión que (a) preserve toda regla actual (no remover nada existente), (b) agregue las categorías faltantes en secciones nombradas, (c) respete el orden `pattern` antes de `!exception` para negaciones futuras (`.env.example`).

### Key Components

- **Baseline de referencia**: el `.gitignore` que Vite oficial genera para `react-ts`, ampliado con tooling caches comunes.
- **Patrón de organización**: secciones con headers `# <Nombre>` agrupando reglas por dominio (Vite, TypeScript, Dependencies, Environment, Logs, Tooling caches, Editor, Deno, Test outputs, Misc).
- **No alcance**:
  - NO modificar `.gitignore` de la raíz del repo (es generado por toptal/gitignore.io para vscode/linux/python; pertenece a otro scope).
  - NO cambiar la decisión sobre `deno.lock` (sigue gitignoreado; revisitar en issue separado si se desea).
  - NO crear `.env.example` (se prepara la regla `!.env.example` por si se introduce más adelante, pero no se commitea archivo nuevo).
- **Verificación**: usar `git check-ignore -v <path>` para auditar matches específicos, y `git status` antes/después de `deno task dev` para confirmar `.vite/` ignorado.
- **Limpieza retroactiva**: ejecutar `git log --all --full-history -- 'frontend/.vite/**' 'frontend/.env*' 'frontend/*.tsbuildinfo'` para verificar que ningún archivo quedó trackeado en historia. Si aparece alguno, agregar `git rm -r --cached <path>` en el mismo PR.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Crear branch `chore/frontend-gitignore-INF-FE-00002` desde `main` | Pending | — |
| 2 | Reescribir `frontend/.gitignore` con secciones completas | Pending | `frontend/.gitignore` |
| 3 | Verificar con `git check-ignore -v` que `.vite/`, `.env.local`, `*.tsbuildinfo`, `*.local` quedan ignorados | Pending | — |
| 4 | Verificar que `.env.example` NO queda ignorado (regla de negación funcional) creando un archivo temporal | Pending | — |
| 5 | Ejecutar `git log --all --full-history` sobre paths sospechosos; si aparece tracking previo, `git rm -r --cached` | Pending | — |
| 6 | Mover el `.issue.md` de `Backlog/` a `Ready/`, actualizar frontmatter (`status: ready`, `plan: <path>`) | Pending | `.gdsi-sdlc/issues/...` |
| 7 | Actualizar `docs/features/ISSUES-INDEX.md`: status `NEW` → `RDY`, agregar link al plan | Pending | `docs/features/ISSUES-INDEX.md` |
| 8 | Confirmar que `git status` en checkout limpia post `deno task dev` no muestra archivos en `.vite/` | Pending | — |
| 9 | Commit con `chore(frontend): harden .gitignore with vite cache, env files, and tooling caches` | Pending | — |
| 10 | Abrir PR con `--assignee @me`, descripción referenciando el baseline de Vite oficial | Pending | — |

---

## 4. Code Changes

### 4.1 File: `frontend/.gitignore`

**Purpose**: Hardenear el archivo para cubrir todos los artefactos de Vite, TS incremental, env files, y caches de tooling. Preservar toda regla actual; agregar categorías faltantes.

**Contenido propuesto** (versión completa de reemplazo, ~55 líneas):

```gitignore
# Vite
dist/
dist-ssr/
.vite/
*.local

# TypeScript
*.tsbuildinfo

# Dependencies
node_modules/
.pnp/
.pnp.js
.npm/
.yarn/cache/
.yarn/install-state.gz

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.env.*.local
!.env.example

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# Tooling caches
.eslintcache
.stylelintcache
.cache/
.parcel-cache/
.turbo/

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
.deno/

# Test outputs
coverage/
playwright-report/
blob-report/
test-results/
.playwright/

# Misc
tmp/
temp/
*.pid
*.seed
*.pid.lock
*.tgz
```

**Notas sobre el delta**:
- Preserva 100% de las reglas previas (Vite, Dependencies, Logs, Editor, Deno, Test outputs).
- Agrega: `.vite/`, `*.local`, `*.tsbuildinfo`, `.pnp/`, `.pnp.js`, `.npm/`, `.yarn/cache/`, `.yarn/install-state.gz`, `.env*` (5 variantes + wildcard + excepción), tooling caches (5), `.deno/`, `blob-report/`, misc (`tmp/`, `temp/`, `*.pid`, `*.seed`, `*.pid.lock`, `*.tgz`).
- Orden importa para `!.env.example`: la negación va DESPUÉS de `.env.*.local` para que Git la respete.

### 4.2 File: `.gdsi-sdlc/issues/Backlog/INF-FE-00002-...issue.md` → `.gdsi-sdlc/issues/Ready/...`

**Purpose**: Mover el issue al status Ready y registrar el plan.

**Cambios en frontmatter**:

```diff
 ---
 tag: INF-FE-00002
 title: Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y env files)
 priority: P2
-status: backlog
+status: ready
 created: '2026-05-03'
 source: manual
 author: Claude Code
+plan: docs/features/INF/INF-FE-00002/INF-FE-00002-actualizar-frontend-gitignore.plan.md
 labels:
 - INF
 - FE
 - hygiene
 - gitignore
 ---
```

### 4.3 File: `docs/features/ISSUES-INDEX.md`

**Purpose**: Reflejar status `RDY` y linkear el plan.

**Cambio**:

```diff
-| INF-FE-00002 | Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y env files) | NEW | FE | 2026-05-03 | - |
+| INF-FE-00002 | Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y env files) | RDY | FE | 2026-05-03 | [plan](INF/INF-FE-00002/INF-FE-00002-actualizar-frontend-gitignore.plan.md) |
```

---

## 5. Testing

No hay tests automatizados que aplique escribir para un cambio de `.gitignore`. La verificación es manual y determinística vía `git check-ignore`.

### Manual Verification (obligatorio antes del commit)

Cada item debe pasar:

```sh
# .vite/ ignorado
git check-ignore -v frontend/.vite/deps_temp_d48254a8/package.json
# → debe imprimir: frontend/.gitignore:LINE:.vite/

# env files ignorados
git check-ignore -v frontend/.env
git check-ignore -v frontend/.env.local
git check-ignore -v frontend/.env.production.local
git check-ignore -v frontend/.env.development.local

# .env.example NO ignorado (excepción funciona)
touch frontend/.env.example
git check-ignore -v frontend/.env.example
# → exit code 1 (no ignorado) — OK
rm frontend/.env.example

# *.local ignorado
git check-ignore -v frontend/foo.local

# *.tsbuildinfo ignorado
git check-ignore -v frontend/tsconfig.tsbuildinfo

# Tooling caches
git check-ignore -v frontend/.eslintcache
git check-ignore -v frontend/.cache/foo
git check-ignore -v frontend/.turbo/cache

# Test outputs (preservados)
git check-ignore -v frontend/coverage/lcov-report/index.html
git check-ignore -v frontend/playwright-report/index.html
git check-ignore -v frontend/blob-report/0.zip

# Editor (preservados)
git check-ignore -v frontend/.vscode/settings.json
git check-ignore -v frontend/.vscode/extensions.json
# → settings.json IGNORADO, extensions.json NO IGNORADO (negación intacta)
```

### Smoke E2E del cambio

```sh
cd frontend
deno task dev &       # arranca Vite, genera .vite/deps_*
sleep 3 && kill %1
cd ..
git status --short | grep '^??' | grep -v '^??' frontend/.vite || echo "OK — .vite/ ignorado"
```

### Auditoría de historia

```sh
git log --all --full-history -- 'frontend/.vite/**' 'frontend/.env*' 'frontend/*.tsbuildinfo'
# Si imprime commits → al menos un archivo está trackeado → agregar git rm -r --cached <path> en el PR
# Si vacío → OK
```

---

## 6. Acceptance Criteria

(Heredados del issue, traducidos a checks ejecutables)

- [ ] `git check-ignore -v frontend/.vite/deps_temp_xxx/package.json` matchea regla `.vite/`.
- [ ] `git check-ignore -v` matchea para: `.env`, `.env.local`, `.env.development.local`, `.env.test.local`, `.env.production.local`, una variante arbitraria `.env.foo.local`.
- [ ] `git check-ignore -v frontend/.env.example` retorna exit 1 (NO ignorado — excepción funcional).
- [ ] `git check-ignore -v` matchea para: `*.local`, `*.tsbuildinfo`, `.eslintcache`, `.stylelintcache`, `.cache/x`, `.parcel-cache/x`, `.turbo/x`, `blob-report/x`.
- [ ] `git check-ignore -v frontend/.vscode/extensions.json` retorna exit 1 (excepción preservada).
- [ ] `git check-ignore -v frontend/.vscode/settings.json` matchea regla `.vscode/*`.
- [ ] Tras `deno task dev`, `git status` no muestra archivos en `frontend/.vite/`.
- [ ] `git log --all --full-history` sobre paths sospechosos vacío, O bien archivos trackeados removidos vía `git rm -r --cached` en el mismo PR.
- [ ] `deno.lock` sigue gitignoreado (status quo preservado).
- [ ] Commit message Conventional: `chore(frontend): harden .gitignore with vite cache, env files, and tooling caches`.
- [ ] PR creado con `--assignee @me` y descripción referenciando el baseline oficial de Vite (`npm create vite@latest -- --template react-ts`).
- [ ] Issue movido `Backlog/` → `Ready/` (cuando se planea) y luego `Ready/` → `InProgress/` (cuando se implementa) — este último en `issues:implement`, no en este plan.

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `docs/features/INF/INF-FE-00002/INF-FE-00002-actualizar-frontend-gitignore.plan.md` | Este plan. |

### Modified Files

| File | Changes |
|------|---------|
| `frontend/.gitignore` | Reescritura completa: ~35 → ~55 líneas, agregando 9 categorías nuevas (.vite, TypeScript, Environment, Tooling caches, blob-report, .deno, Misc, .pnp/.npm/.yarn deps, .env exception). |
| `.gdsi-sdlc/issues/Backlog/INF-FE-00002-...issue.md` → `Ready/` | Movido + frontmatter `status: ready`, `plan: <path>`. |
| `docs/features/ISSUES-INDEX.md` | Status `NEW` → `RDY`, link al plan en columna Plan. |

### Out of Scope

| File | Reason |
|------|--------|
| `.gitignore` (root) | Generado por toptal/gitignore.io para vscode/linux/python; otro scope (`INFRA` o `GEN`). |
| `backend/.gitignore` | Rails genera el suyo; revisitar bajo `INF-BE-*` si hace falta. |
| `deno.lock` (re-evaluar commit vs ignore) | Status quo decidido fuera de este issue; abrir issue separado si se quiere revisitar. |
| `.env.example` (crear archivo) | El `.gitignore` deja la regla `!.env.example` lista, pero no se introduce un archivo nuevo en este issue. |

---

## Notes for Implementer

- **Branch desde `main` limpio**: `git stash` cualquier cambio actual antes de empezar, o crear branch desde un commit limpio. Hoy hay 3 issues untracked en `Backlog/` (este, `INF-INFRA-00001`, `INF-INFRA-00002`); NO mezclar en este PR.
- **Conflicto potencial con `INF-INFRA-00002`**: ambos tocan `frontend/`. Coordinar orden de merge. Recomendación: este primero (es trivial), luego CI workflow.
- **Mise en main**: NO pushear a `main` directamente. Usar branch + PR.
- **Verificación post-merge**: en una checkout fresca del default branch tras merge, repetir `deno task dev` + `git status` para confirmar que `.vite/` queda silenciado para todos.
