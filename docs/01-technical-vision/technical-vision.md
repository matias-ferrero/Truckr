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
**Decision (amended 2026-05-22 — REQ-BE-00034)**:

- **Soft-delete enabled** on `Shipment`, `Payment`, `ArcaInvoice` and `Vehicle` — these carry fiscal / contractual significance or must be preserved for historical traceability (Vehicle is preserved because of the Shipment ← CargoOffer ← TransportWindow ← Vehicle chain).
- **Hard-delete** on `Carrier`, `Shipper`, `TransportWindow`, `CargoOffer`, `Quote`, `TrackingEvent`, `Route`, `InsurancePolicy`. Cascade rules expressed via Rails `dependent: :destroy` / `:nullify` per relation (specifics in `domain-model.md`).
- No gem mandated. The Phase-0 implementation is a `deleted_at` column, a default scope (`where(deleted_at: nil)`) only on the three audit-bearing models, and explicit `unscoped` for admin reads.

**Consequences**: Most tables stay simple. Unique indexes on the soft-deleted tables must be partial (`WHERE discarded_at IS NULL`) where uniqueness is meaningful — supported in SQLite ≥ 3.8 (our target). The canonical column name is `discarded_at` (historical references to `deleted_at` in older docs remain as historical notes). Reports that need historical rows must use `unscoped` / `with_discarded` explicitly.

### ADR-010 — Geo storage: lat/lng columns, application-level distance math

**Context**: ADR-002 keeps SQLite as the production DB permanently (see `CLAUDE.md` § "Database policy"). PostGIS requires PostgreSQL and is therefore off the table. Tracking, routing, and "transportistas dentro de N km" features need to **store** coordinates and answer city / proximity queries — both achievable without spatial indexes at the scale this project will ever reach.
**Decision**:

- Latitude / longitude stored as `DECIMAL(9,6)` columns directly on `tracking_events`, `routes`, `transport_windows` and `cargo_offers` (origin / destination pairs). The original draft of this ADR also persisted `(province, city)` strings alongside the coordinates — those columns were dropped by ADR-014 once US48 / US49 made geocoded pins authoritative on every matching-relevant entity. Address text is still stored for display (`origin_address` / `destination_address` / `pickup_address` / `delivery_address`) but never queried; parsed `_locality` + `_admin_area` columns are likewise display-only.
- No spatial index, no PostGIS, no GIN/GIST indexes. There is no "find by city" path — discovery is address-driven (see ADR-014).
- "Within N km" queries compute Haversine distance in Ruby over a candidate set narrowed by a coarse lat/lng bounding-box filter (`WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?`). The `(province, city)` narrowing variant described in the original draft of this ADR was retired by ADR-014: matching is address-driven and runs over the bbox prefilter alone, never over province strings. For routing distances, call an external API (Google Maps Distance Matrix / OSRM) — no spatial storage required.

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

### ADR-012 — `Payment` model: per-attempt rows, born-terminal `escrowed | failed`, fake gateway in production

**Amended 2026-05-24** — Payment FSM tightened to canonical born-terminal `escrowed | failed`; `pending` state and `abandon` / `return` endpoints removed. Shipment FSM line aligned to canonical `accepted → in_transit → delivered` (+ terminal `cancelled`).

**Context**: US8 (Shipper realiza el pago) lands in sprint 3 (REQ-BE-00033). Earlier drafts of `domain-model.md` § 5.1 specified a `Payment` FSM with five states (`pending / escrowed / released / refunded / disputed`), a 1:1 relationship with `Shipment`, and an automatic Payment row opened in `escrowed` as a side effect of `Shipment.accept!`. That design assumed (a) a real MercadoPago integration with webhook callbacks, (b) a settlement job that releases escrow on delivery, (c) refund / dispute flows in scope for the MVP, and (d) at most one payment attempt per Shipment. None of those assumptions hold for the MVP — MercadoPago integration is mocked, settlement is out of scope, refund / dispute are post-MVP, and AC9 (retry after rejection) requires multiple attempts per Shipment.

**Decision**:

