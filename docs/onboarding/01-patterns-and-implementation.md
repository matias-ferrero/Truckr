# Patterns & Implementation

The 10 patterns the codebase is built on. Anchored in `02-high-level-design/high-level-design.md`.

## 1. API-only Rails

- **Purpose**: strip session/cookies/flash/asset middleware; serve JSON only.
- **Where**: `config.api_only = true` in `backend/config/application.rb`; `ApplicationController < ActionController::API`.
- **Rule**: new endpoints go under `app/controllers/api/`, mounted in the `:api` namespace in `config/routes.rb`.

## 2. Resource-based routing

- **Purpose**: predictable REST URLs.
- **Where**: `resources :landing_pages, only: [:index]` inside the `:api` namespace.
- **Rule**: restrict verbs explicitly with `only:` / `except:`. Never expose all seven actions unless intended.

## 3. Health check at `/up`

- **Purpose**: load-balancer liveness probe. Maps to `rails/health#show`.
- **Rule**: zero business logic. Cheap, dependency-free, public.

## 4. CORS via explicit allow-list

- **Purpose**: let the Vite dev server (`localhost:5173`) call the Rails API (`localhost:3000`).
- **Where**: `rack-cors` middleware at position 0 in `backend/config/initializers/cors.rb`.
- **Rule**: prod origins must be added explicitly. **Never `"*"` in production.**

## 5. Solid* stack (DB-backed infra)

- **Purpose**: avoid Redis/Memcached.
- **Where**: `solid_cache`, `solid_queue`, `solid_cable` gems + dedicated SQLite DBs in `config/database.yml` under `production` (`cache`, `queue`, `cable` entries).
- **Rule**: jobs go in `backend/app/jobs/`, inherit `ApplicationJob`. Use `Rails.cache` for caching. Don't pull in a third-party broker without an ADR.

## 6. Client-side data-fetching with schema validation

- **Purpose**: defend the UI from backend shape drift without code-generated clients.
- **Where**: `isLandingData()` type guard in `frontend/src/App.tsx` validates JSON before `setData()`.
- **Rule**: every `fetch()` must (a) check `response.ok`, (b) parse as `unknown`, (c) narrow via a type guard.

## 7. Theme via CSS variables

- **Purpose**: brand palette comes from the API (`color_palette` key), so non-technical editing is possible.
- **Where**: `themeVars` memo in `App.tsx` writes `--brand-*` custom properties on the root.
- **Rule**: components read `var(--brand-primary)` etc. Never hardcode palette hexes in component CSS.

## 8. Document-as-code

- **Purpose**: academic deliverables are versioned, diffable, reproducible.
- **Where**: `.typ` source under `docs/artifacts/` and `docs/prompts/`; Python under `docs/scripts/` converts inputs to `.typ`; `justfile` orchestrates.
- **Rule**: don't hand-edit generated artifacts (e.g. `backlog-us.typ`). Edit the source data and re-run `just`.

## 9. Automated release with attached PDFs

- **Purpose**: every release ships the compiled academic report.
- **Where**: `.github/workflows/release-please.yml` — release-please opens the Release PR; on `release_created`, Typst compiles `artifacts.pdf` + `prompts.pdf` and `softprops/action-gh-release@v2` attaches them.
- **Rule**: PDFs are generated. Never commit them.

## 10. AI harness as a development pattern

- **Purpose**: keep AI-agent context and conventions versioned alongside code.
- **Where**:
  - `.agents/skills/` — repo-wide product skills (`user-stories`, `job-stories`, `task-planning`).
  - `frontend/.agents/skills/` — design skills (`impeccable`, `critique`, `polish`, `audit`, `animate`, `layout`, …).
  - `frontend/.claude/skills/` — symlinks for Claude Code discovery.
  - `CLAUDE.md` — project conventions.
  - `frontend/.impeccable.md` — design north-star.
  - `.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}/` — file-backed Kanban.
- **Rule**: a backlog item progresses by moving its `.issue.md` file between status folders. New AI capability = a versioned skill, not a chat convention. See `04-ai-harness.md`.

## API Conventions Snapshot

| Aspect | Today |
|--------|-------|
| Style | REST/JSON. No GraphQL/gRPC. |
| Namespace | `/api/...` |
| Versioning | None yet. Move to `/api/v1/...` at first breaking change. |
| Key style | snake_case (Ruby native). Frontend reads snake_case directly. |
| Auth | None. All endpoints public. |
| Errors | No envelope yet. Recommended shape: `{ "error": { "code", "message", "details" } }`. |
| Dates | ISO-8601 UTC when added. |

## Background Job Conventions

- Inherit from `ApplicationJob`.
- Suffix with `Job` (`TrackingIngestJob`, `InvoiceEmissionJob`).
- Idempotent — solid_queue retries on failure.
- Pass record IDs, not AR objects, in `perform`.
- Log with `Rails.logger.tagged("job:job_name")`.
