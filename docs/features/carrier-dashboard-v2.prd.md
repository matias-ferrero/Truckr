# PRD — Carrier Dashboard v2

> Job-funnel command-center dashboard for **Carriers** (Transportistas) at a new route
> `/carrier/dashboard`. Replaces the old multi-section carrier landing with an at-a-glance
> response queue over the whole inbound-job lifecycle, mirroring the Shipper Dashboard v2.

## Problem Statement

A Carrier today lands on an old multi-section `DashboardPage` and must hop between
`/carrier/cargo-offers` (the offer inbox), `/carrier/shipments` (a flat list), and
`/carrier/payouts` to answer simple questions — "which offers are about to expire?",
"what do I have to pick up today?", "what's still owed to me?", "who do I still need to
rate?". There is no single screen that shows the state of their work pipeline or surfaces
the actions that need their attention.

The Carrier's posture is fundamentally different from the Shipper's. A Shipper *creates
demand* (publishes Cargo, sends offers) and is **proactive/outbound**. A Carrier *advertises
supply* (publishes TransportWindows) and then **responds to inbound offers** — they are
**reactive/inbound**. The dashboard is therefore best understood as a **response queue**,
not a creation surface.

## Solution

A single **command-center dashboard** that a Carrier sees first after login. It presents the
inbound-job lifecycle as a **5-stage Kanban board** that flows a job from an inbound offer to
a paid delivery, surfaces required actions in an **"Atención requerida"** panel, greets the
Carrier by name with a **progressive, context-aware** primary call to action, shows a quiet
**stats strip** of supply posture, and a **"Actividad reciente"** feed of newsworthy events.
Every number and card is derived from data the backend already exposes (or can expose via a
trivial attribute/endpoint addition) — no new model columns, no schema changes.

### Core asymmetry vs the Shipper dashboard (the design crux)

| | Shipper (v2, shipped) | Carrier (this PRD) |
|---|---|---|
| Primary act | Creates demand (publishes Cargo, sends offers) | Advertises supply (publishes TransportWindows), then responds to inbound offers |
| Central object | Cargo (their unit of work) | A *job* that begins as an inbound `CargoOffer` and ends as a paid `Shipment` |
| Board col 1 | Cargos with/without offers | Inbound `CargoOffer`s (pending) — the carrier's lifeblood |
| Urgent/coral | "Envíos por pagar" (money owed) | "Oferta vence pronto" (offer near `expires_at`) — the carrier never owes money |
| Positive feedback | — | "Pago recibido" + "Reseña recibida" (no shipper equivalent) |
| Voice | Sky-blue | **Honey Saffron** (contrast preserved) |

## User Stories

