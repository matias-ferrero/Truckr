# PRD — Cargo Matches v2

> Decision-centric command-center overhaul of the **Shipper's** (Expedidor's) compatible-carriers
> page at `/shipper/cargos/:id/matches` ("Transportistas disponibles"). Replaces the current
> vertically-stacked list of near-identical full-width cards with a **curated top-picks strip + a
> sortable/filterable multi-column grid**, organised around the only two things that actually
> differentiate one compatible match from another: **price and trust**.

## Problem Statement

After publishing a Cargo, a Shipper lands on `/shipper/cargos/:id/matches` and sees a single
infinite vertical column of full-width cards — one per compatible TransportWindow. In the live
data this is ~25 rows and growing (US4/US25 explicitly anticipate "muchas ventanas").

Three problems compound:

1. **No comparison affordance.** Every match is a full-width card stacked on the next, so the
   Shipper compares by scrolling and remembering — the layout is "vertically obsessed". There is
   no sort, no filter, and no side-by-side reading.
2. **The card leads with non-differentiators.** Route, capacity, and vehicle are printed
   prominently — but every window in the list is *already* compatible (route fits, capacity fits,
   dates overlap), so those facts are identical-by-construction and carry no decision signal. The
   things that actually differ — **price and reputation** — are under-weighted (rating is a small
   line; reviews require a click-through to the carrier profile).
3. **Pagination is fetched but never rendered.** The API returns Pagy headers; the UI ignores
   them. The "Página 1 de 2" affordance in the current screen is aspirational, and US25 (an MVP
   story) is therefore unsatisfied.

The two Shipper personas who map to this screen — Florencia (esthetics-center entrepreneur) and
Sofía (one-off student move) — both choose carriers on **price + reviews/trust**, and all four
Expedidor personas are price-sensitive and value a shallow learning curve. The current screen
serves none of that well.

## Solution

A **decision command center** for selecting a carrier, organised top-to-bottom as:

1. **Sticky cargo-context bar** — a compact, always-visible summary of *which* cargo is being
   matched (route, weight, pickup window), so the Shipper never loses the referent while sorting
   or scrolling.
2. **"Recomendados" strip** — up to **three curated picks**, each a *single legible superlative*:
   - **Más barato** — lowest total estimated price.
   - **Mejor calificado** — highest carrier rating, among carriers with **≥1 review** (ties broken
     by review count); hidden entirely if no compatible carrier has any review yet.
   - **Más próximo** — earliest available pickup.
   Each badge is self-justifying — no opaque blended "balance" score to explain or defend.
3. **"Todos" grid** — a responsive multi-column grid of *every* compatible match, with a control
   bar offering **sort** (price ↑/↓, rating ↓, pickup date ↑) and **filter** (max price, pickup
   date range), and **client-side pagination** to satisfy US25.

Every match card leads with the two co-primary differentiators — **total price** (headline) and a
**trust chip** (rating + reseñas, or a neutral "Transportista nuevo" chip) — and demotes the
guaranteed-compatible facts (route, distance, pickup date) to a quiet meta strip, with vehicle
detail behind "Ver perfil".

All picks, sorting, and filtering are computed **client-side** from the full compatible set in a
pure, heavily-tested `buildMatchesModel` module — mirroring the `buildDashboardModel` "deep
testable core" pattern from Shipper Dashboard v2. No ranking logic in Rails, no schema changes.

## User Stories

