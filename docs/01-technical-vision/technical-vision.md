# Technical Vision — Truckr®

## Business Context

Truckr® is a two-sided marketplace that connects **independent truck owners / drivers ("transportistas")** with **shippers ("expedidores" — covers SMB customers and producers shipping their own goods)** who need to move physical goods. The platform is being developed as the capstone project for **Gestión del Desarrollo de Sistemas Informáticos (GDSI)** at Facultad de Ingeniería, Universidad de Buenos Aires.

> Persona ↔ model mapping: `Transportista` ↔ `Carrier`, `Expedidor` ↔ `Shipper`. Identifiers (models, tables, columns) are always English. The single source of truth is [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md).

### Problem Domain

Argentina's overland freight market is highly fragmented. Independent transportistas spend significant time and money securing loads, while small-to-mid producers lack visibility into trucker availability, pricing and reliability. Existing options are either large logistics operators (rigid, expensive) or informal networks (unverified, no guarantees).

### Business Proposition

| Side | Core value |
|------|------------|
| Transportistas | Find new expedidores, publish availability windows, grow independent businesses |
| Expedidores | Publish loads, compare transportistas, pay securely, track shipments |
| Platform | Take transaction fees, offer value-added services (insurance, ARCA tax integration, route optimisation) |

### Target Users & Use Cases

- **Independent transportistas** publishing vehicle availability and route windows.
- **Expedidores** (SMB shippers and own-goods producers) posting cargo and selecting a transportista.
- Both sides need payment handling, verified counter-parties, and shipment traceability.

### Scope Guardrails ("Es / No Es")

Derived from `docs/artifacts/es-no-es-hace-no-hace.typ`:

- **Is**: web platform (optionally mobile) to match transportistas and shippers.
- **Is not**: a passenger-transport app, a goods marketplace, a consultancy, or a social network.
- **Does**: transport-window publishing, cargo publishing, vehicle registration, route planning/GPS, secure payments, insurance brokering, shipment history, tracking, ARCA fiscal integration.
- **Does not**: sell/buy the goods, handle returns, move people, or deliver parcels/mail.

---

## Architectural Decisions

The project is transitioning from the **planning phase** (product artifacts, USM, WBS, personas in `docs/artifacts/`) into the **implementation phase**. The backend (`backend/`) and frontend (`frontend/`) have been scaffolded; the frontend ships a static public landing page and the backend has ActiveAdmin mounted plus the `/up` health check, but no domain `/api/*` endpoints yet. The decisions below are the ones committed to in code or roadmap.

### ADR-001 — Split backend and frontend repositories inside a single monorepo

**Context**: Team is small, product will ship as a single web app in the short term, but has a clear plan for a mobile client and additional services (payments, insurance, ARCA).
**Decision**: Keep a single Git monorepo with two independently buildable components (`backend/`, `frontend/`) plus a `docs/` component for the academic deliverable.
**Consequences**: Simple local developer experience; shared versioning via release-please; components can later be extracted into their own repos without rewriting their internals.

### ADR-002 — Rails 8 API-only backend with SQLite + Solid* stack

**Context**: Minimise operational surface in the prototype phase. Rails 8 ships with `solid_queue`, `solid_cache`, `solid_cable` — all DB-backed, removing the need for Redis/Memcached.
**Decision**: `config.api_only = true`, SQLite primary DB, separate SQLite databases for `cache`, `queue` and `cable` in production.
**Consequences**: Zero-infrastructure prototype; can be deployed with Kamal as a single container. Migration to PostgreSQL planned before multi-region or high-write workloads.

### ADR-003 — React + Vite frontend, Deno as task runner

**Context**: Team wants TypeScript-first, fast HMR, minimal config.
**Decision**: React 18 + Vite 5; Deno 2 runs `vite` via `deno task` so Node is not required for contributors that already use Deno.
**Consequences**: `npm` still works (package-lock.json tracked) so contributors can use either runtime. Dependencies are declared in `deno.json` `imports`, not `package.json`, which is intentional.

### ADR-004 — Typst for the academic report, `just` as command runner

**Context**: GDSI deliverables are PDF reports; LaTeX was rejected for ergonomic reasons. Python/Excel tooling is needed for backlog/WBS/USM generation from the shared spreadsheet.
**Decision**: Typst source in `docs/`, build orchestrated via `justfile`, Python scripts under `docs/scripts/` convert `.xlsx` and chat `.json` exports into `.typ`.
**Consequences**: PDFs are attached automatically to GitHub releases via `release-please` + `typst compile` in `.github/workflows/release-please.yml`.

