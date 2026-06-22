#import "@preview/cmarker:0.1.8"

= Plan issue assignment distribution for team

_2026-05-09 13:25 UTC — rama `HEAD` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc2728-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:project:onboard full`
  ```,
  h1-level: 4,
  label-prefix: "cc2729-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Project Onboarding Complete

  **Task Type**: full
  **Documents Loaded**: README, 00-philosophy-and-architecture, 01-patterns-and-implementation, 02-coding-guidelines, 03-module-reference, 04-ai-harness, 05-testing-strategy, 06-roadmap, `.gdsi-sdlc/config.json`, `CLAUDE.md`
  **Mode**: standard

  ### Project Summary
  - **Name**: Truckr® (FIUBA GDSI capstone)
  - **Stack**: Rails 8.1 API-only (Ruby 3.4, SQLite + Solid* stack) · React 18 + Vite 5 + TS 5.3 (Deno runtime) · Typst docs · `mise`/`just`/`prek`
  - **Architecture**: Monorepo, client/server. Static SPA → stateless REST `/api/...`. No microservices, no Redis.

  ### Key Rules I'll Follow
  - es-AR for product content, English for code/identifiers/commits. Glossary at `docs/05-appendices/glossary.md` is term source-of-truth.
  - Models in English: `Carrier` (Transportista), `Shipper` (Expedidor — never `Cliente`). No denormalized role booleans on `User`; relation row + scopes/predicates only.
  - Conventional Commits required (release-please drops drift).
  - Backend tests = **RSpec only** (`backend/spec/`), no Minitest. Frontend = Vitest + Playwright.
  - API: `/api/...`, snake_case JSON, no auth yet, CORS allow-list (never `*` in prod).
  - Issues = files under `.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}/<TAG>-slug.issue.md`. Status = folder.
  - New AI capability → versioned skill folder, never chat-only.
  - PRs: `gh pr create --assignee @me`. Team size = 6.
  - No PDFs in git; release-please attaches them.

  ### Ready to Help With
  - Backlog grooming + USM/WBS edits in Typst
  - Rails domain models (Identity → Marketplace → Fulfilment → Commerce per Tier 1 funnel)
  - API endpoints under `Api::*` with request specs
  - Frontend (LandingPage split, quote form → real POST), driven via `impeccable`/`critique`/`polish`
  - AI skills + `.gdsi-sdlc/` issue movement
  - CI / pre-commit gap closure (test workflow, rubocop, brakeman)

  ### Active Context
  - gdsi-sdlc config: loaded (`.gdsi-sdlc/config.json`, project #7, owner `tcorzo`, automation disabled)
  - OE Assessment: not assessed (`oe_assessment: false`)
  - In-flight: `REQ-BE-00005` (domain model — gates Tier 1), `INF-BE-00003` (ActiveAdmin), `REQ-DOC-00002`, `REQ-FE-00002`, `INF-GEN-00001`
  - Next priority funnel: `REQ-BE-00005` → `REQ-BE-00020` (Identity) → `REQ-BE-00021` (Marketplace) → `REQ-BE-00022` (Fulfilment) → `REQ-BE-00023` (Auth fullstack)
  - Onboarding docs path: `docs/onboarding/` (not `documentation.onboarding: true` in config — flag is stale; docs exist)

  What do you want to tackle?
  ```,
  h1-level: 4,
  label-prefix: "cc2730-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  right now, I'm, like, I'm implementing serially. Uh, each of the first p zero issues, but I want to go ahead and plan how will distribute work among my other teammates for the rest of the issues. I want you to list and propose a issue assignment draft.
  ```,
  h1-level: 4,
  label-prefix: "cc2731-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll inventory the backlog and the dependency graph to draft a sensible distribution.
  ```,
  h1-level: 4,
  label-prefix: "cc2732-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Here's a draft built off the 6-stream split in `DEPENDENCY-GRAPH.md`. You stay on the Tier 1 funnel; the other 5 each get a stream + a cross-cutting starter they can begin **today** (no Tier 1 wait).

  ## Assignment draft (6 devs)

  ### Dev 1 — you (Tier 1 funnel + first endpoint)
  **Sequential, blocks everyone else.** Already in review:
  - `REQ-BE-00005` (domain design), `REQ-BE-00020` (Identity), `INF-BE-00003`, `REQ-DOC-00002`, `REQ-FE-00002`, `INF-GEN-00001`

  Then Ready:
  - `REQ-BE-00021` (Marketplace) → `REQ-BE-00022` (Fulfilment)
  - `INF-BE-00004` (error envelope) — fold into the first real `Api::*` controller you ship

  ### Dev 2 — Identity / Auth / Account
  Start now (parallel, no Tier 1 dep): `INF-BE-00005` (mailer + Solid Queue scaffolding — needed for email verify anyway)
  After `REQ-BE-00020` merges:
  - `REQ-BE-00023` (auth fullstack US1+US2) → `REQ-FE-00012` (US3 edit profile) → `REQ-BE-00025` (US16 password) → `REQ-BE-00028` (US22 email verify)

  ### Dev 3 — Shipper discovery (Marketplace consumer)
  Start now: `INF-FE-00003` (React Router + `App.tsx` split — gates all FE features)
  After `REQ-BE-00021` merges:
  - `REQ-FE-00006` (search) → `REQ-FE-00007` (paginate) → `REQ-FE-00008` (sort)
  - `REQ-FE-00013` (filters), `REQ-FE-00014` (carrier details), `REQ-FE-00015` (offer wizard)

  ### Dev 4 — Carrier-side + Vehicle + Reviews tail
  After `REQ-BE-00020` merges:
  - `REQ-BE-00009` (vehicle reg) → `REQ-BE-00010` (fleet)

  After `REQ-BE-00021`:
  - `REQ-FE-00016` (publish availability), `REQ-FE-00017` (offers inbox) → `REQ-FE-00018` (filter inbox), `REQ-BE-00024` (US12 accept)

  After `REQ-BE-00027` (delivered) lands (from Dev 5):
  - `REQ-BE-00013` → `REQ-BE-00014` → `REQ-BE-00015` → `REQ-BE-00029` (reviews chain)

  ### Dev 5 — Payments + lifecycle markers + Insurance (Release 3)
  Start now: spike MercadoPago SDK (no ticket — just dev research toward `REQ-BE-00006`)
  After `REQ-BE-00022` merges:
  - `REQ-BE-00006` (MP integration) → `REQ-BE-00007` (checkout) → `REQ-BE-00008` (contact reveal)
  - `REQ-BE-00026` (picked-up) → `REQ-BE-00027` (delivered)
  - `REQ-BE-00011` (payout) + `REQ-BE-00012` (payout history — fold)
  - Insurance chain (Release 3, defer): `REQ-BE-00016` → `00017` → `00018` → `00019`

  ### Dev 6 — Maps / tracking / history + CI
  Start now (independent of everything):
  - `INF-INFRA-00001` (move CI to repo root) → `INF-INFRA-00002` (frontend CI: Vitest + tsc + Playwright)
  - `INF-FE-00001` (cierre de artifacts — doc closure)

  After `INF-FE-00003` (Dev 3) lands:
  - `REQ-FE-00009` (Maps SDK) → `REQ-FE-00010` (live nav) → `REQ-FE-00011` (ETA/reroute)

  After `REQ-BE-00022`:
  - `REQ-FE-00019` (tracking page), `REQ-FE-00020` (history)

  ### Unassigned / deferred (Release 3)
  - `REQ-BE-00030` (composite trips), `REQ-BE-00031` (chained orders) — assign in sprint 5+ once Dev 5 closes lifecycle.

  ## Things worth flagging before locking this in
  - **Skill match**: I assumed generic full-stack. If teammates skew BE-heavy or FE-heavy, swap Dev 3 ↔ Dev 4 (both lean FE) or merge their loads with a partner.
  - **Dev 5 is heaviest** — Payments + Insurance + lifecycle is ~10 tickets. If insurance doesn't move to Release 3, split with Dev 4.
  - **Dev 1 (you) is the bottleneck** — every stream waits on `REQ-BE-00020/21/22`. If you can pair Dev 2 onto `REQ-BE-00021` while you finish `REQ-BE-00020`, the funnel opens ~1 sprint sooner.

  Want me to write this to `docs/features/ASSIGNMENTS.md` or open a Plan to negotiate before committing?
  ```,
  h1-level: 4,
  label-prefix: "cc2733-",
)
