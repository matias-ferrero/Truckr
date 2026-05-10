# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project context

FIUBA **GDSI** (Gestión del Desarrollo de Sistemas Informáticos) coursework for **Truckr®**, a transportation services marketplace connecting independent transporters with clients. Greenfield project: most of the repository is planning/architecture documentation in Typst; a Rails `backend/` and a React+Deno `frontend/` were recently scaffolded but development has not started.

All written content (artifacts, user stories, prompts) is in **Spanish (es-AR)**. Code, identifiers, and commit messages are in English.

## Terminology

**Source of truth: [`docs/05-appendices/glossary.md`](docs/05-appendices/glossary.md).** Whenever a term is introduced, renamed, or deprecated, update the glossary first and propagate from there. Personas / models in particular: `Transportista` ↔ `Carrier`, `Expedidor` ↔ `Shipper`. The terms `Cliente` / `Productor` are deprecated synonyms folded into `Expedidor`.

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
