# PRD — Shipper Dashboard v2

> Cargo-centric command-center dashboard for **Shippers** (Expedidores) at a new route
> `/shipper/dashboard`. Reworks the current flat shipment-list view into an at-a-glance
> overview of the whole cargo lifecycle.

## Problem Statement

A Shipper today lands on `/shipper/shipments`, a flat sorted list of *accepted* shipments,
and a separate `/shipper/cargos` list of published cargos. To answer simple questions —
"which of my cargos still has no offers?", "what do I owe?", "what's in transit right now?",
"who do I still need to rate?" — the Shipper must hop between pages and read rows one by one.
There is no single screen that shows the state of their freight pipeline or surfaces the
actions that need their attention.

## Solution

A single **command-center dashboard** that a Shipper sees first after login. It presents the
entire cargo lifecycle as a **5-stage Kanban board**, surfaces required actions in an
**"Atención requerida"** panel, greets the Shipper by name with a primary **"Publicar carga"**
call to action, and shows a **"Actividad reciente"** feed of the latest events across their
freight. Every number and card on the screen is derived from data the backend already exposes
(or can expose via a trivial attribute/endpoint addition) — no new model columns, no schema
changes, no heavy backend work.

## User Stories

1. As a Shipper, I want to be greeted by name when I open my dashboard, so that the workspace feels personal and I know I'm logged into the right account.
2. As a Shipper, I want a prominent "Publicar carga" button at the top of my dashboard, so that I can start the most common task (publishing freight) in one click.
3. As a Shipper, I want to see all my cargos arranged by lifecycle stage on one board, so that I understand the state of my entire freight pipeline at a glance.
4. As a Shipper, I want a "Buscando transporte" column listing cargos that are open with no offers yet, so that I know which freight still needs carrier interest.
5. As a Shipper, I want a "Con ofertas" column listing open cargos that have received offers, so that I know which cargos are waiting for me to review and accept an offer.
6. As a Shipper, I want an "Ofertas aceptadas" column listing shipments where I accepted an offer but haven't paid, so that I know what's pending payment to move forward.
7. As a Shipper, I want an "En tránsito" column listing shipments currently being delivered, so that I can monitor active deliveries.
8. As a Shipper, I want an "Entregadas" column listing completed deliveries, so that I have a record of fulfilled freight and can act on post-delivery tasks (rating).
9. As a Shipper, I want each board card to show the route (origin → destination), so that I can identify the cargo without opening it.
10. As a Shipper, I want each board card to show the relevant price (declared value, offered amount, or agreed amount depending on stage), so that I can gauge value at a glance.
11. As a Shipper, I want each board card to show a status badge appropriate to its column, so that exceptional states (e.g. "Pago pendiente", "Sin ofertas") stand out.
12. As a Shipper, I want to click any card to open its full detail (cargo detail or shipment detail), so that the dashboard is a navigation hub, not a dead end.
13. As a Shipper, I want each column to show a count of how many cargos it holds, so that I can quickly read the shape of my pipeline.
14. As a Shipper, I want an "Atención requerida" panel that summarizes everything needing my action, so that I never miss a payment, an un-reviewed offer, or a pending rating.
15. As a Shipper, I want the panel to tell me how many shipments are awaiting payment ("Envíos por pagar"), so that I can settle them and unblock transit.
16. As a Shipper, I want the panel to tell me how many cargos have no offers yet ("Cargas sin ofertas"), so that I can consider editing or re-publishing them.
17. As a Shipper, I want the panel to tell me how many delivered shipments I still need to rate ("Transportistas por calificar"), so that I close the loop on completed jobs.
18. As a Shipper, I want each attention item to link directly to the relevant cargo/shipment (or a filtered view), so that the alert is actionable in one click.
19. As a Shipper, I want a "Actividad reciente" feed showing the latest events across my freight (offers received, offers accepted, payments, transit started, deliveries), so that I have a chronological pulse of what's happening.
20. As a Shipper, I want each activity item to be timestamped with a human-friendly relative time (e.g. "hace 2 h"), so that I understand recency without parsing dates.
21. As a Shipper, I want a clear empty state on the board and feed when I have no cargos yet, so that a brand-new account is guided toward publishing their first cargo instead of seeing a blank screen.
22. As a Shipper, I want a clear empty state per column when that stage has no cargos, so that an empty column reads as "nothing here yet" rather than broken.
23. As a Shipper, I want the dashboard to show a loading state while data is fetched, so that I'm not staring at a flash of empty content.
24. As a Shipper, I want a graceful error state with a retry action if the dashboard fails to load, so that a transient network problem doesn't strand me.
25. As a Shipper, I want the dashboard to be reachable from the top navigation ("Inicio"), so that I can always return to my command center.
26. As a Shipper on a narrow screen, I want the Kanban columns to reflow gracefully (horizontal scroll or stacking), so that the dashboard is usable on smaller viewports.
27. As a Shipper, I want the dashboard to respect the existing role guard, so that only authenticated Shippers can see it and a non-shipper is handled consistently with the rest of the app.
28. As a Shipper using a screen reader, I want the board, panel, and feed to be properly labelled regions with semantic headings, so that I can navigate the dashboard non-visually.

