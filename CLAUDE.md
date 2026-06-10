# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project context

FIUBA **GDSI** (Gestión del Desarrollo de Sistemas Informáticos) coursework for **Truckr®**, a transportation services marketplace connecting independent transporters with clients. Greenfield project: most of the repository is planning/architecture documentation in Typst; a Rails `backend/` and a React+Deno `frontend/` were recently scaffolded but development has not started.

All written content (artifacts, user stories, prompts) is in **Spanish (es-AR)**. Code, identifiers, and commit messages are in English.

## Terminology

**Source of truth: [`docs/05-appendices/glossary.md`](docs/05-appendices/glossary.md).** Whenever a term is introduced, renamed, or deprecated, update the glossary first and propagate from there. Personas / models in particular: `Transportista` ↔ `Carrier`, `Expedidor` ↔ `Shipper`. The terms `Cliente` / `Productor` are deprecated synonyms folded into `Expedidor`.

## Database policy (UTMOST importance)

**SQLite is the production database — forever.** This product is academic coursework and will not be brought to market; there is no Phase-2 migration, no scalability cutover, no "when we grow" PostgreSQL plan. Treat SQLite as a permanent architectural constraint, not a temporary one.

**Hard rules:**

| Surface | Rule |
|---|---|
| Schema | Stays portable to SQLite. No `citext`, no partial indexes that require Postgres-only syntax, no `EXCLUDE` constraints, no array columns, no `jsonb`. |
| Indexes | B-tree only. No GIN / GIST / spatial indexes. |
| Geo | Lat/lng as `DECIMAL(9,6)` columns on the relevant tables. "Within N km" queries use Haversine in application code or an external API call — never PostGIS. |
| Search | Diacritic-insensitive matching uses `I18n.transliterate` on a stored normalized column. Never `unaccent`, never a Postgres-only extension. |
| Concurrency | Race-safety is handled at the application layer. Don't write "Phase-2 EXCLUDE constraint" comments — solve it on SQLite or accept the race for the MVP. |
| ADRs / planning | Don't write "Phase 2 → Postgres" / "when we migrate" / "for future Postgres" framing. Solve the problem on SQLite or document the limitation as final. |
| Cost / infra docs | No RDS line. No managed-Postgres line. Deploy is Kamal + single container with SQLite on the local volume. |

**Why:** Stated 2026-05-11. Speculative Postgres baggage in code and docs creates phantom deferred work, biases solutions toward features that aren't actually reachable on the current stack, and pollutes ADRs with "still pending" decisions that will never be revisited. Reject it at review.

**If you encounter pre-existing Postgres-baggage references** in already-merged code or docs (e.g. `transport_window.rb` Phase-2 PostGIS comment, `cost-report.typ` RDS line, `domain-model.md` `citext` note, historical plan files): leave historical plan files alone, but call them out for cleanup in the next docs sweep. Don't write new ones.

## Language policy (UTMOST importance)

**All code and routes are ENGLISH. UI text and error messages are internationalized — NEVER hardcoded literals.** This is non-negotiable. PRs that add Spanish in code surfaces are blocked at review.

| Surface | Rule | Example ✅ | Example ❌ |
|---|---|---|---|
| Backend routes | English path segments | `/api/carriers/me/vehicles` | `/api/transportistas/me/vehiculos` |
| Frontend routes | English path segments | `/carrier/vehicle`, `/carrier/vehicles` | `/transportista/vehiculo`, `/transportista/vehiculos` |
| Models / tables / columns | English | `Carrier`, `vehicles.max_load_kg` | `Transportista`, `vehiculos.peso_maximo` |
| Controllers / files / params | English | `VehiclesController`, `vehicle[plate]` | `VehiculosController`, `vehiculo[patente]` |
| JSON keys | English snake_case | `{ "max_load_kg": ... }` | `{ "peso_maximo": ... }` |
| **UI copy** in components | Via translation key | `<h1>{t('vehicle.list.title')}</h1>` | `<h1>Mis vehículos</h1>` |
| **Error messages** in controllers | Via `I18n.t(...)` | `I18n.t('errors.unauthorized')` | `"Autenticación requerida"` |
| **Validation messages** on AR models | Symbolic key (resolved via `config/locales/*.yml`) | `errors.add(:plate, :invalid_format)` | `errors.add(:plate, "patente inválida")` |

**Carve-outs (Spanish allowed):**
- Product artifacts under `docs/artifacts/`, user/job stories, prompts under `docs/prompts/` and `docs/raw/`, issue titles, README copy aimed at humans. Cargo-cult-friendly: docs are deliverables, code is implementation.
- `frontend/src/landingContent.ts` is *content data* (not hardcoded UI labels) and acts as the prototype-stage i18n bundle until a real i18n library lands. New JSX copy must wait for that library or extend `landingContent.ts`.

