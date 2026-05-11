# Current State & Roadmap

## Project Status

**Phase**: planning → implementation transition.

| Component | Status |
|-----------|--------|
| `docs/artifacts/` (USM, WBS, personas, backlog, …) | Complete enough for course delivery; refinements ongoing. |
| `docs/01-` … `docs/05-` (tech docs) | Generated 2026-04-17; updated 2026-05-03 to cover bootstrap + AI harness. |
| `docs/onboarding/` | New (2026-05-03). |
| `backend/` | Rails 8 scaffolded. No `/api/*` controllers yet — only `/up` health check + ActiveAdmin. 0 domain models, 0 migrations. RSpec wired (`backend/spec/`); only a smoke spec so far. |
| `frontend/` | React + Vite scaffolded. Static single-file landing page (`App.tsx`) reading from `landingContent.ts`. No backend calls yet. Vitest (unit/component) + Playwright (E2E) wired; see `frontend/TESTING.md`. One smoke spec per layer. |
| AI harness | In place — `CLAUDE.md`, `.agents/skills/` (3), `frontend/.agents/skills/` (15), `.gdsi-sdlc/` Kanban. |
| Issue backlog | **Triaged 2026-05-03**: 44 new issues created, all 26 USs (US1–US26) have at least one TAG. See [`docs/features/DEPENDENCY-GRAPH.md`](../features/DEPENDENCY-GRAPH.md) for execution order. |
| CI | Only `release-please.yml` runs. No test workflow. |
| Deploy | Kamal config present (`backend/config/deploy.yml`) but no production target wired. |

## Live vs. Planned

| Surface | Today | Planned (priority order) |
|---------|-------|--------------------------|
| Landing page | Static React page (`App.tsx` + `landingContent.ts`) | Stays static — no backend involvement planned |
| Quote-request form | Frontend-only state | POST → `Api::QuoteRequestsController` |
| Auth | None | `has_secure_password` + session cookie (Solid Cache), CSRF, role helpers (`current_carrier`, `current_shipper`) — relation-derived predicates, no boolean columns (see ADR-008). ActiveAdmin owns its isolated `AdminUser` table. See `REQ-BE-00023`. |
| Identity domain | None | First migrations land here: `User`, `Carrier`, `Shipper`, `Vehicle`. Spec: `02-high-level-design/domain-model.md`; impl: `REQ-BE-00020`. |
| Marketplace domain | None | `TransportWindow`, `CargoOffer`, `Quote` — see `REQ-BE-00021` |
| Fulfilment domain | None | `Shipment` (state machine), `TrackingEvent`, `Route` — see `REQ-BE-00022` |
| Commerce domain | None | `Payment` (escrow), `Payout`, `InsurancePolicy`, `ArcaInvoice` — see `REQ-BE-00006` (MP), `REQ-BE-00011` (payout), `REQ-BE-00018` (insurance policy) |
| Background jobs | None defined | `MercadoPagoReconcileJob`, `CarrierPayoutJob`, `QuotePaymentTimeoutJob`, `IssueInsurancePolicyJob`, `EmailVerificationCleanupJob` |
| Versioned API | `/api/...` | `/api/v1/...` at first breaking change |

## Active Issues

Live index: [`docs/features/ISSUES-INDEX.md`](../features/ISSUES-INDEX.md). Execution order and parallelization: [`docs/features/DEPENDENCY-GRAPH.md`](../features/DEPENDENCY-GRAPH.md).

In flight (InReview):

- `REQ-BE-00005` — domain model design + ADRs + ERDs (gates everything in Tier 1).
- `INF-BE-00003` — ActiveAdmin.
- `REQ-DOC-00002` — risks artifact.
- `REQ-FE-00002` — cronograma.
- `INF-GEN-00001` — throughput projections.

After 2026-05-03 triage, all 26 user stories (US1–US26) are represented in the backlog as actionable fullstack TAGs. Fat USs (US4/8/13/14/15/20/25) have been split into actionable rebanadas; lean USs map 1:1.

