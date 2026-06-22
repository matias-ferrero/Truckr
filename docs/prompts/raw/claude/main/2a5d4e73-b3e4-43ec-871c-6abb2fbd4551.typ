#import "@preview/cmarker:0.1.8"

= Defer Haversine calculation after GMaps integration

_2026-05-19 21:54 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:project:onboard full`
  ```,
  h1-level: 4,
  label-prefix: "cc280-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Project Onboarding Complete

  **Task Type**: full
  **Documents Loaded**: all 8 in `docs/onboarding/` (`README` + `00`–`06`)
  **Mode**: standard

  ### Project Summary
  - **Name**: Truckr® — two-sided transportation marketplace (FIUBA GDSI capstone)
  - **Stack**: Rails 8.1 API-only (Ruby 3.4, SQLite + Solid Queue/Cache/Cable) · React 18 + Vite 5 + TS 5.3 (Deno runtime) · Typst docs · `mise`/`just`
  - **Architecture**: client/server monorepo — static SPA → stateless REST API. Single-container Kamal deploy. No microservices, no BFF.

  ### Key Rules I'll Follow
  - **English code, Spanish content** — identifiers/routes/columns always English; UI copy + errors via i18n keys, never hardcoded literals. Glossary (`docs/05-appendices/glossary.md`) is term source-of-truth: `Transportista`↔`Carrier`, `Expedidor`↔`Shipper`.
  - **SQLite is permanent** — no Postgres/PostGIS/RDS/`citext`/`unaccent`/EXCLUDE/Phase-2 framing, anywhere. Geo = lat/lng `DECIMAL(9,6)` + Haversine. Reject PG baggage at review.
  - **Conventional Commits + PR titles** — title starts with type, no `[TAG]` bracket prefix (kills release-please parse); TAG in body/branch. Assign PRs `--assignee @me`.
  - **API under `/api/`**, snake_case JSON, verbs restricted with `only:`/`except:`. Jobs in `app/jobs/`, idempotent, pass IDs.
  - **Pre-PR gate** for frontend: `/critique` → `/polish` → `/audit`, then `just lint` + `frontend-test-coverage` (≥80%) + `frontend-test-e2e` + `backend-test`. CI is expensive — get it right locally.
  - **Issue lifecycle = file movement** under `.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}/`, tag `<PREFIX>-<SCOPE>-<NNNNN>`. RSpec is the exclusive backend test framework.
  - No denormalized role booleans on `User` (ADR-008) — relation-derived predicates.

  ### Ready to Help With (full context)
  Architecture/planning · backend Rails models/controllers/jobs · frontend React/UI · RSpec + Vitest + Playwright tests · Typst docs · issue triage and SDLC workflow.

  ### Active Context
  - **`.gdsi-sdlc` config**: loaded — GitHub `tcorzo/fiuba-gestion-tp`, project #7, automation disabled.
  - **OE Assessment**: not assessed (`oe_assessment: false`).
  - **Phase**: planning→implementation transition. Priority funnel: `REQ-BE-00005` (domain model, InReview) → `REQ-BE-00020` Identity → `REQ-BE-00021` Marketplace → `REQ-BE-00022` Fulfilment → `REQ-BE-00023` Auth.

  ### ⚠️ Doc drift noticed
  Onboarding docs still describe the `Quote`/`CargoOffer`/`QuoteRequest` naming, but recent commits renamed **`Quote`→`CargoOffer`** and **`CargoOffer`→`Cargo`** (commit `3a30c6d`) and added an offer wizard (`b4c7a7e`). `05-testing-strategy.md` still references `/api/quotes` and `quote` params. Backend has clearly moved past "0 models / 0 migrations" too. The onboarding docs need a re-distill from the canonical tech docs — flag for the next docs sweep.

  Working tree currently has uncommitted `backend/app/controllers/api/base_controller.rb`. Questions? Ask me anything about the project.
  ```,
  h1-level: 4,
  label-prefix: "cc281-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:issues:plan https://github.com/tcorzo/fiuba-gestion-tp/issues/198 in a worktree`
  ```,
  h1-level: 4,
  label-prefix: "cc282-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The exploration surfaced a real conflict that forks the design. The issue's **matching algorithm** (`GET /api/cargos/:id/matches`) is specified as Haversine over `origin_lat/lng`, `destination_lat/lng`, and `pickup_radius_km` on **both** `Cargo` and `TransportWindow`. But the shipped `transport_windows` table has **none of those** — it's zone-string based (`origin_zone` / `destination_zone` + normalized columns), and the already-merged carrier search uses those zones. The `cargo_offers` table (→ `cargos` after `REF-BE-00002`) also lacks lat/lng and `status`.

  So the matching can't be built as written without a schema decision that reaches beyond this issue's own table.
  ```,
  h1-level: 4,
  label-prefix: "cc283-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The user wants to clarify before answering. What would you like to clarify?

  A few things I can expand on if useful:

  - **The conflict in detail** — exactly which fields the issue assumes vs. what the schema has, and which other issues (`REQ-FE-00016` carrier search, `REQ-FE-00006` US4 reframe) are affected by changing `transport_windows`.
  - **The three matching approaches** — deeper trade-offs of zone-string vs. lat/lng+Haversine vs. hybrid (effort, accuracy, blast radius).
  - **The other open decisions** the issue defers to "decidir en plan" — frontend i18n (`cargosContent.ts` vs. real i18n lib) and form library (`react-hook-form`+`zod` is specified but not installed; existing US7 wizard uses plain `useState`).
  - **Dependency reality** — `REF-BE-00002` is in Ready (not merged), `INF-FE-00003` routing is partially done, PR #193 still mixes `POST /api/quotes`. Whether the plan should assume those land first or absorb some of that work.
  - **Scope** — whether you want the full fullstack plan or a narrower cut.

  What's on your mind?
  ```,
  h1-level: 4,
  label-prefix: "cc284-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  We must defer the Haversine for after the GMaps integration given that we don't truly have geo(lat/lon)
  ```,
  h1-level: 4,
  label-prefix: "cc285-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Understood — that resolves the fork. With no real lat/lng data, **Haversine matching is deferred** to a follow-up that depends on the GMaps integration (`REQ-FE-00009`). For `REQ-BE-00032`, `GET /api/cargos/:id/matches` will match on **zone strings + date overlap + capacity** — the same dimensions the shipped carrier search already uses — and the plan will explicitly carve out lat/lng columns + Haversine + `distance_km` as out-of-scope.

  That leaves a single clear approach, so I'll go straight to the implementation plan (no alternatives doc needed). Let me pull the last details I need to write it accurately.
  ```,
  h1-level: 4,
  label-prefix: "cc286-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now move the issue file Backlog → Ready and update the index.
  ```,
  h1-level: 4,
  label-prefix: "cc287-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Plan Flow complete — `REQ-BE-00032` planned

  **Issue #198** (`REQ-BE-00032`, Cargo fullstack US27) analyzed, planned, moved Backlog → **Ready**.

  ### Research gate
  Surfaced one real architectural fork: the issue specifies Haversine matching over `lat/lng` + `pickup_radius_km`, but the shipped schema is zone-string based with no geo data. You directed: **defer Haversine until the GMaps integration**. That collapsed it to a single clear approach → Plan Flow (no alternatives doc).

  ### What the plan resolves
  - **Zone-string matching** for `GET /api/cargos/:id/matches` (mirrors the merged carrier search); lat/lng + `distance_km` carved out to a `REQ-FE-00009` follow-up.
  - **Schema reconciliation table** — the issue was written against an imagined schema; every gap is mapped to the real post-`REF-BE-00002` `cargos` table.
  - Hand-rolled FSM (mirrors `Shipment`, no `aasm`); derived window-availability (no window status enum exists); soft-cancel cascade.
  - Two deferred decisions decided in-plan: keep `*Content.ts` i18n, plain-`useState` form — both for repo consistency, recorded as deliberate deviations.
  - Full file-level tasks, code snippets, 6-commit sequence, testing + AC.

  ### Artifacts
  - **Plan**: `docs/features/REQ/REQ-BE-00032/REQ-BE-00032-cargo-fullstack-us27.plan.md`
  - Issue file moved to `.gdsi-sdlc/issues/Ready/`; `ISSUES-INDEX.md` updated `NEW → RDY`.
  - Committed `9e8e3e0` on branch **`worktree-plan+REQ-BE-00032`**, pushed to origin.
  - [Comment posted](https://github.com/tcorzo/fiuba-gestion-tp/issues/198#issuecomment-4492488661) to issue #198.

  ### Notes
  - All work is in the **worktree** you requested. On session exit you'll be prompted to keep or remove it; the branch is already pushed either way.
  - The plan is **hard-blocked on `REF-BE-00002`** (rename, currently Ready) — implementation can't start until that lands. Dependency documented in the plan's §8.
  ```,
  h1-level: 4,
  label-prefix: "cc288-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  Check the actual state of REF-BE-00002 and #193
  ```,
  h1-level: 4,
  label-prefix: "cc289-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Both dependency assumptions in the plan are **stale** — let me verify against `main` directly.
  ```,
  h1-level: 4,
  label-prefix: "cc290-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I have the full picture now. Both assumptions in the plan are stale — let me correct it.

  **Findings:**

  | Item | Plan assumed | **Actual state** |
  |---|---|---|
  | `REF-BE-00002` (issue #197) | Hard blocker, in `Ready`, not started | **DONE** — merged via **PR #204** (`c50a431`), 2026-05-19 21:51. `Cargo`/`CargoOffer` models + `cargos`/`cargo_offers` tables are on `main`. |
  | PR #193 (`REQ-FE-00015`) | Open, pending request-changes to split `POST /api/quotes` | **MERGED** 2026-05-19 20:17 — **un-split**. |

  The consequential surprise: **the endpoint split never happened.** PR #204 only *renamed* `POST /api/quotes` → **`POST /api/cargo_offers`** — and that action still **inline-creates a `Cargo`** (`CargoOffersController#create` does `Cargo.create!` + `CargoOffer.create!` in one transaction). There is no `POST /api/cargos` and no `cargos_controller.rb`.

  So: no blockers remain — the issue is ready to implement now — but the plan must drop the "split #193" framing and flag the leftover. The verified post-rename `cargos`/`cargo_offers` schema matches what the plan's §2.1 and §4.1 already projected, so the migration/model/controller design stays valid. Fixing the plan:
  ```,
  h1-level: 4,
  label-prefix: "cc291-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done. Verified state and corrected the plan.

  ## Actual state

  | Item | Status |
  |---|---|
  | **`REF-BE-00002`** (issue #197) | **DONE** — merged via **PR #204** (`c50a431`), 2026-05-19 21:51. `cargo.rb`/`cargo_offer.rb` models + `cargos`/`cargo_offers` tables on `main`. |
  | **PR #193** (`REQ-FE-00015`) | **MERGED** 2026-05-19 20:17 — **un-split**. |

  **The key surprise:** the endpoint split never happened. PR #204 only *renamed* `POST /api/quotes` → `POST /api/cargo_offers`, and that action **still inline-creates a `Cargo`** (`CargoOffersController#create` = `Cargo.create!` + `CargoOffer.create!` in one tx). There is no `POST /api/cargos`.

  **Net:** no blockers remain — the issue is ready to implement now. The verified post-rename `cargos`/`cargo_offers` schema matches exactly what the plan's §2.1 / §4.1 projected, so the migration, model, controller, and matching design are all still valid.

  ## Plan corrections (commit `550edea`, pushed)

  - **Header `Depends On`** — "hard blocker" → "None blocking; `REF-BE-00002` DONE via PR #204".
  - **New §1 "Dependency status (verified)"** subsection — documents that #197 is closed, #193 merged un-split, and that de-mixing `CargoOffersController#create` is **US7 follow-up scope**, not this issue.
  - **§8 risk table** — struck the stale `REF-BE-00002`/`#193` rows; added the real risk (two `Cargo`-creation paths now coexist) and a note on the `:restrict_with_error` → `:destroy` association change.

  [Correction comment posted](https://github.com/tcorzo/fiuba-gestion-tp/issues/198#issuecomment-4492572589) to issue #198.

  One thing worth your call: the worktree branch `worktree-plan+REQ-BE-00032` is based on `b4c7a7e` and is **one commit behind `main`** (missing #204). Doesn't affect the plan doc, but whoever implements should branch fresh from current `main`.
  ```,
  h1-level: 4,
  label-prefix: "cc292-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  REQ-FE-00015 has been merged. This plan must correct it's poor implementation into compliance with REQ-BE-00032
  ```,
  h1-level: 4,
  label-prefix: "cc293-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Before updating the plan I need the real shape of the merged REQ-FE-00015 frontend — to scope the remediation accurately.
  ```,
  h1-level: 4,
  label-prefix: "cc294-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The merged REQ-FE-00015 on `main`: `frontend/src/api/quotes.ts` POSTs the combined `{ cargo_offer: {…all cargo + offer fields…} }` to `/api/cargo_offers`; the `CreateOfferPage` 3-step wizard (`/carriers/:id/offers/new`) collects everything. Backend `CargoOffersController#create` inline-creates the `Cargo`.

  The backend fix is unambiguous — split the endpoint so a `CargoOffer` references an existing `Cargo`. But how deep the **frontend** remediation goes is a real fork that changes the size of this issue:
  ```,
  h1-level: 4,
  label-prefix: "cc295-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The user chose the full cargo-first rework. Let me read the current plan to fold the remediation in accurately.
  ```,
  h1-level: 4,
  label-prefix: "cc296-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Folding the REQ-FE-00015 remediation into the plan as in-scope.
  ```,
  h1-level: 4,
  label-prefix: "cc297-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done. The REQ-FE-00015 remediation is folded into the plan as in-scope.

  ## What changed in the plan (commit `9097d5c`, pushed)

  **The problem:** REQ-FE-00015 merged un-split — `CargoOffersController#create` inline-creates a `Cargo` from the same payload as the bid, and `CreateOfferPage` is a standalone 3-step wizard collecting every cargo field. A `Cargo` is never a deliberately *published* entity — it's a side effect of bidding. Non-compliant with the Cargo-first model REQ-BE-00032 establishes.

  **Remediation now in scope** — new plan sections **§2.7**, **§4.9**, **§4.10**, tasks **19–25**:

  - **Backend split** — new nested `POST /api/cargos/:cargo_id/offers`; `CargoOffersController#create` drops `cargo_attrs` + `Cargo.create!`, loads the `Cargo` from the path, bids against it (params: `transport_window_id` + `estimated_km` only). Combined `POST /api/cargo_offers#create` route removed; ownership via `CargoPolicy#offer?`.
  - **Validation coupling caught** — `CargoOffer` inherits a `pickup_date_within_window` validation that reads `cargo.pickup_date` — a column this issue *drops*. Plan retargets it to the new `pickup_window_*` overlap, and makes the capacity check tolerate `nil` volume.
  - **Frontend cargo-first rework** — offer creation moves to `/shipper/cargos/:id/offers/new?window=:windowId`, reached from the `MatchCard` "Ofertar" CTA. `CreateOfferPage` collapses 3 steps → 1 confirm step (read-only cargo + window summaries, `estimated_km`, cost estimate). `/carriers/:id/offers/new` removed; `api/quotes.ts` → `api/cargoOffers.ts`.

  **Effort L → XL.** Commit sequence extended to 8 — the remediation lands in dedicated commits (6–7) *after* the `POST /api/cargos` surface exists, so each stays independently green. AC, testing (incl. an "asserts no `Cargo` created" request spec), files summary, and a new "Renamed Files" section all updated.

  [Update comment posted](https://github.com/tcorzo/fiuba-gestion-tp/issues/198#issuecomment-4492683739) to issue #198. Plan still in the worktree branch `worktree-plan+REQ-BE-00032`; issue remains in `Ready`.

  One judgment call worth flagging for review: removing `/carriers/:id/offers/new` means a Shipper can no longer start an offer from carrier-browse — offers now only originate from a published Cargo's matches. That's the compliant funnel, but it's a UX removal; if a carrier-browse → offer entry should survive, it'd need a "pick one of your cargos" step instead.
  ```,
  h1-level: 4,
  label-prefix: "cc298-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  How does the cargo -> offer flow work to your understanding? I want to have aligned expectations
  ```,
  h1-level: 4,
  label-prefix: "cc299-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Here's my model of the cargo → offer flow. Two actors, plus the system:

  ## The entities

  - **`Cargo`** — a load the **Shipper** publishes (`open / accepted / cancelled`).
  - **`TransportWindow`** — availability a **Carrier** publishes: a vehicle, origin/destination zones, date range, `price_per_km`.
  - **`CargoOffer`** — the **Shipper's bid**: "I offer *this Cargo* against *that Window*." (`pending / accepted / rejected/expired / …`). It links `Cargo + TransportWindow + Carrier`.

  Key point on direction: **the Shipper authors the `CargoOffer`** ("oferta de carga" = offer *of* cargo). The Carrier is passive until it accepts. The merged US7 wizard confirms this — `require_shipper!`, `CargoOfferPolicy#create? = shipper`.

  ## The flow

  ```
  Shipper                          System                         Carrier
  ───────                          ──────                         ───────
  1. POST /api/cargos  ──────────▶  Cargo {status: open}
                                    compute matches (zone+date+cap)
  2. GET /cargos/:id/matches ─────▶  compatible TransportWindows
  3. picks a match → "Ofertar"
  4. confirm screen: cargo summary
     + window/carrier + estimated_km
  5. POST /cargos/:id/offers ─────▶  CargoOffer {status: pending}  ──▶ email
                                     amount_cents derived
  6. detail: "Mis ofertas" shows it                                   reviews in
                                                                      inbox (US10)
                                ◀──── accepts (US12/REQ-BE-00024) ─────┘
  7.                                Cargo → accepted
                                    Shipment created
                                    sibling pending offers → expired
  ```

  So: **publish Cargo → see matches → offer against a window → carrier accepts.** A Cargo stays `open` and can carry several `pending` offers (against *different* windows) at once; acceptance of any one flips the Cargo to `accepted`.

  ## Where I'm making assumptions — confirm or correct these

  These four points are baked into the plan; I'd rather align now than discover a mismatch mid-implementation:

  1. **Pricing is derived, not negotiated.** The offer's `amount_cents` = `estimated_km × window.price_per_km`. The Shipper doesn't *name* a price — they accept the carrier's per-km rate, and `estimated_km` is a **manual Shipper input** on the confirm screen (Haversine auto-distance is deferred with GMaps). Is "offer" really just "I accept your rate for ~N km", or should the Shipper propose a price?

  2. **Window-lock.** My matching (§2.3) **hides** any window that already has a `pending` or `accepted` offer — i.e. one offer per window at a time; offering "reserves" the window. `REF-BE-00002` hinted at a unique index for this. If instead a window should accept competing offers from multiple shippers (carrier picks the best), then `matches` must *show* contended windows, and §2.3 changes.

  3. **One Cargo, many windows.** A Shipper can offer the same Cargo against W1, W2, W3 simultaneously (shopping around). When a carrier accepts one, the others expire. (The accept-cascade itself is `REQ-BE-00024`'s scope, not this issue — but my model depends on it.)

  4. **Single entry point.** After this issue, an offer can *only* start from a published Cargo's match list — `/carriers/:id/offers/new` is removed. No "offer from carrier-browse" path survives.

  #2 is the one most likely to bite — it decides whether matches is a "free windows" list or an "all candidate windows" list. Which of these matches your intent?
  ````,
  h1-level: 4,
  label-prefix: "cc300-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  Let's keep POST /api/cargo_offers but add a cargo_id param instead of using the /cargos/:id path. This way is cleaner
  ```,
  h1-level: 4,
  label-prefix: "cc301-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Good call — flat route with a `cargo_id` param is cleaner and consistent with how `transport_window_id` already rides in the body. Updating the plan.
  ```,
  h1-level: 4,
  label-prefix: "cc302-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Six stray "nested route" references for the API endpoint slipped through — fixing them.
  ```,
  h1-level: 4,
  label-prefix: "cc303-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Done — plan updated, committed `d695dc9`, pushed.

  ## Change

  The remediation no longer nests the route. `POST /api/cargo_offers` stays exactly as it is on `main` — the fix is **payload-only**:

  ```
  POST /api/cargo_offers
  { "cargo_offer": { "cargo_id": 42, "transport_window_id": 7, "estimated_km": 310 } }
  ```

  `CargoOffersController#create` reads `cargo_id` from the body, loads that existing `Cargo`, and creates only the `CargoOffer` — no inline `Cargo.create!`. `resources :cargo_offers, only: %i[index create]` is untouched.

  This is cleaner: no extra route, and consistent with `transport_window_id` already being a body param.

  Updated across the plan: §1 bullet, §2.7 (backend section), §4.4 routes, §4.9 controller code, §4.10 wizard, §3 task 19, §5/§6/§7/§8, plus six stray "nested route" references. The FE component route `/shipper/cargos/:id/offers/new` is unaffected — it's a UI route, independent of the API path.

  I didn't post another GitHub comment for this one — it's a refinement of the already-commented remediation, not a new scope shift. Say the word if you'd like a comment too.

  One open item still unconfirmed from the last turn: **the window-lock question** (#2 — does `matches` hide windows that already have a pending offer, or show contended ones?). That decides whether `matches` §2.3 rule 2 stays as written.
  ````,
  h1-level: 4,
  label-prefix: "cc304-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  matches hides windows that already have a pending offer
  ```,
  h1-level: 4,
  label-prefix: "cc305-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The plan's §2.3 rule 2 already encodes that — `matches` excludes any window with a `pending` (or `accepted`) `CargoOffer`. So the read side is aligned, no change needed there.

  But your confirmation exposes a gap on the **write side**: the plan's `matches` *hides* contended windows, yet `POST /api/cargo_offers#create` doesn't *enforce* the lock — a stale match list or a direct API call could still stack a second `pending` offer onto a locked window. The window-lock is only real if create rejects it too. Folding that in:
  ```,
  h1-level: 4,
  label-prefix: "cc306-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done — window-lock fully encoded, committed `b349938`, pushed.

  ## What's now in the plan

  The window-lock is enforced on **both sides** consistently:

  - **Read** (§2.3 rule 2) — `matches` hides any window with a `pending`/`accepted` `CargoOffer`. *(Already there — your confirmation.)*
  - **Write** (§2.7 new "window-lock" subsection, §4.9) — `CargoOffer` gains a create-time validation: the target `TransportWindow` must hold no other `pending`/`accepted` offer → **422** otherwise. A stale match list, a concurrent shipper, or a direct API call can no longer stack a second offer onto a contended window.

  Race-safety: SQLite serialises all writes, so the `exists?` check inside the create transaction is sufficient — no explicit row lock needed. That satisfies CLAUDE.md's "race-safety at the application layer" rule (solved, not deferred — no EXCLUDE-constraint baggage).

  Also updated: task 20, the §4.9 implementation note (`validate :window_not_already_taken, on: :create`), the §5 request-spec coverage, and a §6 AC bullet.

  The plan is now internally consistent on the lifecycle: publish `Cargo` → `matches` shows only free windows → offer locks a window → cancel/expire/reject unlocks it (cascade in §2.4) → carrier accept flips `Cargo` to `accepted` (`REQ-BE-00024`).

  Plan branch `worktree-plan+REQ-BE-00032` (commits `9e8e3e0`→`b349938`); issue #198 in `Ready`.
  ```,
  h1-level: 4,
  label-prefix: "cc307-",
)
