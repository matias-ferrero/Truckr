# Sprint 1 — Plan

Sprint 1 commits to delivering, end-to-end and demoable: **sign-in / registration, vehicle registration, transport-window publishing, transport-window search, the public carrier profile page, and a post-login dashboard with global navigation that ties them together**. All running on the AWS environment Fernando is building in parallel.

The Sprint 1 narrative we're presenting:

> *A transporter signs up, logs in, and lands on a dashboard showing their fleet, their published transport windows, and a placeholder for incoming offers. From there they can register a truck and publish a window. A shipper signs up, lands on a different dashboard with search as the primary action, finds a window the transporter just published, and clicks through to that transporter's public profile to vet them before reaching out. Everything is running on the AWS environment Fernando built.*

Authoritative cross-references:
- User-story texts: [`docs/artifacts/backlog-us.typ`](../artifacts/backlog-us.typ).
- Per-issue execution order: [`DEPENDENCY-GRAPH.md`](DEPENDENCY-GRAPH.md).
- Live status (folder source-of-truth): [`.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}/`](../../.gdsi-sdlc/issues/).
- Glossary (term source-of-truth): [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md).

> **Update rule**: when an issue's status changes, update [`ISSUES-INDEX.md`](ISSUES-INDEX.md) first; this doc is regenerated/refreshed at sprint review, not on every move.

## Commitment Summary

| Sprint | Commitment | What ships | Notes |
|--------|------------|------------|-------|
| **Sprint 1** | Carrier onboarding spine + Shipper discovery half + dashboard glue + AWS deploy | Sign-in/register, vehicle registration, transport-window publishing, transport-window search, public carrier profile, post-login dashboard, AWS deployment | Full demo loop: a transporter publishes a window and a shipper finds it. |
| **Sprint 2 (stretch)** | Discovery polish + carrier inbox | Pagination, sorting, multi-criteria filters on search, the "offers received" inbox | Pull only after Sprint 1 commitment is green. |

**What's explicitly out of Sprint 1 scope:**

- **Email infrastructure of any kind.** No welcome email, no email verification, no transactional notifications. Mailer scaffolding stays out until a user story requires it on screen.
- **Profile editing as a primary commitment.** It stays on the sprint board as a **free-agent issue** — whoever finishes their primary feature first picks it up. See "Free-agent issue" below.
- **The carrier offers inbox.** It would be visually empty in Sprint 1 anyway because shippers can't make offers yet (that's a future user story).

## Closed in Sprint 1 (foundation already landed or in flight)

These cleared the runway for the user-facing slices. None of them maps to a user story directly — they unblock everything in Tier 1 of the dependency graph.

| TAG | Title | Sprint role | Evidence |
|-----|-------|-------------|----------|
| `INF-GEN-00002` | Bootstrap backend, frontend, docs y AI harness | Greenfield scaffolding (Rails 8 + React/Vite + skills + Kanban) | PR #63 |
| `INF-FE-00002` | Hardenear `frontend/.gitignore` | Hygiene — keep `.vite/`, `.env*` out of git before real FE work starts | PR #66 |
| `INF-BE-00003` | Agregar ActiveAdmin al backend | Read-only inspection panel for the Tier 1 models | PR #73 |
| `REQ-DOC-00002` | Artefacto de riesgos (metodología + registro) | Course deliverable — no code dep | PR #77 |
| `INF-GEN-00001` | Sin estimaciones — throughput projection CLI | Tooling for the cronograma + sprint forecasting | PR #81 |
| `INF-BE-00001` | Reestructurar WBS por funcionalidades | Doc artifact — no code dep | PR #128 / #131 |
| `REQ-BE-00005` | Diseñar modelo de dominio inicial | ADRs + ERDs + Identity spec — gates every Tier 1 model impl | PR #74 / #131 |
| `REQ-BE-00020` | Implementar contexto Identity (User, Carrier, Shipper, Vehicle migrations + AR models) | Foundation: unblocks Auth and Vehicle reg | PR #133 |
| `REQ-BE-00021` | Implementar contexto Marketplace (TransportWindow, CargoOffer, Quote) | Foundation: unblocks publishing, search, and all Sprint 2 stretch | PR #134 |
| `REQ-BE-00022` | Implementar contexto Fulfilment (Shipment + state machine, TrackingEvent, Route) | Foundation: unblocks lifecycle, payment, tracking, reviews (future sprints) | PR #135 |