## Priority Work (next slices)

The dependency graph forces a narrow funnel through the foundation tier before features parallelize. Order:

1. **`REQ-BE-00005`** (in review) — domain model design + ADRs + ERDs. Spec: [`docs/02-high-level-design/domain-model.md`](../02-high-level-design/domain-model.md); ADR-007 to ADR-010 in [`01-technical-vision/technical-vision.md`](../01-technical-vision/technical-vision.md); Identity ERD in [`04-database-diagrams/erd-identity.puml`](../04-database-diagrams/erd-identity.puml). Glossary promoted to [single source of truth](../05-appendices/glossary.md). Merges first — gates everything in Tier 1.
2. **`REQ-BE-00020`** — implement Identity migrations + AR models (`User`, `Carrier`, `Shipper`, `Vehicle`) + minimal RSpec specs. Unblocks Auth and every `/me/*` endpoint.
3. **`REQ-BE-00021`** — implement Marketplace models (`TransportWindow`, `CargoOffer`, `Quote`). Unblocks search/offer/accept stream.
4. **`REQ-BE-00022`** — implement Fulfilment models (`Shipment` + state machine, `TrackingEvent`, `Route`). Unblocks lifecycle, payment, tracking, reviews, insurance.
5. **`REQ-BE-00023`** — Auth fullstack (US1+US2): register/login/sessions + screens. Unblocks all user-facing features.
6. **Cross-cutting** (parallel from day 1, no Tier 1 dependency): `INF-BE-00004` (error envelope — establishes the API error pattern via the first real endpoint), `INF-BE-00005` (mailer), `INF-FE-00003` (FE routing + App.tsx split), `INF-INFRA-00001/2` (CI test workflow — closes the testing gap before more code lands).
7. **First feature streams** (after Tier 1): vehicle (`REQ-BE-00009`), search (`REQ-FE-00006`), publish window (`REQ-FE-00016`), carrier inbox (`REQ-FE-00017`).
8. **Backend skills folder** — once 2-3 real Rails patterns exist, extract into `backend/.agents/skills/{rails-controller, rails-model, rspec-test, solid-queue-job, migration}/`.

## Architecture Decisions Pending

Recorded as "Decisions Deferred" in `01-technical-vision/`:

- **Mobile strategy**: PWA vs. React Native. Influences API versioning timing.
- ~~**Test framework choice**: Minitest (Rails default) vs. RSpec.~~ Resolved 2026-05-03 — **RSpec exclusively** (`rspec-rails ~> 7.1`); Rails-default `backend/test/` is unused.
- ~~**Production database**: SQLite vs. PostgreSQL.~~ Resolved 2026-05-11 — **SQLite, permanent**. Project will not be brought to market; no migration is planned. See `CLAUDE.md` § "Database policy" + ADR-002.
- ~~**Geospatial storage**: PostGIS vs. external geo provider.~~ Resolved 2026-05-11 — **lat/lng columns + Haversine in app code + external API for routing distance**. No PostGIS, ever. See ADR-010.

## Scalability Roadmap

Per `CLAUDE.md` § "Database policy", there is no scalability roadmap past Phase 0. SQLite + single Kamal container is the final infrastructure. The table below documents the closed shape, not deferred work.

| Phase | Trigger | Change |
|-------|---------|--------|
| 0 (final) | Coursework scope | SQLite, single container, lat/lng + Haversine geo, external API for routing. Auth + CI test workflows still in flight inside this phase. |
| — | Scope change to market launch | Would re-open ADR-002 and ADR-010. Not on the table. |

## Known Technical Debt

- No domain models, migrations, or domain endpoints yet — only `/up` and ActiveAdmin live in the backend.
- Frontend quote form is local-state-only.
- CORS allow-list is dev-permissive (`localhost:5173`, all methods, all headers).
- Pre-commit only covers Typst formatting; Ruby and TypeScript are ungated.
- No CI tests.
- Single-file `App.tsx` (~620 LOC) needs splitting before a second route lands.