1. As a Carrier, I want to be greeted by name when I open my dashboard, so that the workspace feels personal and I know I'm logged into the right account.
2. As a Carrier, I want a primary call-to-action that adapts to my setup state, so that a brand-new carrier is told to add a vehicle, a carrier with no open window is told to publish one, and an established carrier sees "Publicar ventana".
3. As a Carrier, I want to see all my work arranged by lifecycle stage on one board, so that I understand the state of my entire job pipeline at a glance.
4. As a Carrier, I want an "Ofertas nuevas" column listing inbound offers awaiting my response, so that I know which jobs are waiting for me to accept or reject.
5. As a Carrier, I want offers that are about to expire highlighted in an urgent (coral) tone with a countdown, so that I respond before I lose the job.
6. As a Carrier, I want a "Por iniciar" column listing accepted shipments not yet picked up, so that I know what I have to collect.
7. As a Carrier, I want an "En tránsito" column listing shipments I'm currently delivering, so that I can track active jobs.
8. As a Carrier, I want an "Entregadas" column listing delivered shipments not yet settled ("por cobrar"), so that I know which jobs are awaiting payout.
9. As a Carrier, I want a "Pagadas" column listing settled shipments, so that I have a record of completed, paid work.
10. As a Carrier, I want each Ofertas-nuevas card to show the route (origin → destination, or "Destino abierto"), the cargo (weight · distance · price), and the shipper's identity and rating, so that I can vet the job and the counterparty before accepting.
11. As a Carrier, I want to accept or reject an inbound offer directly from its card, so that the most common action is one click from the dashboard.
12. As a Carrier, I want each shipment card to show its route, agreed amount, and a status badge, so that I can read the job without opening it.
13. As a Carrier, I want to click any card to open its full detail (offer inbox or shipment detail), so that the dashboard is a navigation hub, not a dead end.
14. As a Carrier, I want each column to show a count of how many jobs it holds, so that I can quickly read the shape of my pipeline.
15. As a Carrier, I want a quiet stats strip (vehículos · ventanas abiertas · calificación), so that I can read my supply posture at a glance without it competing with my action queue.
16. As a Carrier, I want an "Atención requerida" panel that lists only items with a concrete next action, so that it is a to-do queue and never noise.
17. As a Carrier, I want the panel to tell me how many offers await my response ("Ofertas nuevas por responder"), so that I never let a job lapse.
18. As a Carrier, I want the panel to tell me how many shipments are awaiting pickup ("Envíos por iniciar"), so that I can mark them started.
19. As a Carrier, I want the panel to tell me how many shipments are awaiting delivery ("Envíos por entregar"), so that I can mark them delivered and trigger my payout.
20. As a Carrier, I want the panel to tell me how many delivered shipments I still need to rate ("Expedidores por calificar"), so that I close the loop on completed jobs.
21. As a Carrier, I want each attention item to link directly to the relevant offer/shipment (or a filtered view), so that the alert is actionable in one click.
22. As a Carrier, I want a "Actividad reciente" feed showing newsworthy events — payouts settled, reviews received from shippers, and offer activity (received / accepted / rejected) — so that I have a chronological pulse of what's happening *to* me.
23. As a Carrier, I want each activity item timestamped with a human-friendly relative time (e.g. "hace 2 h"), so that I understand recency without parsing dates.
24. As a brand-new Carrier with no vehicle, I want a guided onboarding hero pointing me to add my first vehicle, so that I'm not staring at an empty board with nothing I can do.
25. As a Carrier with a vehicle but no open window, I want a hero prompting me to publish my first window, so that I become visible in the marketplace and start receiving offers.
26. As a Carrier, I want a clear empty state per column when that stage has no jobs, so that an empty column reads as "nothing here yet" rather than broken.
27. As a Carrier, I want the dashboard to show a loading state while data is fetched, so that I'm not staring at a flash of empty content.
28. As a Carrier, I want a graceful error state with a retry action if the dashboard fails to load, so that a transient network problem doesn't strand me.
29. As a Carrier, I want the dashboard to be my default landing after login (including when I hold both roles), so that it is always my command center.
30. As a Carrier on a narrow screen, I want the Kanban columns to reflow gracefully (horizontal scroll or stacking), so that the dashboard is usable on smaller viewports.
31. As a Carrier, I want the dashboard to respect the existing `RequireCarrier` guard, so that only authenticated Carriers can see it.
32. As a Carrier using a screen reader, I want the board, panel, stats strip, and feed to be properly labelled regions with semantic headings, so that I can navigate the dashboard non-visually.

## Implementation Decisions

### Routing & shell
- New route `/carrier/dashboard`, nested under the existing `<CarrierLayout>` (inherits the `RequireCarrier` guard and app chrome). It becomes the carrier's "Inicio" landing.
- `IndexRoute` redirects **every** carrier — including dual-role carrier+shipper — to `/carrier/dashboard`, retiring the old multi-section `DashboardPage` as the carrier landing.
- The existing `/carrier/cargo-offers`, `/carrier/shipments`, `/carrier/payouts`, `/carrier/availability` (windows), and `/carrier/vehicles` pages **survive unchanged** as drill-down destinations the dashboard links into. This is a *rework that adds an overview layer*, not a deletion.
- **Header consolidation:** the `cargo-offers` pill + `CarrierBadge` count and the `payouts` link are removed from `Header.tsx` for carriers; the live offer count migrates into the Atención panel. Header keeps brand + notifications + session widget only.

### Data sourcing (no schema changes)
- The board, panel, and stats strip are composed **client-side** from existing endpoints:
  - `GET /api/carriers/me/cargo-offers?status=pending` (→ `CarrierCargoOfferInboxResource`) → board column 1 ("Ofertas nuevas") and the "Ofertas nuevas por responder" alert; `expires_at` drives the coral urgency.
  - `GET /api/carriers/me/shipments` → board columns 2–5 and the "por iniciar" / "por entregar" alerts.
  - `GET /api/carriers/me/vehicles` (count), `GET /api/carriers/me/transport_windows` (open count), and the carrier profile (`rating_avg`) → the stats strip and the onboarding-ladder state.
