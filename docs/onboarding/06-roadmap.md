# Current State & Roadmap

## Project Status

**Phase**: planning → implementation transition.

| Component | Status |
|-----------|--------|
| `docs/artifacts/` (USM, WBS, personas, backlog, …) | Complete enough for course delivery; refinements ongoing. |
| `docs/01-` … `docs/05-` (tech docs) | Generated 2026-04-17; updated 2026-05-03 to cover bootstrap + AI harness. |
| `docs/onboarding/` | New (2026-05-03). |
| `backend/` | Rails 8 scaffolded. One controller (`Api::LandingPagesController`). 0 models, 0 migrations. RSpec wired (`backend/spec/`); only a smoke spec so far. |
| `frontend/` | React + Vite scaffolded. Single-file landing page (`App.tsx`). Vitest (unit/component) + Playwright (E2E) wired; see `frontend/TESTING.md`. One smoke spec per layer. |
| AI harness | In place — `CLAUDE.md`, `.agents/skills/` (3), `frontend/.agents/skills/` (15), `.gdsi-sdlc/` Kanban. |
| CI | Only `release-please.yml` runs. No test workflow. |
| Deploy | Kamal config present (`backend/config/deploy.yml`) but no production target wired. |

## Live vs. Planned

| Surface | Today | Planned (priority order) |
|---------|-------|--------------------------|
| Landing page API | Hardcoded hash → JSON | DB-backed `LandingPage` model |
| Quote-request form | Frontend-only state | POST → `Api::QuoteRequestsController` |
| Auth | None | `has_secure_password` + JWT/session, Pundit policies (`transportista`, `cliente`, `admin`) |
| Identity domain | None | First migrations land here: `User`, `Transportista`, `Cliente`, `Vehicle` |
| Marketplace domain | None | `TransportWindow`, `CargoOffer`, `Quote` |
| Fulfilment domain | None | `Shipment` (state machine), `TrackingEvent`, `Route` |
| Commerce domain | None | `Payment` (escrow), `InsurancePolicy`, `ArcaInvoice` |
| Background jobs | None defined | `TrackingIngestJob`, `PaymentSettlementJob`, `InvoiceEmissionJob`, `NotificationEmailJob`, `MatchExpiryJob` |
| Versioned API | `/api/...` | `/api/v1/...` at first breaking change |

## Active Issues

See `docs/features/ISSUES-INDEX.md` for the live index. Current backlog highlights from `.gdsi-sdlc/issues/Backlog/`:

- `INF-GEN-00002` — bootstrap backend, frontend, docs y AI harness (covers this PR's scope).
- `INF-GEN-00001` — sin estimaciones, proyecciones basadas en throughput.
- `INF-FE-00001` — cierre de artifacts y próximos pasos.
- `REQ-DOC-00001` / `00002` / `00003` — pagos y GPS, riesgos refinement, USM additions (seguros, GPS, pagos).

## Priority Work (next slices)

1. **First domain model** — Identity bounded context. `User` + `Transportista` + `Cliente` + `Vehicle` with migrations and minimal tests. Rebases the `04-database-diagrams/erd-identity.puml` diagram against reality.
2. **First real endpoint** — `Api::QuoteRequestsController#create` so the frontend form actually POSTs. Establishes the error envelope pattern.
3. **CI test workflow** — `.github/workflows/test.yml`. Closes the testing gap before more code lands.
4. **Backend skills folder** — once 2-3 real Rails patterns exist, extract them into `backend/.agents/skills/{rails-controller, rails-model, rspec-test, solid-queue-job, migration}/`.
5. **Auth** — `has_secure_password` for users, then Pundit. Unblocks every persona-aware feature.

## Architecture Decisions Pending

Recorded as "Decisions Deferred" in `01-technical-vision/`:

- **Production database**: SQLite vs. PostgreSQL. Stick with SQLite while single-container; revisit when write volume or multi-node deploy lands.
- **Geospatial storage**: PostGIS vs. external geo provider (Google Maps / HERE / OSRM). Tied to Maps integration.
- **Mobile strategy**: PWA vs. React Native. Influences API versioning timing.
- ~~**Test framework choice**: Minitest (Rails default) vs. RSpec.~~ Resolved 2026-05-03 — **RSpec exclusively** (`rspec-rails ~> 7.1`); Rails-default `backend/test/` is unused.

## Scalability Roadmap

| Phase | Trigger | Change |
|-------|---------|--------|
| 0 (now) | Prototype demo | SQLite, single container, no auth, no tests. |
| 1 | First real users / write volume | Migrate to PostgreSQL, add CI tests, ship auth. |
| 2 | Geographic features go live | Add PostGIS or external geo provider. |
| 3 | Multi-region / HA | Extract background workers, adopt managed queue (Sidekiq/Good Job). |
| 4 | Mobile launch | Split API contract into `/api/v1`. |

## Known Technical Debt

- Backend returns hardcoded landing-page data; no model, no migration, no test.
- Frontend quote form is local-state-only.
- CORS allow-list is dev-permissive (`localhost:5173`, all methods, all headers).
- Pre-commit only covers Typst formatting; Ruby and TypeScript are ungated.
- No CI tests.
- Single-file `App.tsx` (~620 LOC) needs splitting before a second route lands.