## Implementation Decisions

### Routing & shell
- New route `/shipper/dashboard`, nested under the existing `<ShipperLayout>` (inherits the `RequireShipper` guard and app chrome). It becomes the natural "Inicio" landing for Shippers.
- The existing `/shipper/shipments` and `/shipper/cargos` pages remain as drill-down/detail destinations; the dashboard links into them. This is a *rework that adds an overview layer*, not a deletion of existing views.

### Data sourcing (no schema changes)
- The board and panel are composed **client-side** from two existing endpoints:
  - `GET /api/shippers/me/cargos` → cargos with nested offers (drives columns 1–2 and the "sin ofertas" alert).
  - `GET /api/shippers/me/shipments` → shipments (drives columns 3–5 and the "por pagar" alert).
- A **deep, pure module** `buildDashboardModel(cargos, shipments)` maps raw API rows into a view model: `{ columns: {searching, withOffers, acceptedOffers, inTransit, delivered}, attention: {toPay, withoutOffers, toReview}, ... }`. This is the testable core — it has no React, no fetch, and rarely changes. Column assignment rules:
  - **Buscando transporte** = `cargo.status == "open"` AND `offers.length == 0`.
  - **Con ofertas** = `cargo.status == "open"` AND `offers.length > 0`.
  - **Ofertas aceptadas** = `shipment.state == "accepted"`.
  - **En tránsito** = `shipment.state == "in_transit"`.
  - **Entregadas** = `shipment.state == "delivered"`.
  - Cancelled cargos/shipments are excluded from the board.
- Card price by stage: open cargos show `declared_value_cents`; cargos with offers show the best/lowest offer amount; shipments show their agreed `amount_cents`.

### Attention panel
- **Envíos por pagar** = count of shipments with `state == "accepted" && payment_escrowed == false`.
- **Cargas sin ofertas** = count of open cargos with zero offers.
- **Transportistas por calificar** = count of delivered shipments the Shipper has not yet reviewed.

### Trivial backend additions (allowed scope only)
- **Expose review status on the shipment list** (`GET /api/shippers/me/shipments`): add a boolean such as `shipper_reviewed` (derived from the already-existing `Review` association — *exposing an existing attribute*, no new column). This unblocks the "Transportistas por calificar" count without N+1 detail fetches.
- **Activity feed:** prefer a trivial read-only endpoint `GET /api/shippers/me/activity` that returns the Shipper's existing `TrackingEvent` records (already an append-only log) ordered by recency, capped (e.g. last 20). This *exposes an existing model* with no new columns. If during implementation this proves non-trivial (auth scoping, serialization surface), the feed falls back to a **client-derived** timeline synthesized from offers + shipment timestamps already in the two list responses, and the richer TrackingEvent feed is deferred to `.claude/tmp/` with rationale.