1. As a Shipper, I want a compact, sticky summary of the cargo I'm matching against, so that I never lose track of *what* these carriers are being compared for while I scroll and sort.
2. As a Shipper, I want a "Recomendados" strip highlighting the cheapest compatible match ("Más barato"), so that the single most price-relevant option is one glance away (price is my #1 driver).
3. As a Shipper, I want the strip to highlight the best-reviewed carrier ("Mejor calificado"), so that I can pick a trustworthy carrier without manually opening every profile.
4. As a Shipper, I want the strip to highlight the soonest-available match ("Más próximo"), so that when pickup timing is urgent I can act on it immediately.
5. As a Shipper, I want each recommended pick to state *why* it's recommended in plain language (cheapest / best-rated / earliest), so that I trust the curation instead of suspecting a black box.
6. As a Shipper, I want carriers with no reviews yet to show a neutral "Transportista nuevo · sin calificaciones" chip rather than "0★", so that a brand-new carrier reads as *new*, not *bad*.
7. As a Shipper, I want the "Mejor calificado" pick to consider only carriers with at least one review, so that a single 5★ rating doesn't outrank an established 4.7★ carrier.
8. As a Shipper, I want all compatible matches laid out in a multi-column grid rather than one infinite vertical column, so that I can compare many options by scanning, not by scrolling-and-remembering.
9. As a Shipper, I want each grid card to lead with the total estimated price and the carrier's rating, so that the two things that actually differ between compatible matches are the loudest elements.
10. As a Shipper, I want each card to show the per-km price beneath the total, so that I can sanity-check the headline figure.
11. As a Shipper, I want the guaranteed-compatible facts (route, distance-to-pickup, pickup date) demoted to a quiet meta strip, so that they give context without competing with the decision drivers.
12. As a Shipper, I want to sort the grid by price, rating, or pickup date, so that I can drive the comparison around whichever axis matters for this shipment (US5, pulled forward).
13. As a Shipper, I want to filter the grid by maximum price and by pickup-date range, so that I can prune options outside my budget or schedule (US5, pulled forward).
14. As a Shipper, I want the recommended picks to respect my active filters but ignore my sort, so that "el más barato" means cheapest *among what I'm looking at* and sorting only reorders the grid.
15. As a Shipper, I want the grid to paginate (client-side) when there are many compatible matches, so that I'm not scrolling infinitely (US25).
16. As a Shipper, I want each card's primary action to be "Enviar oferta" and a secondary "Ver perfil", so that I can either act immediately or drill into reviews/vehicle detail first (US7, US6).
17. As a Shipper, I want a clear empty state when no compatible windows exist, with a nudge to widen my pickup dates or radius, so that a no-results screen is actionable rather than a dead end (US4).
18. As a Shipper with only one or two matches, I want the "Recomendados" strip suppressed, so that the page doesn't show me the same cards twice when the grid already *is* the comparison.
19. As a Shipper, I want the page to show a loading state while matches are fetched and a graceful error state with retry, so that slow or failed loads don't strand me.
20. As a Shipper on a narrow screen, I want the grid to collapse to a single column and the picks strip to become horizontally scrollable, so that the page stays usable on smaller viewports.
21. As a Shipper using a screen reader, I want the picks strip, control bar, and grid to be properly labelled regions with semantic headings and accessible sort/filter controls, so that I can compare and select non-visually.

## Implementation Decisions

### Naming & vocabulary
- The UI continues to speak of **"Transportistas" / "carriers"** as the user-facing concept,
  because "Transport Window" is too abstract for an occasional Shipper. The underlying unit
  remains one **TransportWindow** per card (a Carrier may legitimately appear more than once with
  two different windows/dates/prices — this duplication is accepted, not de-duplicated).
- Glossary alignment: `Shipper` ↔ Expedidor, `Carrier` ↔ Transportista, the card-level entity is a
  compatible `TransportWindow`, the action creates a `CargoOffer` (US7). "Carrier match" is the
  friendly UI surface for "a TransportWindow compatible with this Cargo".

### Routing & shell
- Same route `/shipper/cargos/:id/matches`, same `<ShipperLayout>` and role guard. This is an
  in-place overhaul of `CargoMatches.tsx` + `MatchCard.tsx`, not a new route.
- "Ver perfil" → `/carriers/:carrierId` (US6, unchanged). "Enviar oferta" →
  `/shipper/cargos/:cargoId/offers/new?window=:windowId` (US7, unchanged).

### Data sourcing (no schema changes)
- The endpoint `GET /api/cargos/:id/matches` returns the **full compatible set** for the cargo —
  **no server-side pagination** for this screen. Compatibility (window open + time overlap +
  Haversine pickup/dropoff radius + capacity) already bounds the set per cargo, so returning it
  whole is safe and is what makes *global* picks ("the cheapest of all") honest.
  - **No hard cap for the MVP.** A backend cap would silently make "el más barato" a lie (the true
    cheapest could sit beyond the cap). If a single route ever balloons past a comfortable size,
    revisit then — do not pre-emptively cap.
  - The existing Pagy/`page` plumbing on this endpoint is retired for this screen; pagination moves
    to the client (below). (Other consumers of paginated list endpoints are unaffected.)
- **All picks, sort, and filter are computed client-side.** No sort/filter query params and no
  ranking logic are added to Rails.

### The deep, pure core — `buildMatchesModel`
A pure module `buildMatchesModel(matches, { sort, filters })` maps the raw match array into a view
model: `{ picks: { cheapest, bestRated, soonest }, rows, totalCount, filteredCount, page }`. No
React, no fetch. Rules:
- **Total estimated price** per match = `price_per_km × cargo haul distance` (US7). Because haul
  distance is fixed per cargo, sorting by total ≡ sorting by per-km; the **total** is the headline
  because it's what the Shipper actually reasons about.
- **Picks** (each may be `null`):
  - `cheapest` = min total price.
  - `bestRated` = max `rating_avg` among matches whose carrier has `reviews_count ≥ 1`; ties → max
    `reviews_count`; `null` if no eligible carrier exists.
  - `soonest` = min `available_from`.
  - **Dedupe:** if one window wins two badges, it occupies the first slot it qualifies for and the
    next-best distinct window is promoted into the freed slot, so ≥3 matches always yield 3
    distinct picks.
  - **Suppression:** the entire picks set is omitted when there are **≤3 matches** (the grid is the
    comparison at that point).
  - **Filter-aware, sort-blind:** picks are computed over the *filtered* set; the active grid sort
    does not affect which windows are picked.
- **Filters** (US5): `maxPrice` (on total), `pickupDateFrom`/`pickupDateTo` (on the window's
  availability). Combinable.
- **Sort** (US5): `price-asc | price-desc | rating-desc | date-asc`. Default `price-asc`.
- **Client pagination** (US25): the filtered+sorted rows are sliced into pages of a fixed size
  (e.g. 12); the model exposes `page`, `pageCount`, and the current slice.
- **Cold-start display flag:** each row carries `isUnrated = reviews_count === 0` so the card can
  render the neutral "Transportista nuevo" chip instead of a numeric rating.

### Frontend composition
- `CargoMatches` (container): fetches the cargo + full match set, manages loading/error/empty,
  holds sort/filter/page UI state, calls `buildMatchesModel`, renders sections.
- Presentational sub-components: `CargoContextBar` (sticky), `RecommendedStrip` → `PickCard`,
  `MatchesControls` (sort + filter), `MatchGrid` → `MatchCard`, `MatchesPagination`. Each is dumb
  (props in, markup out).
- `MatchCard` hierarchy (decided): **total price headline** + per-km beneath; **trust chip**
  (rating + reseñas, or "Transportista nuevo" when `isUnrated`) beside it; one quiet meta strip
  (pickup date · distance-to-pickup · route caption); vehicle detail behind "Ver perfil"; primary
  "Enviar oferta", secondary "Ver perfil".
- All Spanish copy lives in a new `cargoMatchesContent.ts` bundle (prototype-stage i18n pattern).
  No hardcoded Spanish literals in JSX.
- Styling via `cargoMatches.css` using existing design tokens. **Shipper voice = sky-blue**
  (`--brand-primary`). No raw hex, no side-stripe borders, no `background-clip:text`
  (stylelint-enforced bans). Recommended-pick emphasis uses an accent ring/elevation, not a banned
  side-stripe.
- Reuse the existing `Button` (CVA) component and any existing price/date/relative-time formatting
  helpers.

## Testing Decisions

- **Good test = external behavior, not implementation.** Assert on what the Shipper sees and can do
  (which picks render and why, grid ordering after a sort, rows remaining after a filter, the
  "nuevo" chip vs a numeric rating, empty/error/loading states), not on internal calls or CSS
  classes.
- **`buildMatchesModel` (deep module)** gets thorough unit tests in isolation — the highest-value,
  lowest-cost coverage:
  - picks: cheapest / best-rated / soonest selection; the `reviews_count ≥ 1` eligibility gate;
    `bestRated === null` when nothing is rated; tie-breaking by review count.
  - dedupe: one window winning two badges promotes the next-best into the freed slot.
  - suppression: no picks when `matches.length ≤ 3`.
  - filter-aware / sort-blind picks: picks recompute under a `maxPrice` filter but are unchanged by
    a sort change.
  - sort correctness for every axis; filter correctness for price and date range; combined
    filter+sort.
  - pagination slicing, including last-page remainder and empty result.
  - degenerate inputs: empty array, single match, all-unrated.
- **`CargoMatches`** gets React Testing Library + `vi.mock`/MSW tests mirroring the existing
  `CargoMatches.test.tsx` prior art: loading, populated picks+grid, empty state with the
  widen-dates nudge, error + retry, and a sort/filter interaction asserting the visible order/count
  changes.
- **Presentational components** get light render tests where they hold logic worth checking
  (`MatchCard` rated vs unrated chip; `PickCard` badge label; suppressed strip ≤3 matches).
- **E2E (Playwright)** covers the golden path: a Shipper opens a cargo's matches, sees the
  Recomendados strip, sorts/filters the grid, and clicks "Enviar oferta" to reach the offer flow —
  reusing the existing register/login e2e pattern and test backend.
- **Backend (RSpec)** request specs cover the changed matches endpoint: returns the full compatible
  set (no pagination), correct compatibility scoping, shipper-only auth, and the shape consumed by
  the client. Maintain or improve SimpleCov coverage. Frontend coverage must stay ≥ 80%
  (lines/functions/branches/statements).

## Out of Scope

- **Carrier side-by-side comparison view / multi-select compare** — not in any user story; the grid
  + picks are the comparison surface for the MVP.
- **Negotiation / counter-offers** — the model is single-shot (Shipper proposes a frozen price per
  US7; Carrier binary accepts/rejects or it expires at 48h). No price haggling.
- **Sort/filter axes beyond US5** — no sort/filter by capacity, vehicle type, or distance. US5's
  documented axes (price, rating, pickup date) only. (Distance-to-pickup is *displayed* as context,
  not a sort/filter axis.)
- **Server-side ranking or a "top picks" backend payload** — all curation is client-side in
  `buildMatchesModel`.
- **Any new model columns, schema migrations, or Postgres-only features** (SQLite-forever policy).
  Picks/sort/filter are application-layer; no GIN/GIST, no PostGIS, no `unaccent`.
- **Insurance / Seguro** — not in MVP.
- **Real-time live updates** of the match set — fetch on mount; a manual refresh affordance is
  acceptable but not required.
- **A full i18n library migration** — uses the existing content-bundle convention.

## US Mapping

| User story | This PRD covers it by… |
|---|---|
| **US4** — Búsqueda de Ventanas Compatibles | The screen itself: full compatible set, per-match price, "Enviar oferta", empty state. **Extends US4** by surfacing carrier rating inline (US4's row spec omits it) — a deliberate, persona-justified addition. |
| **US25** — Paginado de Ventanas Compatibles | Client-side grid pagination over the filtered+sorted set. |
| **US5** — Filtrar Ventanas Compatibles *(Release 2, Baja)* | **Pulled forward**, scoped *exactly* to US5's axes: sort by price/start-date (+ rating), filter by max price + pickup-date range. No invented scope. |
| **US7** — Ofertar Retiro de una Carga | "Enviar oferta" CTA → offer flow; total = per-km × haul distance shown on the card. |
| **US6** — Perfil de Transportista | "Ver perfil" secondary CTA → carrier profile + reviews (the deep-dive for trust). |

## Further Notes

- **The crux is that "compatible" erases the obvious differentiators.** Once route, capacity, and
  dates are guaranteed by construction, the only signal left is price and reputation — so the whole
  hierarchy is rebuilt around those two, and everything else is demoted to context. That single
  observation is what turns a flat list into a decision tool.
- **Surfacing rating inline is a conscious extension of US4.** US4's acceptance criteria list only
  cargo + window + price; rating/reviews live on US6's profile. We pull a *rating summary* inline
  because the target personas choose on trust — but the full reviews list stays on US6 behind
  "Ver perfil", so US6 is complemented, not duplicated.
- **Why client-side curation (potential ADR).** Returning the full compatible set and computing
  picks/sort/filter in a pure front-end module (rather than ranking in Rails with server
  pagination) is the load-bearing architectural choice: it keeps the thin-client / deep-testable
  precedent set by `buildDashboardModel`, keeps zero ranking logic in Ruby, and makes the global
  "cheapest/best/soonest" picks honest. The trade-off is that it assumes per-cargo match counts
  stay modest — which compatibility filtering makes true for this academic, SQLite-forever scope.
  If that assumption ever breaks, an ADR should record the move to server-side ranking.
- Any concept element that cannot be honestly backed by current data is **deferred and documented
  in `.claude/tmp/` with reasons**, rather than faked.
