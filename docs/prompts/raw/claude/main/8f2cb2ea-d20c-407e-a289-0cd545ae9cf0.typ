#import "@preview/cmarker:0.1.8"

= Review Shipment FE issues

_2026-05-25 15:22 UTC — rama `docs/sprint-3-plan` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/sprint-status`
  ```,
  h1-level: 4,
  label-prefix: "cc1620-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Sprint 3 status (day 5 of 7).

  2 of 10 commitments merged.

  | Dev | Commit | Status | Risk |
  |---|---|---|---|
  | Brian | `REQ-BE-00033` US8 Pago (#213) | not started — no PR | at risk |
  | Lucas | `REQ-FE-00023` US17 Shipper FE (add-on) | not started — no PR | at risk |
  | Matías | `REQ-FE-00022` US17 Carrier FE (add-on) | not started — no PR | at risk |
  | Tomás | `REQ-FE-00024` US39 detalle FE (add-on) | not started — no PR | at risk |
  | Fernando | `INF-FE-00005` notifs scaffold (#217) | not started — no PR | at risk |
  | Lucas | `REQ-BE-00034` US32 baja vehículo (#215) | in review — PR #220 draft, stale 2 days, CI skipped | at risk |
  | Matías | `FIX-BE-00001` TW nullable destination (#211) | in review — PR #227 CHANGES_REQUESTED, iterating today, CI green | at risk |
  | Fernando | `INF-INFRA-00004` OIDC deploy (#202) | in review — PR #246 phase 3 of 3, CI green; phases 1+2 (#232, #245) merged | on track |
  | Tomás | `REQ-BE-00035` Envíos endpoints | merged — PR #248 merged 2026-05-25 15:20 UTC | merged |
  | Franco | `REQ-FE-00017`+`REQ-BE-00024` US10/US12 | merged — PR #221 (carryover) | merged |

  Critical path: PR #248 (BE Envíos) just merged → unblocks Matías US17 Carrier, Lucas US17 Shipper, Tomás US39 detail — but **none of the four add-on FE PRs exist** at the day-5 cutoff written into the plan.

  Headline: trigger the documented go/no-go — 4 of 4 add-ons (US17 Carrier, US17 Shipper, US39, INF-FE-00005) have zero PRs at end of day 5; per the Sprint 3 plan, **defer all FE add-ons to Sprint 4**. The bigger fire is Brian's `REQ-BE-00033` (US8 Pago) — original commitment, dependency (US12) cleared yesterday, still no branch on day 5/7.
  ```,
  h1-level: 4,
  label-prefix: "cc1621-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  Which are the Shipment FE issues?
  ```,
  h1-level: 4,
  label-prefix: "cc1622-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Three Shipment FE issues, all add-ons from the 2026-05-24 enmienda. All local (no GH issue), no PR open:

  | TAG | US | Dev | Route | Board | File |
  |---|---|---|---|---|---|
  | `REQ-FE-00022` | US17 Carrier | Matías | `/carrier/shipments` | Backlog | `.gdsi-sdlc/issues/Backlog/REQ-FE-00022-us17-listado-envios-carrier.issue.md` |
  | `REQ-FE-00023` | US17 Shipper | Lucas | `/shipper/shipments` | Backlog | `.gdsi-sdlc/issues/Backlog/REQ-FE-00023-us17-listado-envios-shipper.issue.md` |
  | `REQ-FE-00024` | US39 detalle | Tomás | `/{carrier,shipper}/shipments/:id` | Ready | `.gdsi-sdlc/issues/Ready/REQ-FE-00024-us39-detalles-de-envio.issue.md` |

  All three consume the now-merged `REQ-BE-00035` endpoints (PR #248). Per the Sprint 3 plan's day-5 go/no-go: zero of the three have PRs → all three FE add-ons are due to be deferred to Sprint 4, leaving the BE endpoints as the Sprint 3 seed.
  ```,
  h1-level: 4,
  label-prefix: "cc1623-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  How should I (tcorzo) begin the GMaps issues?
  ```,
  h1-level: 4,
  label-prefix: "cc1624-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  All six GMaps issues are already triaged, planned, and assigned to you (`sprint: 4`, status `ready`) under `docs/features/REQ/REQ-{BE,FE}-000{25..28,36,37}/*.plan.md`. Sprint 4 starts **2026-05-28** — don't crack any of these open in the next 48h, finish/defer the Sprint 3 work first.

  **Pre-step (do once, day 1 of Sprint 4):** Google Maps Platform billing + API key. Restrict by HTTP referrer; enable only Places JS + Maps JS. Store as `GOOGLE_MAPS_API_KEY` (Rails credentials + frontend env). Set a quota cap — burn risk is real. This unblocks everything and the plans assume it exists.

  **Dependency-correct sequence:**

  ```
  REQ-BE-00036  ─┬─▶ REQ-FE-00025 ─┬─▶ REQ-FE-00026
  (lat/lng mig)  │   (AddressPicker │   (mount picker on Cargo)
                 │    on TW)        │
                 │                  └─▶ REQ-FE-00027 ─┐
                 │                      (radius circle)│
                 └─▶ REQ-BE-00037 ──────────────────────┘
                     (pickup_radius_km + Haversine)
                                                       │
                                                       └─▶ REQ-FE-00028
                                                           (US51 detail map)
                                                           + blocked on US39 merge
  ```

  | # | TAG | Why this slot | Size |
  |---|---|---|---|
  | 1 | `REQ-BE-00036` | Two migrations, no backfill, no spatial. Unblocks every FE issue. | S |
  | 2 | `REQ-BE-00037` | Independent of FE; merge in parallel with FE-00025. | S |
  | 3 | `REQ-FE-00025` | Builds the shared `<AddressPicker />` — biggest single piece. The other FE issues mount/extend it. | L |
  | 4 | `REQ-FE-00026` | Pure composition: mount `<AddressPicker />` on Cargo forms. Trivial after 3. | S |
  | 5 | `REQ-FE-00027` | Extends the AddressPicker preview with the draggable circle. Needs both 2 and 3 merged. | M |
  | 6 | `REQ-FE-00028` | **Hard dep on US39 (`REQ-FE-00024`) merged + TW/Cargo records carrying lat/lng.** If US39 slips to Sprint 4 per today's go/no-go, this one falls late in Sprint 4. P2, not P1 — fine to land last. | M |

  **Watch-outs:**
  - US51 (`REQ-FE-00028`) is contingent on US39. Track the Sprint 3 day-5 decision: if you defer `REQ-FE-00024` to Sprint 4, **sequence US39 first**, then US51 — otherwise US51's `<section id="shipment-tracking-map">` anchor doesn't exist.
  - AR-only is client-side only (`componentRestrictions: { country: 'ar' }`) per the closed triage decision — don't add a server-side bounding-box gate.
  - All six plans exist already; read those, don't replan.
  ````,
  h1-level: 4,
  label-prefix: "cc1625-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/sprint-status`
  ```,
  h1-level: 4,
  label-prefix: "cc1626-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Sprint 3 status (day 5 of 7).

  5 of 10 commitments merged. Massive movement in the last ~8 hours.

  | Dev | Commit | Status | Risk |
  |---|---|---|---|
  | Brian | `REQ-BE-00033` US8 Pago (#213) | not started — still no PR or branch | at risk |
  | Fernando | `INF-FE-00005` notifs scaffold (#217) | not started — no PR (Fernando heads-down on INF-INFRA-00004 all day) | at risk |
  | Tomás | `REQ-FE-00024` US39 detalle FE (add-on) | not started — no PR. Tomás pulled Sprint 4 GMaps work forward instead (PRs #252/#255/#256/#261/#262) | at risk |
  | Lucas | `REQ-BE-00034` US32 baja vehículo (#215) | in review — PR #220 still draft, ~3 days stale, CI skipped | at risk |
  | Matías + Lucas | `REQ-FE-00022` + `REQ-FE-00023` US17 Carrier+Shipper (add-ons) | in review — combined PR #258, CI green, no reviewer yet | at risk |
  | Fernando | `INF-INFRA-00004` OIDC deploy (#202) | in review — phases 1-4 merged (#232/#245/#246/#251/#253/#254/#257/#259); phase 5 frontend-deploy open as PR #260, CI green | on track |
  | Matías | `FIX-BE-00001` TW nullable destination (#211) | merged — PR #227 merged 15:53 UTC | merged |
  | Tomás | `REQ-BE-00035` Envíos endpoints | merged — PR #248 | merged |
  | Franco | `REQ-FE-00017`+`REQ-BE-00024` US10/US12 | merged — PR #221 (carryover) | merged |

  Critical path: review + land PR #258 (US17 combined) → reviewer needed; CI is green, just needs eyes. Brian (US8) is the standalone hole — no branch on day 5, original commitment, all upstream deps cleared 24h ago.

  Headline: 2 add-ons now have a PR (US17 combined) so the day-5 go/no-go threshold isn't formally crossed, but **US39 (`REQ-FE-00024`) should be explicitly deferred to Sprint 4** — owner pulled GMaps work in early instead. Meanwhile Brian's US8 Pago is the real fire and `INF-FE-00005` likely slips too.
  ```,
  h1-level: 4,
  label-prefix: "cc1627-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  I want to pile up the GMaps work in a single monolith PR, what do you recommend I do?
  ```,
  h1-level: 4,
  label-prefix: "cc1628-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Doable, and arguably fine since you're solo owner on GMaps for Sprint 4 — but a few specific tradeoffs to call out first, then concrete mechanics.

  ## What you give up

  - **Granular revert.** Squash-merge collapses the whole thing into one commit; if US50's Haversine scope regresses matching, you can't `git revert` just that — you revert all six features.
  - **Release-please granularity.** All six features become a single `feat(...)` line in CHANGELOG. Versioning still bumps once correctly; the history just reads coarser.
  - **Reviewer load.** ~2 migrations + AddressPicker component + 3 form integrations + radius circle + Haversine scope + i18n strings × 5 locales × 6 features. Whoever you tag will rubber-stamp or stall — accept that and pre-empt it with a PR body that links each plan section to its diff.
  - **Pre-PR gate scales up.** CLAUDE.md requires `/critique` → `/polish` → `/audit` + `just frontend-test-coverage` (80% threshold) + `just frontend-test-e2e` + `just backend-test` + `just lint` *all green locally before opening*. On a monolith, that's a real gate, not a quick check.

  ## What to exclude

  **Drop `REQ-FE-00028` (US51) from the monolith.** It has a hard dep on `REQ-FE-00024` (US39 detail FE) being merged first — and US39 is on the Sprint 3 deferral list right now. If you include US51, the monolith can't merge until US39 lands separately. Keep it as a follow-up PR after US39 ships.

  That leaves 5 issues in the monolith: `REQ-BE-00036`, `REQ-BE-00037`, `REQ-FE-00025`, `REQ-FE-00026`, `REQ-FE-00027`.

  ## Mechanics

  ```sh
  # 1. Integration branch off main
  git fetch origin
  git switch -c feature/gmaps-fulfilment origin/main

  # 2. Fold the 5 sub-branches in dependency order (BE first, then shared FE, then mounts)
  git merge --no-ff feature/REQ-BE-00036-lat-lng-coords
  git merge --no-ff feature/REQ-BE-00037-pickup-radius-haversine
  git merge --no-ff feature/REQ-FE-00025-us48-address-picker
  git merge --no-ff feature/REQ-FE-00026-us49-cargo-address-picker
  git merge --no-ff feature/REQ-FE-00027-us50-pickup-radius
  # Resolve conflicts as they surface — expect: routes.rb, locales/*.yml, strong params, AddressPicker imports
  ```

  Then close the 5 existing PRs (#252, #255, #256, #261, #262) with a comment `Folded into #NEW — see <link>` so reviewers don't waste cycles on stale branches.

  ## PR shape

  - **Title (squash-merge subject):** `feat(fulfilment): geocoded addresses, pickup radius, and Haversine matching (US48 + US49 + US50)` — single conventional prefix, no `[REQ-...]` bracket (would break release-please per `feedback_pr_title_format`).
  - **Body:** `Closes #234, #235, #239, #240, #241` (the 5 GH issues). Section per US with a "what changed / where to read" pointer to each plan under `docs/features/REQ/REQ-{BE,FE}-000{25..27,36,37}/`.
  - `--assignee @me` (per `feedback_pr_assignee`).

  ## Hard prereqs before `gh pr create`

  1. GMaps API key in place (frontend env + Rails credentials) — otherwise FE tests can't run.
  2. `just backend-test` green (RSpec + new model/request specs for both BE issues).
  3. `just frontend-test-coverage` green and ≥80% across all four metrics (the AddressPicker is the coverage risk — write Vitest first).
  4. `just frontend-test-e2e` green with at least one Playwright golden-path per FE issue.
  5. `/critique` → `/polish` → `/audit` against the new FE surface. Don't skip — CI is expensive and this PR is huge.
  6. `just lint` clean (stylelint design-system rules will trip on raw hex in any map styling — use tokens).

  ## Honest alternative

  If reviewer attention turns out scarce, **stack** instead of monolith: one branch per layer (BE → shared FE → mounts), each PR-from-prev. You keep "one logical merge", reviewers eat it in 3 sittings, and you can ship the BE half while iterating on FE. Costs you the convenience of cross-layer refactors inside a single diff.

  Want me to start the integration branch and run the first merge?
  ````,
  h1-level: 4,
  label-prefix: "cc1629-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/handoff the monolith playbook`
  ```,
  h1-level: 4,
  label-prefix: "cc1630-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Handoff written.

  - **File:** `/tmp/handoff-gmaps-monolith.md`
  - **Focus:** monolith playbook for the 5 Sprint-4 GMaps issues (US51 excluded — depends on US39).
  - **Includes:** scope table with branches/PRs/plans, merge order, expected conflict surfaces, PR title/body shape, hard pre-PR gate, watch-outs (SQLite-forever, i18n, AR-only client-side), and suggested skills (`gdsi-sdlc:issues:implement`, `verify`, `/critique`+`/polish`+`/audit`, `code-review`).
  - **Does not duplicate** the six plan files or the issue frontmatter — references by path only.
  ```,
  h1-level: 4,
  label-prefix: "cc1631-",
)