### Frontend composition
- `ShipperDashboardPage` (container): fetches the two lists, manages loading/error/empty, calls `buildDashboardModel`, renders sections.
- Presentational sub-components: `DashboardGreeting`, `AttentionPanel`, `CargoBoard` → `BoardColumn` → `BoardCard`, `ActivityFeed`. Each is dumb (props in, markup out) so they're trivially testable and reusable.
- All Spanish copy lives in a new `shipperDashboardContent.ts` bundle (prototype-stage i18n pattern). No hardcoded Spanish literals in JSX.
- Styling via a new `shipperDashboard.css` using existing design tokens (oklch/color-mix, 4pt spacing scale, flat-by-default, pill radius only for interactive). Shipper voice = sky-blue (`--brand-primary`). No raw hex, no side-stripe borders, no `background-clip:text` (stylelint-enforced bans).
- Reuse the existing `Button` (CVA) component for CTAs and the relative-time / formatting helpers if present.

## Testing Decisions

- **Good test = external behavior, not implementation.** Assert on what the Shipper sees and can do (rendered counts, column membership, links, empty/error/loading states), not on internal function calls or CSS class names.
- **`buildDashboardModel` (deep module)** gets thorough unit tests in isolation: column bucketing for every status, exclusion of cancelled, attention counts (toPay/withoutOffers/toReview), price selection per stage, and degenerate inputs (empty arrays, all-cancelled). This is the highest-value, lowest-cost coverage.
- **`ShipperDashboardPage`** gets React Testing Library + MSW/`vi.mock` tests mirroring `ShipperShipmentsPage.test.tsx` prior art: loading skeleton, populated board with cards in the right columns, attention-panel counts, empty state for a new account, and error + retry.
- **Presentational components** get light render tests where they hold logic worth checking (e.g. badge selection, empty column copy).
- **E2E (Playwright)** covers the golden path: a Shipper logs in, lands on the dashboard, sees their pipeline, and clicks a card to reach detail — reusing the existing register/login e2e pattern and the test backend.
- **Backend (RSpec)** request specs cover the new/changed serializer attribute and (if built) the activity endpoint: shape, auth (shipper-only), and scoping to the current shipper. Maintain or improve SimpleCov coverage. Frontend coverage must stay ≥ 80% (lines/functions/branches/statements).

## Out of Scope

- Drag-and-drop between Kanban columns. The board is read/navigate-only; stage transitions happen through existing flows (accept offer, pay, carrier-driven transit/delivery).
- Any new model columns, schema migrations, state-machine changes, or Postgres-only features (SQLite-forever policy).
- Real-time live-updating of the board beyond the existing notifications mechanism; the dashboard fetches on mount (a manual refresh affordance is acceptable but not required).
- A full i18n library migration — the dashboard uses the existing content-bundle convention.
- Carrier-side dashboard (this PRD is Shipper-only).
- Editing/cancelling cargos or initiating payment *inline* on the board (these remain on their existing dedicated pages, linked from the cards/alerts).
- Insurance/Seguro (not in MVP).

## Further Notes

- Lifecycle column mapping is the crux: cargos and shipments are two backend resources representing two halves of one Shipper-facing lifecycle. The dashboard is the first surface to stitch them into a single continuum, which is exactly why a pure `buildDashboardModel` module is worth extracting and testing hard.
- Any feature visible in the concept that cannot be honestly backed by current data (e.g. a richer activity feed, certain badge semantics) will be **deferred and documented in `.claude/tmp/` with reasons**, per the task constraint, rather than faked.
- Glossary alignment: `Shipper` ↔ Expedidor, `Carrier` ↔ Transportista. UI copy is Spanish; all code/routes/identifiers are English.