### ADR-005 — Conventional Commits + release-please for versioning

**Context**: Coursework requires traceable milestones; product will iterate quickly.
**Decision**: Adopt Conventional Commits, run `release-please` on push to `main` to auto-generate `CHANGELOG.md`, tag SemVer releases, and attach built PDFs.
**Consequences**: Non-conventional commit messages will be silently skipped by release-please — pre-commit hooks should be extended to enforce the convention later.

### ADR-006 — AI-augmented SDLC via a per-component skill harness

**Context**: A two-person team needs to ship a marketplace, an academic deliverable, and a polished landing page on a course timeline. AI assistants are a primary productivity multiplier, but only if their context and conventions are versioned alongside the code.
**Decision**: Adopt a **per-component AI harness**:

- Repo-wide `CLAUDE.md` documents project conventions for AI agents.
- Repo-wide `.agents/skills/` holds **product/planning** skills (`user-stories`, `job-stories`, `task-planning`).
- `frontend/.agents/skills/` holds **design/UX** skills (`impeccable`, `critique`, `polish`, `audit`, `animate`, `layout`, etc.) plus `frontend/.impeccable.md` as the design north-star.
- `frontend/.claude/skills/` symlinks the same skills so Claude Code picks them up natively.
- `.gdsi-sdlc/` houses the issue-tracking + automation harness (`Backlog/`, `Ready/`, `InProgress/`, `InReview/`, `Done/` folders mirror a Kanban board; `automation/queue/` drives AI-driven sync).

**Consequences**: AI agents have stable, reviewable context. Skills are versioned, diffable and reproducible across sessions. The harness is **the** workflow for moving a backlog item from `Backlog/` to `Done/` — see `05-appendices/ai-harness.md` for the full inventory.

### ADR-007 — Bigint primary keys (Rails default)

**Context**: Phase 0/1 runs on SQLite, Phase 1+ migrates to PostgreSQL (still deferred). PKs are referenced by every FK in the schema, so the choice is hard to reverse. UUIDs would only pay off if external clients generated IDs offline, or if multi-master writes were on the table — neither is true.
**Decision**: Use `bigint` PKs (Rails default) for every domain table. Public-facing URLs that need to hide sequential numbering will use a separate `slug` or `obfuscated_id` column on the relevant resource (decided per resource when the first endpoint exposes IDs).
**Consequences**: Smaller indexes and faster joins on both SQLite and Postgres; trivially compatible with `references` migrations and Rails associations. Loses portability to event-sourced / offline-write scenarios — acceptable given the scope. Re-evaluating only triggers if a future feature explicitly requires client-generated IDs.

### ADR-008 — User ↔ Carrier/Shipper: role + extension table

**Context**: A single human can act as both `Carrier` (transportista) and `Shipper` (expedidor) — the product explicitly allows it. STI (`users` with type column) leaks role-specific columns as nullable into the base table; polymorphic profile abstractions over only two profile types are over-engineering. Identifier rules: model and table names are English (see glossary), even though the personas are `Transportista` and `Expedidor` in product copy.
**Decision**:

- `users` holds auth + common fields (`email`, `password_digest`, `full_name`, `phone`, `dni_or_cuit`, `verified_at`).
- `carriers` (FK `user_id`, unique) carries Carrier-specific fields (`legal_name`, `base_city`, `rating_avg`, `completed_shipments`).
- `shippers` (FK `user_id`, unique) carries Shipper-specific fields (`company_name`, `tax_id`, `billing_address`).
- **Role state is derived from the `has_one :carrier` / `has_one :shipper` relations on `User`**. Convenience access via scopes (`User.carriers`, `User.shippers`) and predicate methods (`user.carrier?`, `user.shipper?`). **No denormalised boolean columns on `users`** — relation rows are the source of truth. Revisit when a third role is needed: switch to a `user_roles` join table.
- `users` does **not** carry an `admin` value or role — `AdminUser` (generated by ActiveAdmin/Devise via INF-BE-00003) lives in its own isolated table.

**Consequences**: FK integrity preserved; nullable columns avoided; same `User` can hold both profiles cleanly. Adds one extra row write on profile creation — negligible.

**Why not denormalise** (`is_carrier` / `is_shipper` boolean columns on `users`): the relation row already encodes role membership, so adding boolean mirror columns introduces a guaranteed drift surface — every `Carrier#create` / `Carrier#destroy` (and `Shipper` likewise) would have to remember to flip the corresponding flag, a classic dual-write hazard. The maintenance cost (sync callbacks + periodic invariant checks in tests) buys nothing the relation-derived scope can't deliver in one indexed join. If a future profile / query pattern proves the join is hot enough to need denormalisation, add the column then, **behind an explicit invariant** (after_create / after_destroy callback + a spec asserting the invariant holds for every `Carrier` / `Shipper` row). Until that data exists, denormalising is premature optimisation.

