# Testing Strategy

## Current State

- **Backend**: RSpec (`rspec-rails ~> 7.1`) wired (`backend/spec/`, `.rspec`, `spec_helper.rb`, `rails_helper.rb`). 1 smoke spec (`spec/smoke_spec.rb`); 0 model/controller/job specs.
- **Frontend**: Two-layer testing wired (Vitest + Playwright). One component spec (`src/App.test.tsx`) and one E2E smoke (`e2e/smoke.spec.ts`).
- **CI**: only `release-please.yml` runs on pushes to `main`. No test workflow.
- **Pre-commit**: `prek` runs `typstyle` on `.typ` only. Ruby and TypeScript are not gated.

> Backend decision: RSpec is the **exclusive** backend test framework. Do not add Minitest specs or `bin/rails test`-style tests. Rails-default `backend/test/` is unused.
> Frontend decision: two layers — **Vitest** for unit/component, **Playwright** for E2E. See `frontend/TESTING.md` for the full modus operandi.

## What Lives Where

| Layer | Location | Tooling |
|-------|----------|---------|
| Backend unit / model | `backend/spec/models/` | RSpec (`type: :model`). |
| Backend controller / request | `backend/spec/requests/` | RSpec request specs (preferred over controller specs). |
| Backend background jobs | `backend/spec/jobs/` | RSpec (`type: :job`) + `ActiveJob::TestHelper`. |
| Backend system / E2E | `backend/spec/system/` | RSpec system specs + Capybara. Lower priority for an API-only app. |
| Frontend unit / component | Co-located `<name>.test.ts(x)` next to source | Vitest + happy-dom + `@testing-library/react` + `@testing-library/jest-dom` + `@testing-library/user-event`. |
| Frontend network mocking | `frontend/src/test/mocks/` | MSW (`handlers.ts`, `server.ts`). |
| Frontend E2E | `frontend/e2e/` | Playwright (Chromium default; Firefox + WebKit configured, opt-in). |
| Contract / API integration | TBD (likely Pact-style or a hand-written suite hitting a test-mode Rails server) | — |

## Running Tests

```sh
# Backend (RSpec)
just backend-test                  # bundle exec rspec

# Frontend Layer 1 (Vitest)
just frontend-test                 # deno task test:run
just frontend-test-coverage        # deno task test:coverage

# Frontend Layer 2 (Playwright)
just frontend-test-e2e-install     # one-time: install browsers (~100 MB)
just frontend-test-e2e             # deno task test:e2e (chromium)
```

Direct invocation also works (`cd backend && bundle exec rspec spec/path`, `cd frontend && deno task test`).

## Conventions

### Backend

- One spec file per class. Mirror `app/` structure under `spec/` (`app/models/user.rb` → `spec/models/user_spec.rb`).
- Prefer **request specs** over controller specs for API endpoints.
- Use **fixtures** (Rails default) for canonical seed data. Avoid `factory_bot` unless the team explicitly opts in via ADR.
- Background jobs: assert enqueue with `have_enqueued_job(SomeJob)` rather than asserting side effects.
- Idempotency: every job spec should run the job twice and assert the second run is a no-op.
- Migrations: don't write specs for them; rely on the schema diff in CI.
- Top of every spec: `require "rails_helper"`.

### Frontend

See `frontend/TESTING.md` for the full doctrine. Highlights:

- Co-locate Vitest specs as `<name>.test.ts(x)` next to source.
- Test behavior, not markup. Use accessibility-first locators (`getByRole`, `getByText`, `getByLabelText`). No snapshot tests.
- Mock network with **MSW** (`onUnhandledRequest: "error"`). Override per-test via `server.use(...)`. Never hand-roll `fetch` stubs in component tests.
- Coverage target ≥ 80 % on `src/` (excludes `src/test/`, `src/main.tsx`, `*.d.ts`).
- E2E: one happy-path per major user flow. Chromium default, Firefox/WebKit opt-in. CI only.

## CI Roadmap

Order of work to close the testing gap:

1. **Add a test workflow** — `.github/workflows/test.yml` running `bundle exec rspec`, `deno task test:run`, and `deno task test:e2e` on every PR. Cache Playwright browsers.
2. **Wire backend pre-commit** — `bin/rubocop` and `bin/brakeman` on staged Ruby files via `prek`.
3. **Wire frontend pre-commit** — `tsc --noEmit` and `vitest related --run` on staged TS files.
4. **First domain specs** — land alongside the first real domain model + controller (likely Identity bounded context).
5. **First domain component test** — quote-form `validateQuote()` once it's extracted from `App.tsx`.
6. **First real E2E journey** — quote form happy path (POST round-trip), once the backend `Api::QuoteRequestsController#create` exists.

## Known Gaps

- Only smoke specs exist on both sides — refactors of real code are unverified.
- `brakeman` and `bundler-audit` are installed (`backend/bin/`) but not run in CI.
- No backend coverage reporting. When real specs arrive, target ≥ 80 % for new model + controller code; don't backfill historical coverage.
- Playwright runs only on Chromium by default; cross-browser regressions are unknown until `deno task test:e2e:all` is run.

## Don't

- Don't add Minitest specs or use `bin/rails test`. RSpec is the exclusive backend framework.
- Don't pile heavy dependencies on top (`factory_bot` + `database_cleaner` + `shoulda-matchers` + …) before there's anything to test. Add deliberately if the bare RSpec defaults hurt.
- Don't mirror unit tests at the E2E layer — they're slow. E2E is for browser-real concerns (routing, real network, focus, CSS-driven behavior).
- Don't gate every PR on E2E from day one — start with unit + request specs. Layer Playwright in for explicit critical journeys only.
