# High-Level Design — Truckr®

## System Architecture

Truckr® is structured as a **client / API / docs** triad, packaged as a **single monorepo** with three independently buildable components. Today the system is a thin vertical slice (public landing page) over a Rails 8 API, but the architectural boundaries are set up for the full marketplace described in the product vision.

### Style

- **Architecture style**: client-server. The frontend is a **static single-page application** that calls a **stateless REST API**. There is no BFF layer, no aggregator, no microservice split.
- **Deployment style**: the API is a single containerised Rails process (Puma + Thruster). The SPA is a static bundle that can be served from any CDN or from the same container.
- **Persistence style**: Rails multi-database setup — separate SQLite files for the app domain, Solid Cache, Solid Queue and Solid Cable. All in-process, no external brokers.

### Top-Level Components

| Component | Path | Role |
|-----------|------|------|
| **Backend API** | `backend/` | Rails 8 API-only; owns data, business logic, and background jobs. |
| **Frontend SPA** | `frontend/` | React + Vite single-page app; consumes JSON from the API. |
| **Documentation** | `docs/` | Typst report (academic deliverable) + chat-session logs. Not runtime-coupled to the app. |

### Layered View of the Backend

Rails' conventions are respected deliberately — each folder maps to a layer:

```
backend/app/
├── controllers/         # HTTP boundary (API namespace for JSON endpoints)
│   └── api/
├── models/              # Domain + ActiveRecord persistence (currently empty)
├── jobs/                # Background work (solid_queue)
├── mailers/             # Transactional email (not used yet)
└── views/               # Only mailer layouts — API is JSON-only
```

### Layered View of the Frontend

```
frontend/src/
├── main.tsx             # React entry point — mounts <LandingPage />
├── App.tsx              # Single page; data-fetching, quote form, layout
└── styles/              # Co-located CSS
```

The frontend today is a **single-file component** (`App.tsx`, ~620 lines). When a second page appears this should be split into a router + per-feature folders.

---

## Core Patterns

The patterns below are either already present in code or load-bearing for the roadmap.

### 1. API-only Rails

- **Purpose**: strip session, cookies, flash and asset middleware; serve JSON only.
- **Implementation**: `config.api_only = true` in `backend/config/application.rb`; `ApplicationController < ActionController::API`.
- **Where**: `backend/app/controllers/application_controller.rb`.
- **Rule**: new endpoints live under `app/controllers/api/` and are mounted inside the `:api` namespace in `config/routes.rb`.

### 2. Resource-based routing

- **Purpose**: predictable REST URLs, one resource per controller.
- **Implementation**: `resources :landing_pages, only: [:index]` under a namespaced `:api` block.
- **Example**: `GET /api/landing_pages` → `Api::LandingPagesController#index`.
- **Rule**: restrict verbs explicitly with `only:` / `except:` — do not expose all seven actions unless intended.

### 3. Health check endpoint

- **Purpose**: load-balancer liveness probe.
- **Implementation**: `get "up" => "rails/health#show"` in `config/routes.rb`.
- **Rule**: never add business logic here; this must stay cheap and dependency-free.

### 4. CORS via explicit allow-list

- **Purpose**: allow the Vite dev server (`localhost:5173`) to call the Rails API (`localhost:3000`) during development.
- **Implementation**: `rack-cors` middleware inserted at position 0 in `backend/config/initializers/cors.rb`.
- **Rule**: production origins must be added explicitly — **never widen this to `"*"` in production**.

### 5. Solid* stack (DB-backed infra)

- **Purpose**: avoid Redis/Memcached in the prototype.
- **Implementation**: `solid_cache`, `solid_queue`, `solid_cable` gems + dedicated SQLite databases in `config/database.yml` (`cache`, `queue`, `cable` entries under `production`).
- **Rule**: background jobs go in `backend/app/jobs/`, inherit from `ApplicationJob`. Cache reads/writes use `Rails.cache`. Never bypass these for a third-party broker without an ADR.

### 6. Client-side data-fetching with schema validation