### ADR-009 — Selective soft-delete (audit-bearing entities only)

**Context**: Soft-delete (`deleted_at` column + a `kept` scope) preserves historical rows for legal / fiscal / audit reasons but complicates every query and every unique index (`WHERE deleted_at IS NULL`). Universal soft-delete is overkill for catalog-like entities; universal hard-delete breaks ARCA traceability for shipments and payments.
**Decision**:

- **Soft-delete enabled** on `Shipment`, `Payment`, `ArcaInvoice` — these carry fiscal / contractual significance.
- **Hard-delete** on `Carrier`, `Shipper`, `Vehicle`, `TransportWindow`, `CargoOffer`, `Quote`, `TrackingEvent`, `Route`, `InsurancePolicy`. Cascade rules expressed via Rails `dependent: :destroy` / `:nullify` per relation (specifics in `domain-model.md`).
- No gem mandated. The Phase-0 implementation is a `deleted_at` column, a default scope (`where(deleted_at: nil)`) only on the three audit-bearing models, and explicit `unscoped` for admin reads.

**Consequences**: Most tables stay simple. Unique indexes on the three soft-deleted tables must be partial (`WHERE deleted_at IS NULL`) where uniqueness is meaningful — already supported in SQLite ≥ 3.8 and natively in Postgres. Reports that need historical rows must use `unscoped` explicitly.

### ADR-010 — Geo storage: lat/lng columns Phase 0/1; PostGIS Phase 2

**Context**: ADR-002 keeps SQLite as the primary DB through Phase 1. PostGIS requires PostgreSQL — adopting it now would force the Phase-1 migration ahead of schedule. Tracking, routing, and "transportistas dentro de N km" features eventually need spatial indexes, but Phase 0/1 only needs to **store** coordinates and lookup-by-city. External providers (Google Maps Distance Matrix, OSRM) solve routing but not storage.
**Decision**:

- Phase 0/1 stores latitude / longitude as `DECIMAL(9,6)` columns directly on `tracking_events`, `routes`, `transport_windows` and `cargo_offers` (origin / destination pairs). City and province go in indexed `string` columns alongside.
- No spatial index, no PostGIS, no GIN indexes. "Find by city" uses plain B-tree indexes on `(province, city)`.
- Phase 2 introduces PostGIS in lockstep with the SQLite → Postgres migration; lat/lng columns become `point` / `geography(Point, 4326)` and acquire a GIST index. The migration is mechanical because no app-level code is allowed to bake in spatial-function calls before then.

**Consequences**: Phase 0/1 ships with zero geospatial infra. Distance / radius queries return nothing useful until Phase 2 — features that depend on them are deferred to that phase. The Phase-2 schema migration is a focused, well-scoped piece of work.

### Decisions Deferred

- Authentication / authorization (no users or sessions yet — the only endpoint is public). User schema in ADR-008 reserves the auth slots (`password_digest`, `verified_at`).
- Database choice for production beyond SQLite (likely PostgreSQL — still deferred; ADR-010 hangs the geo Phase-2 migration off this).
- Mobile strategy (React Native vs. PWA).

---