- **`Payment` belongs to `Shipment`**, not `CargoOffer`. Documented `Shipment 1:N Payment`. Per-attempt rows: each "Pagar" click creates a new `Payment` row that is born terminal in `escrowed` (success) or `failed` (rejection) — no intermediate `pending` row. Failed attempts are kept (soft-deleted via the `discard` gem, per ADR-009) — supports forensics on "why did this Shipment have three failed charges?".
- **FSM (MVP)**: `escrowed | failed`, **both born terminal**. Each gateway attempt yields exactly one `Payment` row in its final state — there is no `pending`, no `released`, no `refunded`, no `disputed`, and no transitions between states. Re-introducing intermediate or post-escrow states requires a real-gateway integration and is out of scope.
- **`Payment.amount_cents`** is frozen from `CargoOffer.price` at create.
- **`Payment.provider`** enum: `fake | mercadopago | stripe | other`. The MVP writes `fake` for every row; the column exists from day 1 so the real-gateway swap-in does not require a data migration.
- **No "paid" state on `Shipment`**. The canonical Shipment FSM is `accepted → in_transit → delivered`, with `cancelled` as a terminal branch reachable from `accepted` or `in_transit`; payment status never collapses into it. "A recoger" (AC2 wording) is a UI-derived label gated on `shipment.payments.escrowed.exists?`, not a canonical state. Rationale: keeps the Shipment FSM aligned with physical events.
- **Gateway abstraction**: `Payments::Gateway` Ruby interface (`create_intent`, `confirm!`). `Payments::FakeGateway` is the MVP implementation; it lives in `app/services/payments/` and is mounted in **all environments including production**. The fake gateway IS the production gateway for the MVP — it is not behind an environment guard or feature flag. Cost of the real-MP swap-in is a single new class implementing the same interface plus DI config.
- **API surface**: `POST /api/shipments/:id/payments` (create — the request synchronously calls the gateway and persists exactly one born-terminal `escrowed` or `failed` row inside a `with_lock`, together with any Shipment-side effects). No gateway return URL, no abandonment endpoint, no webhook — the FakeGateway resolves in-process during the same request.
- **Carrier contact-info reveal**: implemented as a scoped `CarrierResource` whose response includes `email` / `phone` / `full_name` only when `CarrierPolicy#can_view_contact?(current_shipper)` returns true. The predicate is `shipment.payments.escrowed.exists?` for the Shipper's accepted offer.

**Consequences**:

- Doc surface updated in lockstep: `domain-model.md` § 1 (1:1 → 1:N), § 3 (drop "open Payment row" side effect on accept), § 4.1 (add "payment as predicate" callout), § 5.1 (FSM collapsed to born-terminal `escrowed | failed`); `api-overview.md` (single `POST /api/shipments/:id/payments` route, no return URL, no abandon, no webhook); `external-systems.md` (fake gateway is the production gateway); `scheduled-jobs.md` (`PaymentSettlementJob` removed); `glossary.md` (`Pasarela falsa` added).
- Post-MVP delta is concrete and small: introduce intermediate / post-escrow states (e.g. `pending`, `released`, `refunded`, `disputed`) only when a real gateway with asynchronous callbacks lands; add `PaymentSettlementJob` and the dispute flow at that point; add a real-gateway adapter (`Payments::MercadoPagoGateway`), keep the fake one for QA / e2e tests.
- Per-attempt rows mean policy / authorization queries always filter by status: any `shipment.payments.escrowed.exists?`-style predicate is one index away (`payments(shipment_id, status)`).
- "Fake gateway in production" is a deliberate, documented surface. It is acceptable because (a) this is academic coursework not a real product (per `CLAUDE.md`), (b) the alternative — env-gating the gateway — would require a second always-broken code path that never gets exercised in production. The fake gateway is the canonical path until a real adapter lands.

### ADR-013 — In-app notifications: best-effort live delivery, no offline queue

**Context**: Several sprint-4+ features need to push state changes to the user in real time — payment confirmed, offer accepted, shipment state transitions, new offer received, etc. Before wiring any of them, a single transport + contract is being scaffolded (`INF-FE-00005`). The framework's delivery semantics shape every consumer that follows.

Most notification systems developers have encountered (Slack, Discord, Linear) persist notifications server-side and offer "unread / missed" views. That model is the implicit baseline a future feature builder will assume unless this decision is documented.

**Decision**:

