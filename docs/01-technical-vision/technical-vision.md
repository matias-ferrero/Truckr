# Technical Vision — Truckr®

## Business Context

Truckr® is a two-sided marketplace that connects **independent truck owners / drivers ("transportistas")** with **clients and producers ("clientes" / "productores")** who need to move physical goods. The platform is being developed as the capstone project for **Gestión del Desarrollo de Sistemas Informáticos (GDSI)** at Facultad de Ingeniería, Universidad de Buenos Aires.

### Problem Domain

Argentina's overland freight market is highly fragmented. Independent transportistas spend significant time and money securing loads, while small-to-mid producers lack visibility into trucker availability, pricing and reliability. Existing options are either large logistics operators (rigid, expensive) or informal networks (unverified, no guarantees).

### Business Proposition

| Side | Core value |
|------|------------|
| Transportistas | Find new clients, publish availability windows, grow independent businesses |
| Clientes / Productores | Publish loads, compare transportistas, pay securely, track shipments |
| Platform | Take transaction fees, offer value-added services (insurance, ARCA tax integration, route optimisation) |

### Target Users & Use Cases

- **Independent transportistas** publishing vehicle availability and route windows.
- **Producers / SMB clients** posting cargo and selecting a transportista.
- Both sides need payment handling, verified counter-parties, and shipment traceability.

### Scope Guardrails ("Es / No Es")

Derived from `docs/artifacts/es-no-es-hace-no-hace.typ`:

- **Is**: web platform (optionally mobile) to match transportistas and shippers.
- **Is not**: a passenger-transport app, a goods marketplace, a consultancy, or a social network.
- **Does**: transport-window publishing, cargo publishing, vehicle registration, route planning/GPS, secure payments, insurance brokering, shipment history, tracking, ARCA fiscal integration.
- **Does not**: sell/buy the goods, handle returns, move people, or deliver parcels/mail.

---

## Architectural Decisions

The project is transitioning from the **planning phase** (product artifacts, USM, WBS, personas in `docs/artifacts/`) into the **implementation phase**. The backend (`backend/`) and frontend (`frontend/`) have been scaffolded and a vertical slice (public landing page) is live. The decisions below are the ones committed to in code or roadmap.

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

### Decisions Deferred

- Authentication/authorization (no users or sessions yet — the only endpoint is public).
- Database choice for production beyond SQLite (likely PostgreSQL).
- Geospatial storage (PostGIS vs. external provider for route/GPS features).
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

- **Latency target (prototype)**: p95 < 300 ms for the landing-page endpoint.
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

- Backend returns **hardcoded** landing-page data; no `Model`, no migrations, no tests yet.
- Frontend form ("Solicitar cotización") currently only updates local state — no POST endpoint exists.
- CORS is permissive across all methods and headers — acceptable for dev, must be narrowed for prod.
- Pre-commit hooks only cover Typst formatting; Ruby and TypeScript lint/test steps are not enforced.
- No CI test runs (only a release-please workflow).

### Planned Capabilities (from product artifacts)

See `docs/artifacts/backlog-us.typ`, `usm.typ`, `wbs.typ` for the full backlog. The high-impact milestones:

1. **Auth & profiles** for transportistas and clientes.
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