## Technology Stack

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| Backend framework | Ruby on Rails | 8.1.x (API-only) | Convention-over-configuration, Solid* stack removes Redis dependency |
| Language (backend) | Ruby | 3.4.8 | Pinned in `Dockerfile` ARG |
| DB | SQLite | ≥ 3.8 | Zero-ops prototype; multi-database split for cache/queue/cable in production |
| Job queue | solid_queue | bundled with Rails 8 | DB-backed, no Redis |
| Cache | solid_cache | bundled with Rails 8 | DB-backed |
| WebSocket | solid_cable | bundled with Rails 8 | DB-backed pub/sub |
| App server | Puma | ≥ 5.0 | Rails default |
| HTTP front | Thruster | latest | Asset caching/compression, X-Sendfile for Puma |
| File storage | Active Storage + image_processing | — | Uses libvips for transforms |
| CORS | rack-cors | latest | Explicit allow-list for dev origins |
| Deploy | Kamal | latest (dev dep only) | Docker-based deploy target |
| Frontend framework | React | 18.2.0 | Team familiarity |
| Build tool | Vite | 5.0.0 | Fast HMR, ESM-native |
| Language (frontend) | TypeScript | 5.3.3 | `strict: true` enforced |
| Runtime | Deno | 2.x | `deno task dev/build/preview` |
| Docs engine | Typst | latest | Replaces LaTeX for academic report |
| Task runner | just | latest | Simpler than Make |
| Version manager | mise | latest | Pins gh, typst, uv, prek, typstyle, just |
| Python tooling | uv | latest | Used by `docs/scripts/*.py` for xlsx → typ |
| Commit linting | prek (pre-commit) | latest | Runs `typstyle` on `.typ` files |
| Security (Ruby) | brakeman, bundler-audit | dev-only | Static analysis, advisory scan |
| Style (Ruby) | rubocop-rails-omakase | dev-only | Rails official style |
| Test (backend) | rspec-rails | ~> 7.1 | **Exclusive** backend test framework; specs live under `backend/spec/` |
| Test (frontend, L1) | vitest + happy-dom + @testing-library/react + @testing-library/jest-dom + @testing-library/user-event + msw | latest | Unit + component layer; co-located `*.test.tsx`; v8 coverage target ≥ 80 % |
| Test (frontend, L2) | @playwright/test | latest | E2E layer; specs in `frontend/e2e/`; Chromium default, Firefox/WebKit opt-in |
| Release | release-please | v4 (Action) | Conventional-commits → SemVer → GitHub Release |
| AI assistant | Claude (Anthropic) | — | Skills + CLAUDE.md context loaded per session; see `05-appendices/ai-harness.md` |
| SDLC harness | gdsi-sdlc | — | File-backed Kanban (`.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}`) with GitHub Projects sync |

---

## Quality Attributes

### Performance

- **Latency target (prototype)**: p95 < 300 ms for the first domain endpoint when it lands; the static frontend bundle ships with no server round-trip on initial render.
- Thruster fronts Puma in production to offload static assets and compression.
- `jemalloc` preloaded in the production Docker image to reduce Ruby memory fragmentation.
- Frontend is a static Vite build — cached at CDN once deployed.

### Scalability

- Single-container deploy today. Vertical scaling is sufficient for demo scope.
- SQLite is the current primary store; migration to PostgreSQL is expected when write volume or multi-node deployment becomes necessary.
- solid_queue scales by adding worker processes; can be swapped for Sidekiq/Good Job without changing job definitions.

### Security

- Rails API-only mode disables session, cookies and flash middleware by default — reduces attack surface.
- `brakeman` and `bundler-audit` available as dev tools; not yet wired into CI.
- Secrets via `config/master.key` + `config/credentials.yml.enc`.
- CORS allow-list currently includes `localhost:5173` for the Vite dev server — **must be tightened before any production deployment**.
- No authentication or authorization implemented yet.

### Availability

- No SLA defined for the prototype.
- Rails health check exposed at `/up` for load-balancer probes.
- Kamal + Docker give zero-downtime rolling deploys when multi-replica deployment is set up.

---

## Future Considerations

### Known Technical Debt

- Backend has no domain controllers, models, or migrations yet — only `/up` and ActiveAdmin are mounted.
- Frontend form ("Solicitar cotización") currently only updates local state — no POST endpoint exists.
- CORS is permissive across all methods and headers — acceptable for dev, must be narrowed for prod.
- Pre-commit hooks only cover Typst formatting; Ruby and TypeScript lint/test steps are not enforced.
- No CI test runs (only a release-please workflow).

### Planned Capabilities (from product artifacts)

See `docs/artifacts/backlog-us.typ`, `usm.typ`, `wbs.typ` for the full backlog. The high-impact milestones:

1. **Auth & profiles** for transportistas and expedidores.
2. **Marketplace core**: publishing transport windows and cargo offers, matching.
3. **Payments**: integrated gateway with escrow.
4. **Tracking**: GPS + shipment history.
5. **Insurance brokering** for shipments.
6. **ARCA fiscal integration** for invoicing.
7. **Mobile client** (PWA or native — decision pending).

### Scalability Roadmap

| Phase | Trigger | Change |
|-------|---------|--------|
| 0 (now) | Prototype demo | SQLite, single container |
| 1 | First real users / write volume | Migrate to PostgreSQL, add CI tests |
| 2 | Geographic features live | Add PostGIS or external geo provider |
| 3 | Multi-region / HA | Extract background workers, adopt managed queue |
| 4 | Mobile launch | Split API contract into v1 with versioning |

---

## Document Information

| Attribute | Value |
|-----------|-------|
| Version | 1.1 |
| Generated | 2026-04-17 |
| Last updated | 2026-05-03 |
| Scope | Truckr® platform (backend + frontend + docs + AI harness) |