In flight (open PR, expected to land before sprint mid-point):

| TAG | Title | What it absorbs | PR |
|-----|-------|-----------------|----|
| `REQ-BE-00009` + `REQ-BE-00010` | Vehicle registration with photos + multi-vehicle fleet support | **US14 in full**, plus React Router setup and `App.tsx` split (originally `INF-FE-00003`), plus an API base controller and Pundit policy scaffolding (chunk of `INF-BE-00004`), plus auth scaffolding helpers like `RequireCarrier` | PR #144 (open) |

In-flight doc artifacts:

| TAG | Title | Status caveat |
|-----|-------|---------------|
| `REQ-FE-00002` | Cronograma básico con hitos clave | Doc artifact, ready to merge. |

**The impact of PR #144 is large enough to call out separately.** It removes Tomás's truck-registration work from his queue, eliminates Lucas's frontend foundation issue entirely, and partially absorbs Matias's error-envelope work. The team-assignment table below assumes #144 lands and reassigns those four people accordingly.

## Remaining in Sprint 1 (commitment work)

The user-facing commitment, broken down by feature. Each row says what ships, who owns it end-to-end, and what it depends on.

### Sign-in and registration

| Issue | Owner | Status | Depends on | Notes |
|-------|-------|--------|------------|-------|
| `REQ-BE-00023` — Auth fullstack (registro, login, sesiones + pantallas) | **@tcorzo** | Backlog | `REQ-BE-00020` (Identity) ✓ | Single issue covering US1+US2 BE+FE. Session-cookie strategy, no JWT. Ships register/login/logout/me endpoints plus the screens. Required for **every** subsequent `/me/*` endpoint. No welcome email — mailer cut. Tomás also serves as the team's reference-implementation author: every layer of this PR (session middleware, authn-protected controllers, AR write paths, React Router pages, RSpec request specs, Vitest+MSW frontend tests, Playwright E2E) is the pattern other devs copy when they pick up their own features. |

### Vehicle registration (US14)