**Workflow:** add the term to [`docs/05-appendices/glossary.md`](docs/05-appendices/glossary.md) first, then derive the English identifier *and* the Spanish i18n value from it.

## Tooling (managed by mise)

`mise install` provisions everything: `typst`, `typstyle`, `uv`, `gh`, `prek`, `just`, `deno`, `ruby 3.4`. After install, run `prek install` once to wire pre-commit hooks into `.git/hooks/`.

## Build commands

All build tasks live in `justfile` and operate on `docs/` (the `root := "docs"` variable scopes Typst's `--root`). Run `just` to list recipes.

```sh
just build                    # everything (artifacts + chat sessions)
just build-artifacts          # full artifacts report → docs/artifacts/main.pdf
just build-artifact <name>    # single artifact, e.g. `just build-artifact wbs`
just watch-artifact <name>    # live-reload a single artifact
just build-chats              # convert raw JSON chats → .typ then compile
just convert-chats            # JSON → .typ only (no compile)
just fmt                      # typstyle on all .typ files
just lint                     # all pre-commit hooks
just clean                    # delete generated PDFs under docs/
```

Typst compile invocations always pass `--root docs` so `#import "../template.typ"` resolves correctly. New artifacts must follow the same import pattern (`#import "../template.typ": conf` then `#show: conf`).

## Parallel worktrees & dev-server ports (UTMOST importance)

Multiple worktrees can run their dev servers **at the same time**, so nothing may hardcode the default ports (Rails `:3000`, Vite `:5173`) when booting a worktree. Two worktrees both binding `:3000`/`:5173` collide and the second silently fails or steals the first one's traffic.

**The reusable allocator lives in [`script/review-worktree.sh`](script/review-worktree.sh) — `pick_free_port lo hi`.** It reads the actual `LISTEN` set via `ss -Hltn` and returns a *random* free port in range (random, not lowest-free, so two sessions booted back-to-back don't race for the same port). `just review <name>` already uses it to pick a backend port (3001–3999) and a frontend port (5174–5999) per session. **Any other helper that boots a worktree's servers (including anything `/worktree` runs) must reuse `pick_free_port` — do not reinvent port selection or fall back to the defaults.**

Once ports are chosen, four wiring points must follow them (all already handled by `just review`; replicate them anywhere else):

| Knob | Where | Purpose |
|---|---|---|
| `PORT=<be>` | backend process env | foreman/Puma bind (`Procfile.dev` + `bin/dev` read `${PORT:-3000}`) |
| `FRONTEND_ORIGIN=http://localhost:<fe>,http://127.0.0.1:<fe>` | backend process env | scopes CORS (`config/initializers/cors.rb`) **and** the ActiveAdmin impersonation redirect (`app/admin/users.rb`) to this session's SPA |
| `VITE_API_BASE_URL=http://localhost:<be>` | frontend process env | points the SPA at this session's backend instead of `:3000` |
| `--port <fe> --strictPort` | `deno task dev` args | binds Vite to the chosen port and fails loudly instead of drifting |

Action Cable's dev allowlist already accepts any `localhost:<port>` / `127.0.0.1:<port>` (`config/environments/development.rb`), so no per-port wiring is needed there. Caveat: `just review main` targets the **root clone** and shares its single `storage/development.sqlite3`; distinct worktrees each get their own DB and are fully independent.

## Architecture

### `docs/` — planning artifacts (the bulk of the repo)

- **`docs/template.typ`** — shared Typst config (lang `"es"`, 10pt, 2cm margins, justified). Every artifact imports `conf` from here.
- **`docs/artifacts/`** — individual planning artifacts (`wbs.typ`, `personas.typ`, `usm.typ`, `features.typ`, `cost-report.typ`, etc.). `main.typ` includes them all into one report.
- **`docs/00-platform-architecture/` … `docs/05-appendices/`** — numbered architecture sections (technical vision, HLD, architecture & DB diagrams, appendices). These are sections of the deliverable, not application code modules.
- **`docs/raw/`** — raw chat session JSON exports.
- **`docs/scripts/chat_json2typ.py`** — converts those JSON exports into `docs/prompts/chat-*.typ` files; `docs/prompts/main.typ` aggregates them. Re-run via `just convert-chats` after adding a new export to `docs/raw/`.
- Special chars in Typst data must be escaped: `\"`, `\#`, `\$`, `\@`, `\\`.

### `backend/` and `frontend/` — scaffolded apps

Rails (`backend/`) and React + Deno + Vite + TypeScript (`frontend/`, dev server on `:5173`, run via `deno task dev|build|preview`). Treat both as greenfield: minimal structure, no real implementation yet. Issues are not scoped per-component — a documentation-only change typically gets a single TAG.

## Document conventions

- User stories: `Como X quiero Y para Z` with numbered acceptance criteria.
- USM (User Story Map) is hierarchical: Epic → Activity → Task Group → MVP / Post-MVP.
- Feature matrices score personas × features on a 1–5 scale.
- typstyle auto-formats on commit — let it.

## Pre-PR UI quality gate (UTMOST importance)

CI on this repo is **expensive** — it builds Typst PDFs, runs frontend Vitest + Playwright, and runs the full Rails RSpec suite on every push to a PR. Treat opening a PR as a costly action: get it right locally first.

**Before opening any PR that touches the frontend (new component, new screen, new UI element, restyle, or copy change), run the [impeccable](https://github.com/anthropic-experimental/impeccable) skills against the changed files, in this order:**

| Step | Slash command | Purpose |
|---|---|---|
| 1 | `/critique` | Surface design, IA, and UX problems before they harden. Acts as a design review. |
| 2 | `/polish` | Apply spacing, typography, alignment, and visual-rhythm fixes. |
| 3 | `/audit` | Final pass — accessibility (a11y), semantic HTML, contrast, focus states, keyboard nav. Blocks merge if findings remain. |

These are real installed skills (impeccable plugin). Invoke them with the slash syntax in your Claude Code session and address the findings — don't just ask for a report and move on. If a finding is intentional, note it inline in the PR description.

**Then, before pushing the branch and opening the PR:**

1. `just lint` — pre-commit hooks (typstyle, formatting, **stylelint design-system enforcement**, basic checks). Must be clean. (Note: the recipe shells out to `pre-commit`; if only `prek` is on PATH via mise, run `prek run --all-files` directly.) The `stylelint` hook is the machine-enforced version of DESIGN.md's absolute bans — no raw `#000`/`#fff`/`white`/`black`/`rgb*`, no `border-left|right > 1px` side-stripes, no `background-clip: text` gradient-text — scoped to `frontend/src/**/*.css`. Token-source files (`global.css`, `landing.css`, `tailwind.css`) are exempted so the five brand source hexes stay declarative. To run standalone: `just frontend-lint-css`.
2. `just frontend-test-coverage` — Vitest with v8 coverage. **Hard threshold: 80% lines / functions / branches / statements** (configured in `frontend/vitest.config.ts`). The command exits non-zero if any threshold is missed; do not open the PR until it passes.
3. `just frontend-test-e2e` — Playwright (chromium). New UI elements must have an E2E spec covering the golden path; run e2e before pushing.
4. `just backend-test` — RSpec, if the branch touches `backend/`. SimpleCov reports under `backend/coverage/`; maintain or improve the existing coverage percentage.
5. `just build-artifacts` — only if the branch touches `docs/`. PDF must compile cleanly.

**Hard rule:** if any of the above fails locally, fix it before opening the PR. Pushing a known-broken branch to burn CI minutes for diagnosis is wasteful — reproduce locally instead. The same goes for `gh pr create`: don't open a PR you haven't run the quality gate against.

**Carve-outs:** typo-only doc edits and pure planning-doc changes (`docs/artifacts/**`, `docs/raw/**`, `docs/prompts/**`) skip steps 1–4 but still need `just build-artifacts` and `just lint`.

## Releases

Automated via `release-please` + GitHub Actions, driven by **Conventional Commits** on `main`:

| Prefix              | Bump  |
|---------------------|-------|
| `fix:`              | patch |
| `feat:`             | minor |
| `feat!:` / BREAKING | major |
| `docs:` `chore:` `ci:` | none (rolled into next release) |

Merging the auto-generated Release PR creates a tagged GitHub Release; a follow-up workflow attaches `artifacts.pdf` and `prompts.pdf`. Config: `release-please-config.json`, `.release-please-manifest.json`.

### PR title format (squash-merge consumed by release-please)

This repo squash-merges PRs. The squash commit subject is the PR title verbatim, and release-please parses that subject as a conventional commit. **The title MUST start with a conventional type** (`feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, etc.) — otherwise the parser drops the commit silently and no version bump happens.

- ✅ `feat(identity): add Carrier and Shipper models`
- ❌ `[REQ-BE-00020] feat(identity): add Carrier and Shipper models` — bracket prefix kills the parse

Reference the issue TAG in the **PR body** (`Closes #N` for auto-link) and in the **branch name** (`feature/REQ-BE-00020-...`), never in the title. The `.github/workflows/pr-title.yml` check enforces this on every PR.
