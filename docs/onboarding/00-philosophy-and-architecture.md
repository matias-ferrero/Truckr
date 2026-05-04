# Philosophy & Architecture

## What Truckr® Is

Truckr® is a two-sided **transportation marketplace** for Argentina that connects independent truck owners ("transportistas") with shippers ("expedidores"). Built as the GDSI capstone at FIUBA. The repository is in transition from **planning** (Typst artifacts: USM, WBS, personas) to **implementation** — backend and frontend are scaffolded; only a public landing page is live.

## Architecture at a Glance

- **Style**: client/server. Static SPA → stateless REST API. No BFF, no microservices.
- **Topology**: single-container Rails (Puma + Thruster) + static Vite bundle. SQLite primary DB; Solid Queue / Cache / Cable replace Redis.
- **Monorepo**: three independently buildable components.

```
fiuba-gestion-tp/
├── backend/    Rails 8 API (Ruby 3.4, SQLite, Solid* stack)
├── frontend/   React 18 + Vite 5 + TypeScript 5.3 (Deno runtime)
├── docs/       Typst sources (academic deliverable) + tech docs + onboarding
├── .agents/    Repo-wide AI skills (product/planning)
├── .gdsi-sdlc/ File-backed Kanban issue tracker
├── CLAUDE.md   Project conventions for AI agents
├── justfile    Task runner
└── mise.toml   Tool version pins
```

## Architectural Decisions (recorded in `01-technical-vision/`)

- **ADR-001** — Monorepo with separate `backend/` and `frontend/` components.
- **ADR-002** — Rails 8 API-only, SQLite + Solid* stack, zero external infra in prototype.
- **ADR-003** — React + Vite, Deno as task runner (Node still works).
- **ADR-004** — Typst for the academic report; `just` orchestrates compilation.
- **ADR-005** — Conventional Commits + `release-please` drive SemVer + CHANGELOG.
- **ADR-006** — AI harness as first-class infrastructure: per-component `.agents/skills/` + CLAUDE.md + `.gdsi-sdlc/` Kanban.

## Technology Stack

| Layer | Tech | Notes |
|-------|------|-------|
| Backend | Rails 8.1 (API-only), Ruby 3.4.8, SQLite, Solid Queue/Cache/Cable, Puma + Thruster | `config.api_only = true`. Background jobs and cache are DB-backed. |
| Frontend | React 18, Vite 5, TypeScript 5.3 (`strict: true`), Deno 2 | `deno task dev` runs Vite. Deps in `deno.json` `imports`. |
| Docs | Typst, Python (`uv`), `just` | `just build` compiles `docs/artifacts/main.typ` to PDF. |
| Tooling | `mise` pins versions; `prek` runs pre-commit (`typstyle`); `release-please` automates releases. |
| AI | Claude (dev-time only). Skills in `.agents/skills/` and `frontend/.agents/skills/`. |

## Domain Model

Persisted models do **not** exist yet — `backend/app/models/` only has `ApplicationRecord`. The target domain (from `docs/artifacts/`):

```
Identity         Marketplace        Fulfilment        Commerce
─────────        ───────────        ──────────        ────────
User             TransportWindow    Shipment          Payment / Escrow
Carrier          CargoOffer         TrackingEvent     InsurancePolicy
Shipper          Quote              Route             ArcaInvoice
Vehicle
```

Personas (es-AR) ↔ models (en): `Transportista` ↔ `Carrier`, `Expedidor` ↔ `Shipper`. Detailed entity spec lives in [`docs/02-high-level-design/domain-model.md`](../02-high-level-design/domain-model.md); ADR-007 to ADR-010 in `01-technical-vision/technical-vision.md` cover PK strategy, identity profile shape, soft-delete policy and geo storage.

Shipment lifecycle: `draft → quoted → accepted → in_transit → delivered → settled` (with `cancelled` branch). Each transition emits a `TrackingEvent`; `settled` triggers payment release + ARCA invoice emission.

## Must-Know Rules

1. **Spanish for content, English for code.** Product artifacts, user stories, prompts, issue titles in es-AR. Identifiers, code, commit messages, branch names in English. The **single source of truth** for term mapping is [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md) — update it first, propagate everywhere else.
2. **Conventional Commits.** `fix:`, `feat:`, `feat!:`, `docs:`, `chore:`, `ci:`. Drift = silently dropped from release.
3. **API endpoints live under `/api/`.** snake_case JSON keys (no camelCase serializer). `/up` is the Rails health check — never put business logic there.
4. **CORS is dev-permissive.** Allow-list in `backend/config/initializers/cors.rb` includes `localhost:5173`. Never widen to `"*"` in production.
5. **No auth yet.** All endpoints are public. Don't ship anything that assumes a `current_user`.
6. **Background jobs go in `backend/app/jobs/`** and inherit from `ApplicationJob`. Idempotent. Pass IDs, not AR objects.
7. **AI harness is canonical.** New AI capability → a skill folder, not a chat-only convention. See `04-ai-harness.md`.
8. **Issue lifecycle = file movement** under `.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}/`. Tag format `<PREFIX>-<SCOPE>-<NNNNN>`.
9. **PDFs are generated.** Never commit `*.pdf`; release-please attaches them on release.
10. **Frontend design north-star = `frontend/.impeccable.md`.** All UI work goes through the `impeccable` / `critique` / `polish` skills.

## What's Live vs. Planned

| Surface | Today | Planned |
|---------|-------|---------|
| Public landing page | Static React (`App.tsx` + `landingContent.ts`), no backend call | Stays static |
| Frontend "Solicitar cotización" form | Local state only | POST to `/api/quote_requests` |
| Auth | None | bcrypt + Pundit policies scoped via `User#carrier?` / `User#shipper?` predicates (relation-derived; no denormalised columns — see ADR-008); ActiveAdmin has its own isolated `AdminUser` table |
| Background jobs | None | TrackingIngest, PaymentSettlement, InvoiceEmission, NotificationEmail, MatchExpiry |
| CI tests | None (only release-please) | Rails + frontend test suites in GitHub Actions |
| Migrations | None | First migrations land = Identity bounded context first |