- A **deep, pure module** `buildCarrierDashboardModel(offers, shipments, supply)` maps raw API rows into a view model: `{ columns: {newOffers, toStart, inTransit, delivered, paid}, attention: {offersToAnswer, expiringOffers, toStart, toDeliver, toReview}, stats: {vehicles, openWindows, rating}, onboardingStep }`. This is the testable core — no React, no fetch. Column assignment rules:
  - **Ofertas nuevas** = `cargo_offer.status == "pending"` (one card per offer; accepting one auto-rejects same-window competitors server-side, so no client-side grouping for MVP).
  - **Por iniciar** = `shipment.status == "accepted"`.
  - **En tránsito** = `shipment.status == "in_transit"`.
  - **Entregadas** = `shipment.status == "delivered"` AND `settled_at == null` (badge: "Por cobrar").
  - **Pagadas** = `shipment.settled_at` present.
  - Cancelled shipments (`status == "cancelled"`) are **excluded** from the board; they remain reachable via the filtered `/carrier/shipments` drill-down.
- Card price: offer cards show `price_amount_cents`; shipment cards show the agreed `amount_cents`. Monetary figures are always saffron-tinted (per DESIGN.md money rule).

### Attention panel (strictly actionable)
Governing rule: **a row earns a place only when there is a concrete next action.** Observations with no remedy the carrier controls (e.g. "an open window has no offers yet") are **not** alerts — they're ambient at best.
- **Ofertas nuevas por responder** = count of pending offers. → aceptar/rechazar.
- **Oferta vence pronto** (urgent, coral) = pending offers within a near-expiry threshold of `expires_at`. → responder. *This is the only coral category — the carrier's structural equivalent of the Shipper's "por pagar" urgency.*
- **Envíos por iniciar** = accepted shipments whose pickup date has arrived. → marcar iniciado.
- **Envíos por entregar** = in-transit shipments. → marcar entregado (triggers payout).
- **Expedidores por calificar** = delivered shipments the Carrier has not yet reviewed (`Review.carrier_authored`). → calificar.
- **Onboarding nudges** (zero-state, actionable): "No tenés ningún vehículo" → agregar; "No tenés ninguna ventana abierta" → publicar.