- **Transport**: Action Cable (Rails 8 built-in) backed by **Solid Cable** (DB-backed pub/sub via `solid_cable_messages` table on the primary SQLite DB — consistent with ADR-002 / `CLAUDE.md` § "Database policy"). No Redis, no external pub/sub, no separate WebSocket service. Single Kamal container serves both HTTP and WS upgrades.
- **Delivery semantic**: **best-effort live delivery only.** A notification is broadcast to the recipient's WS stream at publish time and **lost** if no WebSocket is open. Solid Cable does not store-and-forward.
- **No `notifications` table.** No server-side persistence. No "missed notifications" view. No `read_at` / "mark as read" server-side. The frontend's in-session list is the only history that exists, and it dies with the browser tab.
- **Source-of-truth lives in the REST API.** Every feature that emits a notification **must** also expose a REST/poll path so the client can reconstruct the same state on reload — the notification is a UX accelerator, not a domain event. Example: "payment confirmed" pushes a toast, but the shipper's payment-confirmed state is still derivable from `GET /api/payments/:id`.
- **Contract entry point**: `Notifications::Publisher.publish(user_id:, type:, payload:)`. `type` is a closed whitelist in `Notifications::Type` (constants, raises on unknown). Synchronous broadcast via `NotificationsChannel.broadcast_to(user, message)`. Payload validated to be a JSON-serializable Hash; `emitted_at` is server-injected.
- **WS auth**: JWT in query string (`wss://…/cable?token=<jwt>`), decoded with `Warden::JWTAuth::UserDecoder` in `ApplicationCable::Connection#connect` (consistent with ADR-011). Browsers can't attach `Authorization` headers to a native `WebSocket(url)`, and the cookie-based Action Cable pattern doesn't apply because Devise+JWT runs without sessions. `token` is filtered from logs.

**Alternatives considered**:

- **Durable delivery with `notifications` table + ack flow + retry** — what most developers expect. Rejected: needs schema, audit of every consumer to persist before broadcasting, plus a "mark as read" surface. Cost is high; benefit (a feature builder can fire-and-forget without thinking about reload state) does not match an academic-scope product where REST is already the source of truth and traffic is low.
- **SSE (`ActionController::Live`)** — simpler transport, no WS upgrade in the proxy. Rejected: unidirectional, one HTTP connection per tab, manual reconnect logic, no native channel-class scoping (collides with future per-user streams like presence / live chat).
- **Polling** — zero infrastructure. Rejected: laggy UX, constant CPU/DB cost even when nothing's happening, not real-time.
- **Redis-backed Action Cable** — the Rails-pre-8 default. Rejected: violates `CLAUDE.md` § "Database policy" (no external infra beyond SQLite + Kamal).

**Consequences**:

- Future REQ-BE/FE features that emit notifications **must** also have a REST recovery path. PR review must enforce this — a feature that relies on a notification as the only way the client learns about a state change is a defect. This is a non-obvious contract that future feature builders inherit silently; document in `CLAUDE.md` or feature-template if it gets missed twice.
- "Notify all carriers in zone X" (high-fan-out broadcast) is **not** supported by this framework — same publisher path requires a fan-out loop and would amplify Solid Cable INSERT cost. If/when needed, scoped revisit.
- Multi-tab UX: the user sees the notification in **every** tab where they have a WS open. Each tab maintains its own in-session history; closing one doesn't affect the others.
- If Solid Cable proves problematic on SQLite under low concurrency (WAL contention with hot-path writes), fallback is the `async` adapter (in-process, single-container — already the deploy reality per Kamal + ADR-002). No fallback to Redis or external pub/sub: that reopens the `CLAUDE.md` infra policy.
- Promoting the framework to durable delivery later is a **breaking** change — every consumer would need to adopt a persistence call. The "every consumer has a REST recovery path" rule is what makes that promotion cheap-to-reverse: if durability becomes load-bearing, the REST paths already exist as the source of truth and only the consumer's *recovery moment* moves from "on user reload" to "on background reconnect".

### ADR-014 — Address-driven matching; province narrowing dropped

**Context**: ADR-010 originally listed two equivalent ways to narrow the Haversine candidate set: a `(province, city)` B-tree prefilter or a coarse lat/lng bounding-box filter. The `(province, city)` path was the agreed perf story before geocoded inputs existed — `transport_windows` carries `origin_province` (`NOT NULL`) + `origin_locality` + `destination_province` + `destination_locality` (each with a `_normalized` sibling for diacritic-insensitive Ransack), and `cargos` carries `pickup_zone` + `delivery_zone` (each `_normalized`). With US48 (`REQ-FE-00025` / `REQ-BE-00036`) the publish-window form moved to a Google Places picker that captures `origin_lat` / `origin_lng` / `destination_lat` / `destination_lng` at `DECIMAL(9,6)`; US49 (`REQ-FE-00026`) did the same for the cargo's pickup / delivery pins; US50 (`REQ-FE-00027` / `REQ-BE-00037`) added `pickup_radius_km` and the Haversine matcher in `Cargo#matching_windows`, gated on the pickup pin. The province / locality columns are now UX dead weight — the publish forms no longer surface them, the Haversine path supersedes string equality semantically, and keeping two parallel prefilters (`(province, city)` Ransack matchers *plus* the new Haversine path) duplicates intent and lets the two drift.

