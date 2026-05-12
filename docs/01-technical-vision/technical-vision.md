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
**Consequences**: Zero-infrastructure prototype; can be deployed with Kamal as a single container. **SQLite is the production database for the lifetime of this project** — there is no planned migration to PostgreSQL (see project directive in `CLAUDE.md` § "Database policy"). All schema, query, and infrastructure choices treat SQLite as permanent.

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

**Context**: Runs on SQLite (permanent — see ADR-002 and `CLAUDE.md` § "Database policy"). PKs are referenced by every FK in the schema, so the choice is hard to reverse. UUIDs would only pay off if external clients generated IDs offline, or if multi-master writes were on the table — neither is true.
**Decision**: Use `bigint` PKs (Rails default) for every domain table. Public-facing URLs that need to hide sequential numbering will use a separate `slug` or `obfuscated_id` column on the relevant resource (decided per resource when the first endpoint exposes IDs).
**Consequences**: Smaller indexes and faster joins on SQLite; trivially compatible with `references` migrations and Rails associations. Loses portability to event-sourced / offline-write scenarios — acceptable given the scope. Re-evaluating only triggers if a future feature explicitly requires client-generated IDs.

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

**Consequences**: Most tables stay simple. Unique indexes on the three soft-deleted tables must be partial (`WHERE deleted_at IS NULL`) where uniqueness is meaningful — supported in SQLite ≥ 3.8 (our target). Reports that need historical rows must use `unscoped` explicitly.

### ADR-010 — Geo storage: lat/lng columns, application-level distance math

**Context**: ADR-002 keeps SQLite as the production DB permanently (see `CLAUDE.md` § "Database policy"). PostGIS requires PostgreSQL and is therefore off the table. Tracking, routing, and "transportistas dentro de N km" features need to **store** coordinates and answer city / proximity queries — both achievable without spatial indexes at the scale this project will ever reach.
**Decision**:

- Latitude / longitude stored as `DECIMAL(9,6)` columns directly on `tracking_events`, `routes`, `transport_windows` and `cargo_offers` (origin / destination pairs). City and province go in indexed `string` columns alongside.
- No spatial index, no PostGIS, no GIN/GIST indexes. "Find by city" uses plain B-tree indexes on `(province, city)`.
- "Within N km" queries compute Haversine distance in Ruby over a candidate set narrowed by `(province, city)` or a coarse lat/lng bounding-box filter (`WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?`). For routing distances, call an external API (Google Maps Distance Matrix / OSRM) — no spatial storage required.

**Consequences**: Zero geospatial infrastructure ever. Proximity queries are O(N over a small bounded candidate set); fine at coursework scale. Routing distance is a paid/external call when needed, not a database concern.

### ADR-011 — Stateless auth via Devise + devise-jwt (JTI Matcher revocation)

**Context**: The first cut of auth (REQ-BE-00023) shipped `Api::AuthController` with hand-rolled `login` / `logout` / `csrf` on top of Devise primitives (`valid_password?`, `sign_in`, `sign_out`) — controllers stayed custom because the comment in the file judged `Devise::SessionsController` "too HTML-centric for the JSON contract". That decision is now reversed: the goal of REF-BE-00001 is to **reduce custom auth surface** (security/maintenance), and the natural fit for `config.api_only = true` (ADR-002) is stateless JWT.

**Decision**:

- Authentication runs on **Devise** (`:database_authenticatable`, `:validatable`, `:registerable`, `:jwt_authenticatable`) + the **`devise-jwt`** gem (warden-jwt_auth under the hood).
- Sessions (login/logout) are handled by `Api::SessionsController < Devise::SessionsController`. `respond_with` and `respond_to_on_destroy` are overridden to emit JSON (`MeResource` body, 204 on destroy).
- `register` stays custom in `Api::AuthController` because the role-attach side-effect (`Carrier` / `Shipper` profile creation in a transaction) doesn't model cleanly through `Devise::RegistrationsController#create`. `sign_in(user)` at the end of the flow triggers the devise-jwt dispatcher, so the response carries `Authorization: Bearer <jwt>` automatically.
- **Revocation = JTI Matcher.** A single `jti :string NOT NULL UNIQUE` column on `users`. Logout rotates it; any token bearing the prior `jti` becomes invalid for that user.
- **Transport = `Authorization: Bearer <jwt>` header.** No cookies in the API path. `Api::BaseController` drops `protect_from_forgery`, `ActionController::Cookies`, and `ActionController::RequestForgeryProtection` — eliminating the CSRF vector entirely. The bespoke `GET /api/auth/csrf` endpoint is removed.
- **FE storage = `localStorage["truckr.jwt"]`.** Survives page reload; XSS-exfiltratable. Accepted trade-off for coursework (no PII, no real users). Stricter CSP is a separate, follow-up concern.
- **Expiration**: 24 hours, no refresh tokens (re-login once per day is acceptable for coursework).
- **Failure responses**: a custom `Api::DeviseFailureApp < Devise::FailureApp` emits the unified `{ error: { code, message } }` envelope (`invalid_credentials` for bad login, `unauthorized` for missing/bad/revoked tokens).

**Consequences**:

- Auth-custom surface shrinks to two methods (`register` + `me`). Login/logout flow is library code.
- Zero CSRF code in the API path. SPA loses the bootstrap CSRF call.
- Stateless API: no session storage lookup per request — just the `jti` check on the user row.
- Logout invalidates all of a user's tokens (single-device-effective). Multi-device logout requires the `Denylist` strategy and a `jwt_denylist` table; not on the roadmap.
- Mobile / PWA (Decision Deferred) is no longer auth-blocked — Bearer tokens work the same on any client.
- JWT secret lives in Rails credentials (`devise_jwt_secret_key`); rotation requires a deploy (acceptable for coursework).

### Decisions Deferred

- Mobile strategy (React Native vs. PWA) — auth is no longer a blocker for either.

### Decisions Closed (not deferred)

- **Production database**: SQLite. Permanent. See `CLAUDE.md` § "Database policy" and ADR-002. No PostgreSQL migration is planned, queued, or under consideration.
- **Geospatial storage**: lat/lng columns + Haversine in application code + external API for routing. See ADR-010. No PostGIS, ever.
- **Authentication / authorization**: Devise + devise-jwt with JTI Matcher revocation. See ADR-011.

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

- Single-container deploy today and permanently — this project's scope ends at coursework, not market launch (see `CLAUDE.md` § "Database policy").
- SQLite is the permanent primary store. Vertical scaling on a single Kamal container covers every realistic workload this project will see; there is no planned migration to PostgreSQL or multi-node deployment.
- solid_queue scales by adding worker processes on the same container.

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

Per `CLAUDE.md` § "Database policy", this project does not have a scalability roadmap past Phase 0. SQLite + single Kamal container is the final infrastructure. Items below would only be revisited if the project's scope changed from coursework to a market launch — which is not on the table.

| Phase | Trigger | Change |
|-------|---------|--------|
| 0 (final) | Coursework scope | SQLite, single container, lat/lng + Haversine geo, external API for routing |
| — | Scope change to market launch | Would re-open ADR-002 and ADR-010. Not planned. |

---

## Document Information

| Attribute | Value |
|-----------|-------|
| Version | 1.1 |
| Generated | 2026-04-17 |
| Last updated | 2026-05-03 |
| Scope | Truckr® platform (backend + frontend + docs + AI harness) |