| Issue | Owner | Status | Depends on | Notes |
|-------|-------|--------|------------|-------|
| `REQ-BE-00009` + `REQ-BE-00010` | **@tcorzo** | InReview (PR #144) | `REQ-BE-00020` (Identity) ✓ | Already implemented end-to-end in PR #144 — vehicle CRUD with photos via ActiveStorage, Pundit policies, Pagy pagination, rswag-generated OpenAPI, and the React fleet UI. Covers all of US14 ACs including multi-vehicle (AC#6). |

### Transport-window publishing (US9 — promoted to committed)

| Issue | Owner | Status | Depends on | Notes |
|-------|-------|--------|------------|-------|
| `REQ-FE-00016` — Publicar ventana de transporte (TransportWindow CRUD) | **@matias-ferrero** | Backlog | `REQ-BE-00023` (Auth — `current_carrier`); `REQ-BE-00021` (Marketplace) ✓; `REQ-BE-00009` (Vehicle — required FK) ✓ via PR #144 | The transporter creates a "I'm driving from A to B between these dates with this truck for this price per km" listing. Fullstack: BE CRUD endpoints + FE management screen. First write-path against the Marketplace context. Closes the carrier-onboarding narrative end-to-end and produces the artifact Franco's search will find. |

### Transport-window search (US4 base — pulled into committed)

| Issue | Owner | Status | Depends on | Notes |
|-------|-------|--------|------------|-------|
| `REQ-FE-00006` — Búsqueda de ventanas de transporte por zona origen/destino + rango de fechas | **@FrancoRicciardo** | Backlog | `REQ-BE-00021` (Marketplace) ✓ | The shipper enters origin, destination, and date range and gets back matching transport windows with embedded carrier and vehicle info. Pulled into Sprint 1 commitment so the demo loop is two-sided — Matias's flow produces, Franco's flow consumes. Pagination and sort (the rest of US4) stay in stretch. |

### Public carrier profile (US6 — pulled into committed)

| Issue | Owner | Status | Depends on | Notes |
|-------|-------|--------|------------|-------|
| `REQ-FE-00014` — Página de detalle de transportista (perfil público + CTA ofertar) | **@bcespedes** | Backlog | `REQ-BE-00020` (Identity) ✓; `REQ-BE-00009` (Vehicle) ✓ via PR #144 | The screen a shipper lands on after clicking through from a search result — vetting page before reaching out to the transporter. No auth dep on the visitor side, so Brian can start day one. Reached from a search result with the selected window's context preserved (computes estimated cost from that window's price/km). Reviews-related elements (rating average) render as empty-state since reviews aren't shipped yet. |

### Post-login dashboard + global navigation (no user story — UX glue)

| Issue | Owner | Status | Depends on | Notes |
|-------|-------|--------|------------|-------|
| `REQ-FE-00021` — Dashboard post-login + navegación global | **@LucasDondo** | Backlog | `REQ-BE-00023` (Auth — needs `current_user` + role detection); soft-depends on every other feature for the right links to render | The post-login landing page plus the persistent global navigation (header, role-aware links). For a transporter: cards for fleet, published windows, and a placeholder for incoming offers, all linking to the relevant features. For a shipper: search as the primary action plus a placeholder for "offers I've made". This is the UX layer that makes everything else feel like one app instead of disconnected screens. **Lucas should produce a rough sketch in week one** — paper, whiteboard, or mockup tool — defining what each role sees and where each card links. That sketch becomes the contract every other feature builds against, so Brian, Matias, Franco, and Tomás design their screens to fit a shared map instead of rendering navigation independently. The implementation can land mid- or late-sprint; the sketch matters more than the timing. |

### AWS deployment (no user story — infrastructure)

| Owner | What ships |
|-------|-----------|
| **@FernandoYu** | The AWS environment hosting the backend, frontend, and any supporting services. Fernando is **not assigned to any user story this sprint** — deployment is full-time work and the demo depends on it. |

### Free-agent issue — profile editing (US3)

| Issue | Owner | Notes |
|-------|-------|-------|
| `REQ-FE-00012` — Modificar perfil de usuario | _Unassigned — first to finish_ | The form where a signed-in user edits their personal data. Originally on the committed list, now floating because Lucas (its previous owner) moved to the dashboard. **Picked up by whoever among Brian, Lucas, Matias, or Franco finishes their primary feature first.** Tomás and Fernando are explicitly excluded from this pickup — Tomás's plate is full with Auth and the reference-implementation role, Fernando's with infrastructure. Depends on `REQ-BE-00023` (Auth) and on whatever shape Tomás's profile-related endpoints take, so realistically the earliest start is mid-sprint after Auth BE lands. |

## Sprint 2 — Stretch goals

Pull these only if Sprint 1 commitment is green by mid-sprint. All require `REQ-BE-00021` (Marketplace) merged on `main`, which it is.

| US | Issue | What it adds |
|----|-------|---------------|
| US4 (cont.) | `REQ-FE-00007` — Paginado de resultados de búsqueda | Pagination on top of Franco's search base. |
| US4 (cont.) | `REQ-FE-00008` — Ordenamiento (asc/desc) | Sort on top of Franco's search base. |
| US5 | `REQ-FE-00013` — Filtrado multi-criterio | Combinable filters (precio/km, peso, volumen, capacidad) on top of search. |
| US10 | `REQ-FE-00017` — Bandeja de ofertas recibidas | The carrier inbox listing CargoOffers received against TransportWindows. **Visually empty until shippers can actually create offers (a future sprint), so demo value is limited.** Listed for completeness, not enthusiasm. |

## Parallelism analysis

Wave boundaries are **dependency boundaries**, not calendar boundaries — work flows into the next wave the moment its predecessor merges to `main`, not at a fixed day.

### Wave 0 — Day 1 (everyone starts)

| Stream | Owner | What can start immediately |
|--------|-------|----------------------------|
| Auth BE | Tomás | `REQ-BE-00023` BE half (sessions, register, login, logout, me endpoints) |
| Carrier profile page | Brian | `REQ-FE-00014` — no auth dep on visitor side, starts day one |
| Dashboard sketch | Lucas | Paper/whiteboard/mockup of both role landing pages — **week 1 deliverable**, drives every other team member's navigation contract |
| TransportWindow publishing BE | Matias | `REQ-FE-00016` BE half (CRUD endpoints) — only needs Marketplace ✓ + waiting on Auth BE for `current_carrier` |
| TransportWindow search | Franco | `REQ-FE-00006` BE half (the search endpoint) — only needs Marketplace ✓; FE half waits on `REQ-BE-00009` ✓ via #144 + auth scaffolding |
| AWS infrastructure | Fernando | Full-sprint scope, parallel to everything else |

### Wave 1 — Once Auth BE lands

| Stream | Owner | What unblocks |
|--------|-------|----------------|
| Auth FE | Tomás | Login/register/logout screens — needs PR #144 router setup |
| Dashboard implementation | Lucas | Real implementation of the sketch — needs Auth BE for `current_user` and role detection |
| TransportWindow publishing FE | Matias | The carrier-side management screen |
| TransportWindow search FE | Franco | The shipper-side search screen |

### Wave 2 — Profile editing pickup

The free-agent issue (`REQ-FE-00012`) gets picked up by whoever among Brian, Lucas, Matias, or Franco finishes first. Realistic earliest start is when Auth FE lands (mid-sprint).

### Critical path

```
Tomás:          Auth BE ──▶ Auth FE (login/register screens)
                  ↓
                Unblocks: dashboard implementation, publishing FE, search FE,
                          profile editing pickup, carrier profile page (current_user-dependent
                          elements only — visitor view is not blocked)

Lucas (parallel): Dashboard sketch (week 1) ──▶ Dashboard implementation (after Auth BE)

Fernando (parallel): AWS infrastructure (full sprint, independent)
```

Tomás's auth queue gates Wave 1 for everyone except Brian (who can ship the visitor view of the carrier profile page without auth) and Fernando (independent). The auth backend is the single biggest unlock — landing it in the first half of the sprint is the priority.

## Team assignments

Six people, six concurrent streams. The "one full feature per teammate" rule applies to **everyone except Tomás and Fernando** — Tomás is the auth + reference-implementation owner whose PRs the other four read before starting their own slices, and Fernando is on AWS infrastructure full-time.

> This is a **starting proposal**, not a contract. Adjust at sprint kickoff.

| Member | Primary feature (Sprint 1) | Stream / role |
|--------|----------------------------|---------------|
| **@tcorzo** (Tomás) | Sign-in and registration (`REQ-BE-00023`) — auth fullstack, plus serving as the reference-implementation author for the rest of the team. Vehicle registration (`REQ-BE-00009` + `REQ-BE-00010`) already shipped in PR #144. | Auth + reference impl — **critical path for Wave 1** |
| **@bcespedes** (Brian) | Public carrier profile page (`REQ-FE-00014`) — the screen a shipper lands on to vet a transporter, reachable from search results. | Discovery FE |
| **@LucasDondo** (Lucas) | Post-login dashboard + global navigation (`REQ-FE-00021`) — UX glue across every other feature. **Week 1: produce sketch defining both role landing pages. Mid-late sprint: implement.** | UX foundation |
| **@FernandoYu** (Fernando) | AWS deployment infrastructure (full sprint, no user-story work). | Infrastructure |
| **@matias-ferrero** (Matias) | Transport-window publishing (`REQ-FE-00016`) — fullstack, the carrier-side write path that creates the artifact Franco's search consumes. | Carrier-side fullstack |
| **@FrancoRicciardo** (Franco) | Transport-window search (`REQ-FE-00006`) — fullstack, the shipper-side discovery surface that finds what Matias's flow produces. | Shipper-side fullstack |

### Free-agent issue

| Issue | Eligible owners | Trigger |
|-------|------------------|---------|
| Profile editing (`REQ-FE-00012`) | Brian, Lucas, Matias, Franco | Picked up by whichever of the four finishes their primary feature first. Tomás and Fernando explicitly excluded. |

The free-agent mechanism exists because feature sizes are not equal — the carrier profile page is smaller than transport-window publishing, the dashboard scope can compress or expand depending on how much navigation chrome we want. Rather than guess at sizing now and over- or under-commit individuals, we let the first person to finish absorb the floating issue. This also gives the four eligible owners a natural incentive to ship cleanly rather than gold-plate.

### Why this split

- **Tomás owns auth and the reference-implementation role.** Auth is the first feature that exercises every layer of the stack — session middleware, controller scaffolding, FE routing, MSW-mocked tests, RSpec request specs, Playwright E2E. The PRs become the team's "this is how we build a feature here" canon. Tomás is the most experienced in both Rails and React, which matters because every other team member will read his auth PRs before starting their analogous slice. He's deliberately not assigned anything else this sprint — auth + reference role is enough scope, and piling on creates risk for the critical path.
- **Brian takes the carrier profile page.** No auth dependency on the visitor side, so Brian starts day one and isn't blocked by Tomás's queue. The page is reached from a search result, so Brian works closely with Franco on what context gets passed in the URL.
- **Lucas owns the dashboard and global navigation.** This is a pivot from his original frontend-foundation role (which got absorbed by PR #144). The dashboard is genuinely UX work — what the user sees first, where they go from there, how the app feels stitched together — and it needs an early sketch to set the navigation contract before the others build their features. Lucas is the right owner because his previous frontend-foundation work made him already-thinking about the cross-feature concerns.
- **Fernando owns AWS deployment.** Full-sprint scope, parallel to everything else, no user-story assignments. The demo runs on what he builds.
- **Matias takes transport-window publishing.** Fullstack feature on a Marketplace context that pairs naturally with the API base-controller work he was already starting. He produces the listings Franco's search will find.
- **Franco takes transport-window search.** The other half of the marketplace loop — the shipper enters origin, destination, dates, and finds what Matias's flow produced. Pulled into Sprint 1 from stretch so the demo is two-sided, not one-sided.

### Concurrent issues at peak (mid-sprint)

After Wave 0 dependencies clear, the team is running roughly six concurrent streams:

```
@tcorzo          ──▶ Auth FE (after Auth BE merged)
@bcespedes       ──▶ Carrier profile page
@LucasDondo      ──▶ Dashboard implementation (after sketch + Auth BE)
@FernandoYu      ──▶ AWS infrastructure (full sprint)
@matias-ferrero  ──▶ Transport-window publishing FE (after BE half)
@FrancoRicciardo ──▶ Transport-window search FE (after BE half)
                  +
                 Whoever finishes first ──▶ profile editing pickup
```

That's roughly the `max_concurrent: 3` per stream-owner rule from `.gdsi-sdlc/config.json` × 2 active streams per dev — comfortable, not overloaded.

## Risks & callouts

- **Tomás's auth backend is the single biggest unlock.** Wave 1 — dashboard implementation, publishing FE, search FE, profile editing pickup, and the parts of the carrier profile page that show signed-in-user CTAs — all wait for Auth BE. Landing it in the first half of the sprint is the priority.
- **The dashboard sketch is a week-one deliverable, not just a nice-to-have.** Without it, every other feature designs its own navigation independently and the demo will have visible seams. Lucas should produce something shareable (paper, whiteboard, mockup) by end of week one and circulate it to Brian, Matias, Franco, and Tomás for sign-off.
- **Reference-implementation reading discipline.** Brian, Lucas, Matias, and Franco should all expect to read each Tomás PR (Auth BE → Auth FE) before starting the equivalent layer of their own feature. Don't anticipate the conventions — wait and copy. Skipping this step is how the codebase grows seven different patterns for the same problem.
- **Mailer / email infrastructure is explicitly out of scope.** Welcome email, email verification, and any transactional notifications must wait for a future sprint. If the demo audience asks "doesn't it send a welcome email?", the answer is "no — that's a deliberate Sprint 2+ deferral, not an oversight."
- **Profile editing only gets picked up if someone finishes early.** It's deliberately structured as a free-agent issue rather than a primary commitment because feature sizes are uneven. If everyone runs to the wire on their primary, profile editing slips to next sprint. That's an acceptable outcome — the demo doesn't need it.
- **The carrier offers inbox is not even in stretch.** It would be visually empty without shipper-side offer creation, which doesn't exist this sprint.
- **Stretch is narrower (3 USs of polish + 1 dead-air inbox)** — committing to all four overflows team capacity given the free-agent dynamic. Hold a stretch-pull checkpoint at mid-sprint: pull only what fits.

## Mapping at a glance

```
Sprint 1 commitment
├── Sign-in + register   ─▶ REQ-BE-00023            (Tomás)            ── deps: REQ-BE-00020 ✓
├── Vehicle registration ─▶ REQ-BE-00009 + 00010    (Tomás)            ── PR #144 (in flight, in review)
├── TransportWindow pub  ─▶ REQ-FE-00016            (Matias)           ── deps: Auth, Marketplace ✓, Vehicle ✓ via #144
├── TransportWindow search ─▶ REQ-FE-00006          (Franco)           ── deps: Marketplace ✓
├── Carrier profile page ─▶ REQ-FE-00014            (Brian)            ── deps: Identity ✓, Vehicle ✓ via #144
├── Dashboard + global nav ─▶ REQ-FE-00021            (Lucas)            ── deps: Auth (for impl), every feature (for nav contract)
└── AWS deployment       ─▶ (no user-story tag)     (Fernando)         ── independent

Free-agent
└── Profile editing      ─▶ REQ-FE-00012            (first to finish)  ── eligible: Brian, Lucas, Matias, Franco

Sprint 2 stretch (Marketplace ✓ #134, Fulfilment ✓ #135)
├── Search paginate      ─▶ REQ-FE-00007
├── Search sort          ─▶ REQ-FE-00008
├── Search filter        ─▶ REQ-FE-00013
└── Carrier offers inbox ─▶ REQ-FE-00017            (visually empty until offer creation ships)
```

## Related

- [`ISSUES-INDEX.md`](ISSUES-INDEX.md) — flat index with current status per issue.
- [`DEPENDENCY-GRAPH.md`](DEPENDENCY-GRAPH.md) — full edges + Mermaid + per-stream view.
- [`docs/onboarding/06-roadmap.md`](../onboarding/06-roadmap.md) — higher-level live-vs-planned narrative.
- [`docs/artifacts/backlog-us.typ`](../artifacts/backlog-us.typ) — canonical user-story text.
- [`docs/artifacts/cronograma.typ`](../artifacts/cronograma.typ) — sprint cadence + milestone calendar.
- [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md) — term source-of-truth (Carrier, Shipper, TransportWindow, Vehicle, …).