A second branch of the same decision: the matcher today filters on pickup proximity only. The destination is still expressed as either a fixed lat/lng or the "open destination" flag (`destination_lat` / `destination_lng IS NULL`). There is no symmetric "how far am I willing to deviate at drop-off?" knob — the Carrier publishing the window has no way to say "I'll go anywhere in the Pampas humid, but not Patagonia". This forces Carriers to either over-narrow with a precise destination pin or open the destination entirely.

**Decision**:

- **Drop the province / locality columns from the schema entirely.** `transport_windows.{origin_province, origin_province_normalized, origin_locality, origin_locality_normalized, destination_province, destination_province_normalized, destination_locality, destination_locality_normalized}` and `cargos.{pickup_zone, pickup_zone_normalized, delivery_zone, delivery_zone_normalized}` go away in one destructive migration, along with the four indexes on the `_normalized` siblings. The `Carrier.province` + `Carrier.base_city` profile fields and the carrier-signup `ProvinceSelect.tsx` component survive untouched — they're profile metadata for the public Carrier detail page, not matching inputs.
- **Persist the human-readable address.** Add `transport_windows.origin_address` / `transport_windows.destination_address` (`TEXT`, non-null on origin, nullable iff destination is open) to mirror `cargos.pickup_address` / `cargos.delivery_address` which already exist. The address is Google's `formatted_address` verbatim and is for display only — it never drives matching.
- **Add parsed structured-locality columns**: `origin_locality` + `origin_admin_area` on `transport_windows`, plus the destination pair (nullable iff open destination); `pickup_locality` + `pickup_admin_area` + `delivery_locality` + `delivery_admin_area` on `cargos`. These are extracted client-side from Google's `address_components` (cascade: `locality → sublocality_level_1 → administrative_area_level_2 → formatted_address.split(",")[0]`) via a new frontend helper `frontend/src/lib/places.ts`; the backend persists what the FE sends. **Display only — never queried during matching.** Card label format: `"Locality, AdminArea → Locality, AdminArea"` (e.g. `"CABA, Buenos Aires → Córdoba, Córdoba"`); fallback `"Cualquier destino"` when the destination is open.
- **Matcher prefilter is a coarse lat/lng bbox bounded by the Carrier's pickup radius cap.** Introduce a constant `PICKUP_RADIUS_KM_MAX = 200` (already enforced as the upper bound of `pickup_radius_km` validation per US50). Bbox math at the cargo latitude — degree-per-km converted at the cargo's `pickup_lat` so the longitude span widens correctly near the equator and narrows near the poles. The bbox is a SQL `WHERE` clause directly on `transport_windows.origin_lat` / `origin_lng` indexed columns; Ruby Haversine then trims the candidate set to the actual radius. No `(province, city)` filter is consulted at any layer.
- **Add `dropoff_radius_km` to `transport_windows`**, symmetric to `pickup_radius_km`. Range 1–200 km. Anchored at `destination_lat` / `destination_lng`. `NULL` iff `destination_lat` / `destination_lng` are also `NULL` (open destination) — both columns are NULL together, never just one. When the destination is open, the matcher skips the dropoff filter entirely. When the destination is set, a cargo is compatible only if its `delivery_lat` / `delivery_lng` falls within `dropoff_radius_km` of the window's `destination_lat` / `destination_lng` (Haversine, same path as pickup). Radius changes (up or down) do NOT invalidate existing `CargoOffer`s in `pending` against this window — same principle as `pickup_radius_km`, the radius is a discoverability filter, not a retroactive constraint on commitments already made.
- **Delete the public marketplace endpoint** `GET /api/transport_windows`. Public discovery of windows by an Expedidor was the only consumer of the province-based Ransack matchers; with those gone, the endpoint has nothing useful left. Browse runs through `GET /api/cargos/:id/matches` exclusively — the Expedidor lands on a Cargo and sees the windows that match it, never browses the window catalog blind. Carrier self-service (`GET /api/carriers/me/transport_windows`) and AA admin paths are untouched.
- **Sort key stays pickup distance only.** No re-shuffle for the dropoff radius — the dropoff filter narrows the result set but does not re-order it.
- **Migration is destructive.** Truncate `transport_windows`, `cargos`, `cargo_offers`, `shipments`, and any dependent rows (`tracking_events`, `routes`, `payments`). Acceptable because this is academic coursework with no production data; the alternative (a forward migration that hand-parses province strings into pseudo-coordinates) is engineering effort with zero upside.
- **Address-component parsing lives on the FE.** Wire format: the FE sends already-parsed `_locality` / `_admin_area` strings alongside `lat` / `lng` / `address`; the BE persists what it receives and does not re-parse `address_components`. The contract is documented in the plan file; the helper itself (`frontend/src/lib/places.ts`) lands as part of the implementation PR.
- **Dropoff UX.** Refactor `frontend/src/components/PickupRadiusControl.tsx` into a generic `RadiusControl(anchor, role)` that the publish-window form mounts twice: once at the origin pin (role `pickup`), once at the destination pin (role `dropoff`). Same draggable map circle, same numeric input synced to the circle, same i18n keys parameterised by role.