### Trivial backend additions (allowed scope only)
- **Shipper rating on the offer inbox** (`CarrierCargoOfferInboxResource`): the serializer already exposes the shipper's `id` + `name`; add the shipper's `rating_avg` (and review count) — *exposing an existing attribute* — so the Ofertas-nuevas card can show the rating the carrier needs to vet the counterparty.
- **Carrier-review status on the shipment list** (`GET /api/carriers/me/shipments`): add a boolean `carrier_reviewed` derived from the existing `Review` association (mirror of the shipper's `shipper_reviewed`) — no new column — to drive the "Expedidores por calificar" count without N+1 detail fetches.
- **Activity feed:** a trivial read-only endpoint `GET /api/carriers/me/activity` (mirror of `GET /api/shippers/me/activity`) returning, newest-first and capped (~20): payout-settled events, reviews received from shippers (`shipper_authored`), and offer events (received / accepted / rejected). *Shipment lifecycle milestones the carrier triggers themselves are deliberately excluded* — they are a self-authored log, not news. If scoping proves non-trivial, the feed falls back to a **client-derived** timeline from the data already in the list responses, with the richer endpoint deferred to `.claude/tmp/` with rationale.

### Frontend composition
- `CarrierDashboardPage` (container): fetches the lists, manages loading/error/empty, calls `buildCarrierDashboardModel`, renders sections.
- Presentational sub-components: `DashboardGreeting` (progressive CTA driven by `onboardingStep`), `CarrierStatsStrip`, `CarrierAttentionPanel`, `JobBoard` → `BoardColumn` → `OfferCard` / `ShipmentCard`, `CarrierActivityFeed`. Each is dumb (props in, markup out).
- The progressive CTA / onboarding hero is data-driven: `no-vehicle` → "Agregá tu primer vehículo" (`/carrier/vehicle/new`); `no-window` → "Publicá tu primera ventana" (`/carrier/availability/new`); `steady` → header CTA "Publicar ventana".
- All Spanish copy lives in a new `carrierDashboardContent.ts` bundle. No hardcoded Spanish literals in JSX.
- Styling via a new `carrierDashboard.css` using existing design tokens. **Carrier voice = Honey Saffron (`--brand-secondary`)** — chosen to contrast the already-shipped sky Shipper dashboard. Urgent expiring-offer surface = Signal Coral (`--brand-error`). No raw hex, no side-stripe borders, no `background-clip:text` (stylelint-enforced bans).
- Reuse the existing `Button` (CVA) component and relative-time / formatting helpers.

## Testing Decisions

- **Good test = external behavior, not implementation.** Assert on what the Carrier sees and can do (rendered counts, column membership, links, urgency tone, empty/error/loading states), not internal calls or class names.
- **`buildCarrierDashboardModel` (deep module)** gets thorough unit tests in isolation: column bucketing for every status (incl. the `settled_at` split between Entregadas/Pagadas), exclusion of cancelled, attention counts, near-expiry urgency thresholding, onboarding-step derivation (no-vehicle / no-window / steady), price selection, and degenerate inputs (empty arrays, all-cancelled, no supply).
- **`CarrierDashboardPage`** gets RTL + `vi.mock`/MSW tests mirroring `CarrierShipments.test.tsx` / `CarrierCargoOfferInbox.test.tsx` prior art: loading skeleton, populated board, attention counts, coral urgency on an expiring offer, accept/reject from a card, each onboarding empty state, and error + retry.
- **Presentational components** get light render tests where they hold logic (badge selection, "Destino abierto" rendering, progressive-CTA branch, empty-column copy).
- **E2E (Playwright)** covers the golden path: a Carrier logs in, lands on the dashboard, sees their pipeline, and accepts an inbound offer (or clicks a card to detail) — reusing the existing carrier e2e patterns and the test backend.
- **Backend (RSpec)** request specs cover the new serializer attributes (`carrier_reviewed`, shipper `rating_avg` on the inbox) and the activity endpoint: shape, auth (carrier-only), and scoping to the current carrier. Maintain/improve SimpleCov; frontend coverage stays ≥ 80%.

## Out of Scope

- Drag-and-drop between Kanban columns. The board is read/navigate-and-act-only; stage transitions happen through existing flows (accept/reject, mark started/delivered).
- Any new model columns, schema migrations, state-machine changes, or Postgres-only features (SQLite-forever policy).
- Supply *management* on the dashboard beyond the quiet stats strip + actionable onboarding nudges — full fleet/window CRUD stays on `/carrier/vehicles` and `/carrier/availability`.
- Advanced offer/shipment **filtering** (US5/US11), **composite** (US23) and **chained** (US24) shipments, and **GPS navigation / live tracking** (US13/US21) — all Post-MVP, not surfaced here.
- Real-time live-updating beyond the existing notifications mechanism; the dashboard fetches on mount.
- A full i18n library migration — the dashboard uses the existing content-bundle convention.
- Shipper-side dashboard (already shipped in v2).
- Insurance/Seguro (not in MVP).

## Further Notes

- **The job-funnel mapping is the crux:** `CargoOffer` and `Shipment` are two backend resources representing two halves of one carrier-facing lifecycle (an offer *becomes* a shipment on acceptance). The dashboard is the first surface to stitch them into a single continuum — which is exactly why a pure `buildCarrierDashboardModel` module is worth extracting and testing hard.
- **Two decisions reached during design are ADR-worthy** (hard to reverse, surprising, real trade-off):
  1. **Asymmetric counterparty reveal** — a Carrier sees the Shipper's identity + rating on a *pending* offer, while a Shipper does not see the Carrier pre-escrow. Rationale: the party *assuming the obligation* (the carrier) gets to vet who they commit to; the party *posting demand* (the shipper) is shielded from cold solicitation. Codifies the existing `CarrierCargoOfferInboxResource` behavior.
  2. **Palette re-canonicalization** — the shipped Shipper dashboard is sky and DESIGN.md says the opposite; this PRD adopts the **as-built** regime (Shipper = sky, Carrier = saffron) as canonical to preserve two-voice contrast, and flags DESIGN.md + `carrier.css` + the `global.css` voice comments as **stale, to be reconciled in a docs sweep.**
- Glossary alignment: `Carrier` ↔ Transportista, `Shipper` ↔ Expedidor. UI copy is Spanish; all code/routes/identifiers are English.
