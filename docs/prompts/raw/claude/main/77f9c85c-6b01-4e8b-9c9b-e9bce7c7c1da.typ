#import "@preview/cmarker:0.1.8"

= Prevent GitHub Actions from running on draft PRs

_2026-05-11 01:44 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:project:onboard full`
  ```,
  h1-level: 4,
  label-prefix: "cc1216-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Project Onboarding Complete

  **Task Type**: full
  **Mode**: standard (onboarding docs present)
  **Documents Loaded**: `docs/onboarding/{README, 00-philosophy-and-architecture, 01-patterns-and-implementation, 02-coding-guidelines, 03-module-reference, 04-ai-harness, 05-testing-strategy, 06-roadmap}.md`, `CLAUDE.md`, `.gdsi-sdlc/config.json`

  ### Project Summary
  - **Name**: Truckr® (FIUBA GDSI capstone) — two-sided transportation marketplace AR.
  - **Stack**: Rails 8 API-only (Ruby 3.4, SQLite + Solid* stack, Puma+Thruster) / React 18 + Vite 5 + TS 5.3 strict (Deno runtime) / Typst docs / mise + just + prek + release-please.
  - **Architecture**: monorepo, client/server, static SPA → stateless REST `/api/`. No microservices, no Redis.
  - **Phase**: planning → implementation. Only `/up` + ActiveAdmin live on backend; static landing on frontend.

  ### Key Rules I'll Follow
  - **Spanish for content, English for code/routes/models.** UI text + errors via i18n keys, never hardcoded literals. Glossary at `docs/05-appendices/glossary.md` is source-of-truth (`Transportista`↔`Carrier`, `Expedidor`↔`Shipper`).
  - **Conventional Commits** required; PR title starts with `<type>(<scope>):` — no `[TAG]` prefix (squash → release-please).
  - **No denormalized role booleans** on User; relation row is the state.
  - **Issue lifecycle = file move** under `.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}/`. Tag `<PREFIX>-<SCOPE>-<NNNNN>`.
  - **API**: `/api/`, snake_case JSON, restrict verbs with `only:`. No auth yet, no `current_user` assumptions.
  - **Jobs**: `app/jobs/`, inherit `ApplicationJob`, idempotent, pass IDs not AR objects.
  - **Tests**: RSpec exclusive on backend; Vitest+Playwright on frontend. Coverage ≥80% on new code.
  - **Never commit PDFs**; release-please attaches them.
  - **`gh pr create --assignee @me`** on every PR.
  - **Team size 6** across 5 epics.

  ### Ready to Help With
  - Any phase: planning artifacts (Typst), backend (Rails models/controllers/jobs/migrations), frontend (React/Vite), tests, CI, issues, releases, AI harness skills.

  ### Active Context
  - `.gdsi-sdlc/config.json`: loaded (GH project #7, prefixes=[REQ,FIX,DOC,TST,REF,INF,REL], scopes=[DOC,BE,FE,INFRA,GEN]).
  - **In-flight TAGs**: `REQ-BE-00005` (domain model+ADRs, gates Tier 1), `INF-BE-00003` (ActiveAdmin), `REQ-DOC-00002`, `REQ-FE-00002`, `INF-GEN-00001`.
  - **Next priorities**: REQ-BE-00005 → 00020 (Identity) → 00021 (Marketplace) → 00022 (Fulfilment) → 00023 (Auth).
  - Working-tree note: two issues moved Backlog→InReview (`INF-INFRA-00001/2` CI workflows).

  Ready. What are we doing?
  ```,
  h1-level: 4,
  label-prefix: "cc1217-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:pr:review https://github.com/tcorzo/fiuba-gestion-tp/pull/159`
  ```,
  h1-level: 4,
  label-prefix: "cc1218-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  PR #159 is a **draft** with **2 failing checks** (frontend lint + e2e). Investigating failures and code before review.
  ```,
  h1-level: 4,
  label-prefix: "cc1219-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Found failure causes:
  - **Backend lint**: 4× `Layout/SpaceInsideArrayLiteralBrackets` rubocop violations.
  - **e2e**: `carrier-search.spec.ts:36` — `locator.fill` timeout waiting for `getByLabel('Zona de origen')`. Likely AuthShell blocks unauthenticated nav; e2e doesn't auth first.

  Checking out branch + reviewing code.
  ```,
  h1-level: 4,
  label-prefix: "cc1220-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Running rubocop locally to pinpoint the 4 violations.
  ```,
  h1-level: 4,
  label-prefix: "cc1221-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Pinpointed all blockers. Posting review.
  ```,
  h1-level: 4,
  label-prefix: "cc1222-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Review submitted: REQUEST CHANGES ❌

  PR #159 — `feat(transport window): carrier search and date-range filtering` (REQ-FE-00006, `Closes #112`).

  **Comment**: https://github.com/tcorzo/fiuba-gestion-tp/pull/159#issuecomment-4417152774
  **Formal review**: `CHANGES_REQUESTED` (2026-05-11T02:38:40Z)

  ### Blockers reported
  1. **Backend lint** — 4× `Layout/SpaceInsideArrayLiteralBrackets` in `backend/app/controllers/api/carriers/search_controller.rb:43,63` (the `["..."]` literals in the 422 `details` payloads). Two are autocorrectable.
  2. **Frontend e2e** — `frontend/e2e/carrier-search.spec.ts:4,34` was not updated by the rename commit `d20e7a1d`: still calls `/carriers/search` (route catch-all swallows it → form never renders → `getByLabel('Zona de origen').fill()` 30s timeout × 3 retries) and still mocks `**/api/carriers/search?**` instead of `/api/transport_windows/search`.

  ### Other findings (non-blocking)
  - SQLite `matching` scope materializes the whole table — fine for now, dies with the Postgres migration.
  - `render`+`return if performed?` guard pattern in controller is correct but fragile; future refactor candidate.
  - Inline `style={{}}` leak at `CarrierSearchPage.tsx:192` — move to `carrier.css`.
  - `display_name` fallback preload is correct (`includes(:user)` is in place).

  ### Not blocked
  - Issue link valid (`Closes #112`, OPEN).
  - No `[skip ci]`.
  - Backend RSpec, Vitest, build, scan_ruby, scan_js, backend `test` all green.
  - PR still in **draft** — author should fix blockers, run `bin/rubocop && deno task test:e2e` locally, then `gh pr ready 159`.
  ```,
  h1-level: 4,
  label-prefix: "cc1223-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  draft PRs should never trigger gh action runs, open a PR that fixes that
  ```,
  h1-level: 4,
  label-prefix: "cc1224-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Investigating workflows to add draft-PR skip.
  ```,
  h1-level: 4,
  label-prefix: "cc1225-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Verifying YAML validity and the diff before staging.
  ```,
  h1-level: 4,
  label-prefix: "cc1226-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Diff is clean and only touches workflows. Committing and opening PR.
  ```,
  h1-level: 4,
  label-prefix: "cc1227-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  PR #160 opened: https://github.com/tcorzo/fiuba-gestion-tp/pull/160

  **`ci: skip workflow runs on draft PRs`** — branch `ci/skip-draft-prs`, assignee `@me`, not draft, MERGEABLE. 7 checks already queued (paths-filtered workflows pick up the workflow file edits themselves, as expected).

  ### What the PR does
  - Adds `if: github.event_name != 'pull_request' || github.event.pull_request.draft == false` to all 7 PR-event jobs across `backend-ci.yml` (4), `frontend-ci.yml` (3), `pr-title.yml` (1).
  - Adds `ready_for_review` to each `pull_request: types:` list so CI wakes up the moment a draft is marked ready.
  - `release-please.yml` left untouched — push-to-main only, never PRs.

  ### Why both `types:` and `if:`
  `synchronize` fires on every push (drafts included), so `types:` alone wouldn't gate pushes to draft PRs. The job-level `if:` is the real switch; `ready_for_review` in `types:` only ensures CI fires at the draft→ready transition. The `github.event_name != 'pull_request'` half preserves push-to-main runs (where the `pull_request` object is absent).

  ### Followups for the merger
  - Once merged, push to a draft PR and confirm no runs queue (workflows on `main` apply, so existing draft PRs benefit on their next push).
  - PR #159's red CI will stay red until the author either fixes the blockers I flagged or marks it ready-for-review (which would re-trigger CI under the new rules).
  ```,
  h1-level: 4,
  label-prefix: "cc1228-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  This session is being continued from a previous conversation that ran out of context. The summary below covers the earlier portion of the conversation.

  Summary:
  1. Primary Request and Intent:
     Two sequential user requests in the recent portion:
     - **PR #159 code review** via `/gdsi-sdlc:pr:review https://github.com/tcorzo/fiuba-gestion-tp/pull/159`: Full review of `feat(transport window): carrier search and date-range filtering` (REQ-FE-00006, by FrancoRicciardo, Closes #112). Run tests, analyze CI failures, post review comment + formal review.
     - **Draft-PR CI suppression**: "draft PRs should never trigger gh action runs, open a PR that fixes that" — modify GitHub Actions workflows so CI is skipped while a PR is in draft state, then open a PR with the fix.

  2. Key Technical Concepts:
     - GitHub Actions `pull_request` event types: `opened`, `synchronize`, `reopened`, `ready_for_review`, `edited`
     - Job-level `if:` guard pattern: `github.event_name != 'pull_request' || github.event.pull_request.draft == false`
     - `synchronize` fires on every push (drafts included), so `types:` alone is insufficient to gate drafts — job-level `if:` is the real switch
     - `ready_for_review` is NOT in default `pull_request` types — must be explicitly listed so CI wakes up at the draft→ready transition
     - Conventional Commits (`ci:` for no version bump via release-please)
     - rubocop-rails-omakase rule `Layout/SpaceInsideArrayLiteralBrackets` (wants spaces inside `[ ]`)
     - Playwright `locator.fill` timeout when target label never renders due to React Router `*` catch-all swallowing unknown URL
     - `gh pr` CLI: `view`, `checks`, `comment --body-file`, `review --request-changes`, `create --assignee @me`
     - rails-omakase, RSpec, Devise, ActiveAdmin, AuthShell route gating, AuthProvider

  3. Files and Code Sections:
     - `.github/workflows/backend-ci.yml` (modified)
       - Added `types: [opened, synchronize, reopened, ready_for_review]` to `pull_request:` trigger
       - Added `if: github.event_name != 'pull_request' || github.event.pull_request.draft == false` to all 4 jobs: `scan_ruby`, `scan_js`, `lint`, `test`
       - 5 insertions

     - `.github/workflows/frontend-ci.yml` (modified)
       - Same `types:` change
       - Same `if:` guard on jobs `unit`, `build`, `e2e`
       - 4 insertions

     - `.github/workflows/pr-title.yml` (modified)
       - Extended types from `[opened, edited, reopened, synchronize]` to `[opened, edited, reopened, synchronize, ready_for_review]`
       - Added comment + `if: github.event.pull_request.draft == false` on `lint` job (no `github.event_name` fallback because this workflow is PR-only)
       - 4 insertions, 1 deletion

     - `.github/workflows/release-please.yml` (untouched — runs on `push: branches: [main]`, never on PRs)

     - `/tmp/pr159-review.md` (created, ephemeral)
       - 82-line review comment posted to PR #159 via `gh pr comment 159 --body-file`
       - Listed two blockers: 4× rubocop violations in `search_controller.rb:43,63` and stale URLs in `carrier-search.spec.ts:4,34` after rename commit `d20e7a1d`
       - Non-blocking notes: SQLite scope materializes whole table, `render`+`return if performed?` fragility, inline style leak at `CarrierSearchPage.tsx:192`

     Read (not modified) during PR #159 review:
     - `backend/app/controllers/api/carriers/search_controller.rb` (route renamed but still inside `Api::Carriers::SearchController`)
     - `backend/app/models/transport_window.rb` (diacritic-insensitive `matching` scope with Postgres/SQLite branch)
     - `backend/app/resources/carrier_search_resource.rb`
     - `backend/config/routes.rb` (route at `/api/transport_windows/search`)
     - `backend/spec/requests/api/carriers/search_spec.rb`
     - `frontend/e2e/carrier-search.spec.ts` (the broken file — line 4 mocks old URL, line 34 navigates to old URL)
     - `frontend/src/pages/search/CarrierSearchPage.tsx`
     - `frontend/src/routes.tsx` (route at `/transport_windows/search`, AuthShell wrapper)
     - `frontend/src/api/carriers.ts` (calls `/api/transport_windows/search`)

  4. Errors and fixes:
     - **Local rubocop crash** (`Could not find pagy-43.4.4, parallel-1.28.0 in locally installed gems`):
       - Fixed by running `bundle install --quiet` then `bin/rubocop -f simple` — pinpointed all 4 offenses
     - **PR #159 e2e blocker** (diagnosis, not fixed by us):
       - Diagnosed as URL rename (`d20e7a1d`) leaving `carrier-search.spec.ts` referencing `/carriers/search` / `**/api/carriers/search?**` while actual route and API moved to `/transport_windows/search`. Reported in review for the author to fix.
     - **`gh pr create` warning** "5 uncommitted changes" — harmless; pre-existing untracked `.gdsi-sdlc/issues/InReview/` files and `.claude/worktrees/`. PR #160 still created cleanly because we only staged the 3 workflow files.

  5. Problem Solving:
     - Avoided staging unrelated working-tree changes (issue-file moves under `.gdsi-sdlc/`, `.claude/worktrees/`) by explicit `git add` of only `.github/workflows/{backend-ci,frontend-ci,pr-title}.yml`.
     - Validated YAML before committing via `python3 -c "import yaml; ..."` → "yaml ok".
     - Chose to use BOTH `types: ready_for_review` AND job-level `if:` because `synchronize` events fire on draft pushes — `types:` alone is insufficient.
     - Preserved push-to-main runs by including `github.event_name != 'pull_request' ||` half of the guard (release-please.yml untouched anyway).

  6. All user messages:
     - `/gdsi-sdlc:pr:review https://github.com/tcorzo/fiuba-gestion-tp/pull/159` (skill invocation)
     - "draft PRs should never trigger gh action runs, open a PR that fixes that"

  7. Pending Tasks:
     - None explicit. The PR #160 author (user) needs to merge or request changes.
     - Post-merge verification of PR #160 (open a test draft PR, confirm no runs queue; convert to ready, confirm CI fires) — listed in the PR body's test-plan but not executed.
     - PR #159 still red — author must apply the 6-line fix (4 rubocop offenses + 2 URL updates in e2e spec) before that PR can move forward.

  8. Current Work:
     Just-completed: opened PR #160 (`ci: skip workflow runs on draft PRs`) on branch `ci/skip-draft-prs`, commit `14167a1`, assignee `@me`, not draft, MERGEABLE. Confirmed via `gh pr view 160 --json` that 7 checks are queued (workflows pick up changes to themselves via `paths:` filter). Posted a follow-up summary to the user listing what the PR does, why both `types:` and `if:` are needed, and follow-ups for the merger.

  9. Optional Next Step:
     No explicit user instruction for next step. The most-recent user request — "open a PR that fixes that" — is complete (PR #160 is open). Natural follow-ups would be:
     - Wait for the user to merge PR #160 (no autonomous merge — merging shared state needs explicit confirmation).
     - Optionally circle back to PR #159 once the author pushes fixes for the rubocop + e2e URL issues identified in the review.
     No direct quote indicates a further task — user's last directive was to open the PR, which is done.

  If you need specific details from before compaction (like exact code snippets, error messages, or content you generated), read the full transcript at: /home/[user]/.claude/projects/-home-tcorzo-fiuba-fiuba-gestion-tp/77f9c85c-6b01-4e8b-9c9b-e9bce7c7c1da.jsonl
  ```,
  h1-level: 4,
  label-prefix: "cc1229-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:pr:review https://github.com/tcorzo/fiuba-gestion-tp/pull/159

  We should use ransack for filtering and such, not a bespoke solution`
  ```,
  h1-level: 4,
  label-prefix: "cc1230-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Findings clear. PR is green now (rubocop + e2e fixed). Posting review focused on Ransack refactor.
  ```,
  h1-level: 4,
  label-prefix: "cc1231-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Review posted — REQUEST CHANGES

  PR #159 status: green CI (8/8), MERGEABLE, prior blockers fixed. New ask:

  - **Switch bespoke filter → Ransack.** `ransack 4.4.1` already in `Gemfile.lock` (transitive via `activeadmin 3.5.1`); every model already declares `ransackable_attributes`. The PR reinvents predicate plumbing on top of that.
  - **Refactor surface**: drop `TransportWindow.matching` scope + adapter branch; controller uses `TransportWindow.active.ransack(origin_zone_cont: ..., destination_zone_cont: ..., available_from_lteq: ..., available_to_gteq: ...)`. Keep required-param check, `date_from <= date_to`, and ISO-8601 rescue at controller (Ransack no-ops missing keys).
  - **SQLite full-table scan**: current `matching` scope loads every row into Ruby and `select`s in app memory (`transport_window.rb:35-38`). Recommend a `*_normalized` column written via callback with `I18n.transliterate(value).downcase`, or a Postgres `unaccent` Ransacker.
  - **Naming split**: route `/api/transport_windows/search` vs controller `Api::Carriers::SearchController` — pick one (`Api::TransportWindows::SearchController` is the consistent choice).
  - Non-blocking: fragile `render` + `return if performed?` flow; inline `style={{...}}` on `CarrierSearchPage.tsx`.

  Comment: https://github.com/tcorzo/fiuba-gestion-tp/pull/159#issuecomment-4417225551
  Formal review: REQUEST CHANGES submitted.

  Files modified: none. Files created: `/tmp/pr159-review-v2.md` (review body).
  ```,
  h1-level: 4,
  label-prefix: "cc1232-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  Why are we using a "SearchController" instead of a simple index on a TransportWindowsController?
  ```,
  h1-level: 4,
  label-prefix: "cc1233-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  No good reason — that's a fair second hit. Standard Rails+Ransack shape is:

  ```ruby
  # routes.rb
  resources :transport_windows, only: :index

  # app/controllers/api/transport_windows_controller.rb
  class Api::TransportWindowsController < Api::BaseController
    def index
      return render_missing if missing_params.any?
      return render_invalid_range if dates[:from] > dates[:to]

      q = TransportWindow.active.ransack(
        origin_zone_cont:      params[:origin_zone],
        destination_zone_cont: params[:destination_zone],
        available_from_lteq:   dates[:to].end_of_day,
        available_to_gteq:     dates[:from].beginning_of_day
      )
      windows = q.result(distinct: true).includes(vehicle: :carrier).order(:available_from)
      carriers = Carrier.includes(:user).where(id: windows.map { _1.vehicle.carrier_id }.uniq)
      render json: CarrierSearchResource.list(carriers, windows)
    end
  end
  ```

  `GET /api/transport_windows?origin_zone=...&date_from=...` — filter params *are* the search. The "/search" verb in URL is non-REST baggage. Same for the dedicated `SearchController` namespaced under `carriers/` while filtering windows — three layers of indirection doing no work.

  Want me to amend the PR comment to call this out explicitly, or leave the existing review as-is (it already flags the naming split, but doesn't go all the way to "drop the SearchController")?
  ````,
  h1-level: 4,
  label-prefix: "cc1234-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  amend the PR comment yeah
  ```,
  h1-level: 4,
  label-prefix: "cc1235-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Comment edited in place. Added a dedicated "Drop the `SearchController` — use `TransportWindowsController#index`" section with the concrete route + controller shape, called out the three-layer indirection, and added a third checklist item (`Drop Api::Carriers::SearchController`).

  Same URL: https://github.com/tcorzo/fiuba-gestion-tp/pull/159#issuecomment-4417225551
  ```,
  h1-level: 4,
  label-prefix: "cc1236-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  We're never coming out of the MVP, SQLite is always going to be the database because this won't be brought to market. Don't add Postgres baggage EVER. Document that as a primary project directive and admin merge a PR with it
  ```,
  h1-level: 4,
  label-prefix: "cc1237-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Wide surface — Postgres/PostGIS scattered across tech-vision, domain-model, onboarding, risk artifact, cost report, model comments, and historical plans. Scoping this PR tight: canonical convention files only (CLAUDE.md + tech-vision + onboarding roadmap). Historical plans + academic `.typ` artifacts + the `transport_window.rb` comments stay as follow-up sweeps. Saving memory first.
  ```,
  h1-level: 4,
  label-prefix: "cc1238-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now editing the canonical convention files.
  ```,
  h1-level: 4,
  label-prefix: "cc1239-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now updating the PR #159 review comment to drop the Postgres `unaccent` option (the directive just invalidated it).
  ```,
  h1-level: 4,
  label-prefix: "cc1240-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Merged. Memory saved.

  **PR #161** — `docs: lock SQLite as permanent production database` → admin-squash-merged into `main` as `7704db5`. Branch deleted.

  **Changes shipped:**
  - `CLAUDE.md` — new **"Database policy (UTMOST importance)"** section. Hard rules: no `citext`/`EXCLUDE`/GIN/GIST/`unaccent`/`jsonb`/RDS. Geo = lat/lng + Haversine. Search = stored normalized column via `I18n.transliterate`.
  - `docs/01-technical-vision/technical-vision.md` — ADR-002/007/009/010 rewritten; ADR-010 retitled "Geo storage: lat/lng columns, application-level distance math" (no more PostGIS Phase 2); "Decisions Deferred" purged of the DB item; new "Decisions Closed" subsection; Scalability Roadmap collapsed to Phase 0 (final).
  - `docs/onboarding/06-roadmap.md` — mirrors the same.

  **Memory saved:** `feedback_sqlite_forever_no_postgres.md` — primary feedback rule with why + how-to-apply.

  **PR #159 review comment** — also updated in-place: dropped the suggested Postgres `unaccent` ransacker option. Recommendation collapsed to a single canonical fix (persisted `*_normalized` column via `I18n.transliterate` callback + `*_cont` Ransack predicate).

  **Follow-up sweep (NOT in this PR, listed in PR body so they don't get lost):**
  - `backend/app/models/transport_window.rb:21,44` — Phase-2 PostGIS + EXCLUDE-constraint comments.
  - `docs/02-high-level-design/domain-model.md:88,100,147,332,360` — `citext`, PostGIS Phase 2.
  - `docs/artifacts/cost-report.typ:184` — RDS line in cost model.
  - `docs/artifacts/riesgos.typ:172,180` — frames PG migration as live risk; should become closed decision.
  - Historical plans (`REQ-BE-00005/21/22`) + meeting notes (`2026-05-03`) — left alone (snapshots).

  Want me to do the follow-up sweep now or hold it for a separate session?
  ```,
  h1-level: 4,
  label-prefix: "cc1241-",
)