**Consequences**:

- One destructive migration drops eight columns + four indexes from `transport_windows`, four columns + two indexes from `cargos`, and truncates five tables. The new schema is two columns wider on `transport_windows` (`origin_address`, `destination_address`, `dropoff_radius_km`) and four columns wider on the structured-locality side, but every new column is display-only — none ever appears in a `WHERE` clause.
- `Cargo#matching_windows` collapses to bbox prefilter + Haversine pickup + (Haversine dropoff OR `destination_lat IS NULL` skip). The `_normalized` Ransack stack on `TransportWindow.ransackable_attributes` shrinks accordingly. `I18n.transliterate` callbacks on `transport_window.rb` are removed.
- The public `GET /api/transport_windows` route is deleted from `config/routes.rb` and `Api::TransportWindowsController` is removed in full; the corresponding FE marketplace browse path (if any) is removed in the same PR. AA admin filters that referenced the dropped columns are rewritten to use lat/lng + address strings; specifics are tracked in the plan file's "BE changes" section.
- Structured `_locality` + `_admin_area` are parsed from Google `address_components` for display only and never drive matching. The bbox prefilter gives correctness via Haversine and bounded perf via the 200 km cap. Per `CLAUDE.md` § "Database policy" this is the final SQLite-compatible matcher — no Phase-2 PostGIS, no `unaccent`, no managed-Postgres escape hatch.
- Carrier signup is unchanged: `Carrier.province` + `Carrier.base_city` stay on the schema, `ProvinceSelect.tsx` keeps its existing one consumer, no migration touches the `carriers` table.
- One umbrella User Story ("Migrar a matching dirigido por dirección") in `docs/artifacts/backlog-us.typ` supersedes the province-driven phrasing in US3 / US5 / US9 / US50 and adds a sibling AC chain for `dropoff_radius_km`. The four existing US ACs are edited in place where they referenced province semantics; the new US bundles every cross-cutting concern (schema delta, FE forms, endpoint deletion, destructive migration).

**Alternatives rejected**:

- **Keep `(province, city)` as a parallel discoverability filter alongside Haversine.** Carriers and Expedidores already select an address with a pin; a second narrowing input that they have to fill consistently with the pin is UX dead weight and a guaranteed drift surface (Buenos Aires the city ≠ Buenos Aires the province, etc.). Two prefilters that should always agree but can disagree is worse than one prefilter that is the source of truth.
- **Express destination flexibility as a huge `dropoff_radius_km`** (e.g. 999 km) instead of `destination_lat / destination_lng IS NULL`. Semantically wrong — "open destination" means the Carrier has no preferred end point at all, not "any end point within 999 km of this specific point". The NULL form lets the matcher skip a Haversine call cleanly; the huge-radius form bakes a magic number into the schema and breaks if the country gets bigger.
- **Shipper-side `delivery_radius_km` on `cargos`** instead of carrier-side `dropoff_radius_km` on `transport_windows`. Considered and rejected by the user during design grilling: the radius semantics ("how far am I willing to deviate") belongs to the side doing the deviating, and pickup already lives on the Carrier side. Asymmetric ownership would also force Expedidores to think about routing slop, which is the Carrier's domain.
- **Forward-migrate province strings into pseudo-coordinates** instead of truncating. Engineering effort with zero upside on coursework data; the destructive path is faster, simpler, and acceptable under the project's scope (no production users).

### ADR-015 — Shipment detail stays one shared role-parameterized component; role divergence isolated to the rail