- **Purpose**: defend the UI from backend shape drift without a code-generated client.
- **Implementation**: `isLandingData()` type guard in `frontend/src/App.tsx` validates the JSON shape before `setData()`.
- **Rule**: every `fetch()` must (a) check `response.ok`, (b) parse as `unknown`, (c) narrow via a type guard. This keeps the TypeScript types honest at the boundary.

### 7. Theme-via-CSS-variables

- **Purpose**: brand palette comes from the API (`color_palette` in the landing-page payload) so non-technical editing is possible.
- **Implementation**: `themeVars` memo in `App.tsx` maps the palette to `--brand-*` CSS custom properties on the root element.
- **Rule**: component styles read `var(--brand-primary)` etc. — never hardcode palette hexes.

### 8. Document-as-code

- **Purpose**: academic deliverables are versioned, diffable, and reproducible.
- **Implementation**: `.typ` source under `docs/artifacts/` and `docs/prompts/`, Python scripts convert `.xlsx` (Lean Artifacts spreadsheet) and exported chat JSON into `.typ`, `justfile` orchestrates compilation.
- **Rule**: don't hand-edit generated artifacts (e.g. `backlog-us.typ` comes from the XLSX); edit the source data and re-run `just`.

### 9. Automated release with attached PDFs

- **Purpose**: every release ships the compiled academic report.
- **Implementation**: `.github/workflows/release-please.yml` runs release-please, then on a `release_created` output compiles `artifacts.pdf` and `prompts.pdf` via Typst and attaches them with `softprops/action-gh-release@v2`.
- **Rule**: PDFs are **generated**, never committed — keep them out of Git.

### 10. AI harness as a first-class development pattern

- **Purpose**: keep AI-agent context and conventions versioned alongside the code rather than living in private chat history.
- **Implementation**: per-component skill folders under `.agents/skills/` and `frontend/.agents/skills/`; `CLAUDE.md` at the repo root pins project-wide conventions; the design system is anchored in `frontend/.impeccable.md`. The `.gdsi-sdlc/` Kanban (`Backlog/Ready/InProgress/InReview/Done`) plus `automation/queue/` drive issue lifecycle.
- **Rule**: a backlog item moves through `.gdsi-sdlc/issues/<state>/<TAG>.issue.md` files; AI skills are the canonical entry point for product (`user-stories`, `job-stories`, `task-planning`) and frontend craft work (`impeccable`, `critique`, `polish`, …). See `05-appendices/ai-harness.md` for the full inventory.

---

## Domain Model

The code has no persisted domain model yet (`backend/app/models/` contains only the base class). The entities below come from the product artifacts (`docs/artifacts/*.typ`) and describe the **target** domain the backend will grow into.

### Bounded Contexts

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Identity      │  │   Marketplace   │  │   Fulfilment    │
│                 │  │                 │  │                 │
│ User            │  │ TransportWindow │  │ Shipment        │
│ Transportista   │  │ CargoOffer      │  │ TrackingEvent   │
│ Cliente         │  │ Match / Quote   │  │ Route           │
│ Vehicle         │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
        ▲                    ▲                    ▲
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                  ┌──────────┴──────────┐
                  │     Commerce        │
                  │                     │
                  │ Payment / Escrow    │
                  │ InsurancePolicy     │
                  │ ARCAInvoice         │
                  └─────────────────────┘
```

### Core Entities (planned)

| Entity | Context | Purpose |
|--------|---------|---------|
| User | Identity | Base account, email/password. |
| Transportista | Identity | Independent trucker profile; references one or many Vehicles. |
| Cliente / Productor | Identity | Shipper profile; may be an SMB or individual. |
| Vehicle | Identity | Truck with capacity, plate, GPS capability. |
| TransportWindow | Marketplace | Published availability (origin/destination/time/vehicle). |
| CargoOffer | Marketplace | Published load (origin/destination/weight/goods). |
| Match / Quote | Marketplace | A transportista's offer to fulfil a cargo, or a client's booking of a window. |
| Shipment | Fulfilment | Active transport in progress; lifecycle states. |
| TrackingEvent | Fulfilment | Append-only log (position, status change). |
| Route | Fulfilment | Planned polyline + waypoints. |
| Payment / Escrow | Commerce | Held funds released on delivery. |
| InsurancePolicy | Commerce | Optional insurance per shipment. |
| ARCAInvoice | Commerce | Fiscal document emitted against a completed shipment. |

### Entity Lifecycle — Shipment (planned)

```
draft ──▶ quoted ──▶ accepted ──▶ in_transit ──▶ delivered ──▶ settled
                │                     │
                └── cancelled ◀───────┘