**Context**: The shipment detail page (`frontend/src/pages/shipments/ShipmentDetailPage.tsx`) is mounted twice — `/carrier/shipments/:id` and `/shipper/shipments/:id` — as a single component taking a `role: "carrier" | "shipper"` prop, with role branches scattered across ten vertically-stacked sections (action bar, payout block, pay banner, review forms, per-role CSS tints). The v2 overhaul (`docs/features/shipment-detail-v2.prd.md`) moves this to a sticky-rail + two-column layout where the primary action, money block, and contact card live in a pinned rail and the map + facts + timeline form a shared scrolling spine. That raised the structural question: should the overhaul **split** into `CarrierShipmentDetailPage` + `ShipperShipmentDetailPage` (killing the branching), or stay **one component** with the branching corralled?

The split option is not hypothetical — it is the precedent set by the dashboard work. The shipper dashboard v2 (PR #332) is a shipper-only page (`ShipperDashboardPage`) while carriers keep the older multi-section `DashboardPage`; the two dashboards are genuinely different products (a cargo kanban vs a carrier panel), so the split was correct there. A future reader who sees that precedent will reasonably ask why the detail page did *not* follow suit.

**Decision**:

- **Keep a single shared `ShipmentDetailPage` parameterized by `role`.** Do not split per role. The two sides are the **same shipment viewed from two ends of one contract**, not two products: origin/destination, route map, event timeline, facts (route/weight/vehicle/amount), and counterparty contact are byte-for-byte identical regardless of who is looking. Roughly 70% of the page is this shared spine.
- **Isolate all role/state divergence to the rail.** Extract `<PrimaryActionCard role state payment />` (the state×role matrix: Shipper-Pay/Retry/Waiting/Review, Carrier-Waiting/ConfirmarRetiro/ConfirmarEntrega/Payout) and `<MoneyBlock role />` (shipper agreed-amount vs carrier payout breakdown). The branching that is today smeared across ten sections collapses into these two rail components.
- **The main column stays role-agnostic, with exactly one deliberate exception**: the map's primary navigation button is role- and state-aware ("Navegar al retiro" / "Navegar a la entrega" for the Carrier by FSM state; "Ver ruta completa" for the Shipper). This exception is documented so it is not mistaken for drift back toward scattered branching.
- **Action buttons render strictly off the backend's `available_actions: string[]`** (safe by delegation); only the waiting/status/done *copy* is derived FE-side from `state` + `payment`. The rail's primary card is never a dead/disabled button — when a role cannot act it shows reassuring status.

**Consequences**:

- One component, one set of data wiring (`useShipmentDetail`), one i18n content module (`shipmentDetailContent.ts`), one route-level mount per role. Map/timeline/facts changes are made once and both roles inherit them — no duplicated spine to keep in sync.
- The "pervasive role branching" smell is resolved not by splitting but by *relocation*: divergence is concentrated in two named rail components plus the one documented map-button exception, instead of inlined across the page.
- The dashboard precedent is deliberately *not* followed; this ADR is the answer to "why didn't the detail page split too." The distinguishing test: split when the two roles see **different products**, share when they see **the same entity from opposite sides**.
- If role divergence later grows past the rail + nav-button exception (e.g. a carrier-only sub-page, a shipper-only sub-flow), this decision should be revisited — the shared-component bet is sized to the *current* ~70% overlap, not an unconditional rule.

**Alternatives rejected**:

- **Split into `CarrierShipmentDetailPage` + `ShipperShipmentDetailPage`.** Cleanest kill of the branching, matches the dashboard precedent — but duplicates the map, timeline, facts, and contact wiring plus the i18n bundle across two files, doubling the maintenance surface for the 70% that is identical. The branching is better corralled than duplicated.
- **Keep the status quo (branches inlined across all sections).** The thing the overhaul exists to fix; rejected by definition.

### Decisions Closed (not deferred)

- **Production database**: SQLite. Permanent. See `CLAUDE.md` § "Database policy" and ADR-002. No PostgreSQL migration is planned, queued, or under consideration.
- **Geospatial storage**: lat/lng columns + Haversine in application code + external API for routing. See ADR-010. No PostGIS, ever.
- **Authentication / authorization**: Devise + devise-jwt with JTI Matcher revocation. See ADR-011.
- **In-app notifications**: Action Cable + Solid Cable transport with best-effort live delivery; no `notifications` table, no offline queue, no missed-notifications view. See ADR-013.
- **Matching prefilter**: address-driven only. Province / locality strings are not persisted on matching-relevant entities, are not consulted by the matcher, and the public marketplace endpoint that exposed them is deleted. See ADR-014.

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