```

Each transition emits `TrackingEvent` rows; `settled` triggers payment release and ARCA invoicing.

---

## API Architecture

### Style

**REST / JSON.** No GraphQL, no gRPC. The only live endpoint today is `GET /api/landing_pages`. Future endpoints will be designed as plural, namespaced resources under `/api/...`.

### Versioning Strategy

Not yet in place. When a mobile client or third-party integration lands, the recommended approach is:

- **URL versioning**: `/api/v1/...` introduced from the first breaking change.
- Current `/api/*` paths become `/api/v1/*` (compatible alias retained for one minor release).

### Authentication / Authorization

**Not implemented.** The project will likely adopt:

- **AuthN**: `has_secure_password` (bcrypt) for user accounts; JWT or Rails session cookies depending on mobile needs.
- **AuthZ**: Pundit policies per resource, scoped by role (`transportista`, `cliente`, `admin`).

### Error Handling

- Current controllers return raw JSON on success; there is no shared error envelope.
- **Recommended**: a `rescue_from` in `ApplicationController` mapping Rails exceptions to an `{ error: { code, message, details } }` envelope with the right status code.

### Conventions

- Routes: plural, snake_case (`landing_pages`, `transport_windows`, `cargo_offers`).
- Controller responses: top-level object, camelCase **not** used — keys match Ruby style (`cta_primary`, not `ctaPrimary`). The frontend reads snake_case keys directly.
- Dates/times: ISO-8601 UTC when added.

---

## Data Flow

### Current Flow — Landing Page Render

```
Browser                 Vite dev server            Rails API
   │                         │                         │
   │ GET /                   │                         │
   ├────────────────────────▶│                         │
   │ index.html + JS bundle  │                         │
   │◀────────────────────────┤                         │
   │                                                   │
   │ fetch(GET /api/landing_pages)                     │
   ├──────────────────────────────────────────────────▶│
   │                                                   │ LandingPagesController#index
   │                                                   │  (hardcoded hash)
   │ 200 JSON { hero, features, stats, color_palette } │
   │◀──────────────────────────────────────────────────┤
   │                                                   │
   │ isLandingData(json) ? setData : setError          │
   │ theme-from-palette applied                        │
```

### Frontend Form Flow — "Solicitar Cotización" (current)

- Inputs stored in `quote` state.
- On submit, `validateQuote()` runs a synchronous check; errors shown inline.
- On success, sets `quoteSubmitted = true`. **No network request is made** — the backend endpoint does not exist yet.

### Integration Patterns

| Pattern | Status | Where |
|---------|--------|-------|
| Synchronous REST calls | Active | Frontend → Rails `/api/*` |
| Async background jobs | Scaffolded | `app/jobs/` via `solid_queue` — no jobs defined yet |
| WebSocket (Action Cable) | Scaffolded | `solid_cable` configured — no channels yet |
| Event-driven | Not planned for v1 | — |
| Third-party integration | Planned | Payment gateway, insurance provider, ARCA, GPS/maps |

### Background Job Processing

- Queue adapter: `solid_queue` (DB-backed).
- Jobs inherit from `ApplicationJob`.
- Workers run as a separate process (`bin/jobs` or `bundle exec rake solid_queue:start` depending on config).
- No jobs currently implemented; when added they should handle e.g. tracking webhook ingestion, ARCA invoice emission, payment settlement, and notification emails.

---

## Document Information

| Attribute | Value |
|-----------|-------|
| Version | 1.1 |
| Generated | 2026-04-17 |
| Last updated | 2026-05-03 |
| Scope | Truckr® platform (backend + frontend + AI harness) |
