# Testing Strategy

## Current State

- **Backend**: RSpec (`rspec-rails ~> 7.1`) wired (`backend/spec/`, `.rspec`, `spec_helper.rb`, `rails_helper.rb`). 1 smoke spec (`spec/smoke_spec.rb`); 0 model/controller/job specs.
- **Frontend**: Two-layer testing wired (Vitest + Playwright). One component spec (`src/App.test.tsx`) and one E2E smoke (`e2e/smoke.spec.ts`).
- **CI**: `release-please.yml` (releases), `pr-title.yml` (conventional-commit lint), `backend-ci.yml` (brakeman + bundler-audit + importmap audit + rubocop + rspec + rswag), `frontend-ci.yml` (vitest --coverage + vite build + Playwright chromium). Backend/frontend workflows filtered by `paths:` so docs-only PRs don't fan out.
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

1. ~~**Add a test workflow**~~ — Done. Two workflows at the repo root with `paths:` filters:
   - `.github/workflows/backend-ci.yml` — `scan_ruby` (brakeman), `scan_js` (importmap audit + bundler-audit), `lint` (rubocop), `test` (rspec + rswag swagger-diff). Triggers on `backend/**`.
   - `.github/workflows/frontend-ci.yml` — `unit` (vitest --coverage), `build` (vite), `e2e` (Playwright Chromium). Triggers on `frontend/**`. Toolchain via `jdx/mise-action@v2`; Playwright browsers + Deno + node_modules cached.
2. **Wire backend pre-commit** — `bin/rubocop` and `bin/brakeman` on staged Ruby files via `prek`.
3. **Wire frontend pre-commit** — `tsc --noEmit` and `vitest related --run` on staged TS files.
4. **First domain specs** — land alongside the first real domain model + controller (likely Identity bounded context).
5. **First domain component test** — quote-form `validateQuote()` once it's extracted from `App.tsx`.
6. **First real E2E journey** — quote form happy path (POST round-trip), once the backend `Api::QuoteRequestsController#create` exists.

## Manual Full-Stack Smoke Test

Use this when automated tests aren't enough — new E2E specs are skipped pending fixtures, or you need to verify the real browser + real API together.

### 1. Start the stack

```sh
# Terminal 1 — backend API (http://localhost:3000)
just backend-dev

# Terminal 2 — frontend dev server (http://localhost:5173)
just frontend-dev
```

### 2. Seed the database

Idempotent — safe to re-run against an existing database.

```sh
cd backend && bin/rails db:seed
```

Key fixtures created:

| Resource | Credentials / Value |
|---|---|
| Shipper | `shipper1@truckr.test` / `Password123` |
| Carrier | `carrier1@truckr.test` / `Password123` |
| Vehicle | Mercedes-Benz Sprinter, max 5 000 kg, no volume limit |
| Transport Window 1 | Buenos Aires → Córdoba, ARS 1 500/km, active for ~10 days from seed time |
| Transport Window 2 | Rosario → Mendoza, ARS 1 700/km, active 11–18 days from seed time |

> Window dates are relative to when the seed was last run. Pickup dates must fall within the window's `available_from..available_to` range.

### 3. Offer-creation flow (US7 — REQ-FE-00015)

1. Log in as `shipper1@truckr.test` at `http://localhost:5173`.
2. Go to `http://localhost:5173/carriers/1` → click **Ofertar** on the Buenos Aires → Córdoba window.
3. **Step 1 — Addresses**: fill origin (Av. Corrientes 1234, C1043, CABA, Ciudad Autónoma de Buenos Aires) and destination (Av. Colón 500, X5000, Córdoba, Córdoba). Click **Siguiente**.
4. **Step 2 — Cargo**: description = "Pallets de electrodomésticos", weight = 1 500 kg (limit hint: 5 000 kg), volume = 3 000 000 cm³ (no-limit hint), declared value = 50 000. Try 6 000 kg to verify the capacity error blocks advancement. Click **Siguiente**.
5. **Step 3 — Date + Budget**: pick a date within Window 1's range, enter 700 km. Verify the cost estimate shows ~ARS 1 050 000 (700 × 1 500). Click **Enviar oferta**.
6. Confirm the `data-testid="confirmation-screen"` panel appears with a `Referencia de oferta: #N` chip.
7. Navigate to `/` (dashboard) — the **Mis ofertas** section should show the new quote with a "Pendiente" badge, the route, pickup date, and ARS amount.

### 4. API-level smoke (optional)

```sh
# Authenticate as shipper
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"shipper1@truckr.test","password":"Password123"}}' \
  | jq -r '.token')

# Create a quote (adjust pickup_date to a date within 10 days from now)
curl -s -X POST http://localhost:3000/api/quotes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "quote": {
      "transport_window_id": 1,
      "pickup_address": "Av. Corrientes 1234, C1043 CABA, Ciudad Autónoma de Buenos Aires",
      "delivery_address": "Av. Colón 500, X5000 Córdoba, Córdoba",
      "pickup_date": "'"$(date -d '+3 days' +%Y-%m-%d 2>/dev/null || date -v+3d +%Y-%m-%d)"'",
      "cargo_description": "Pallets de electrodomésticos",
      "weight_kg": "1500",
      "volume_cm3": "3000000",
      "declared_value_cents": "5000000",
      "estimated_km": "700"
    }
  }' | jq .

# List the shipper's quotes
curl -s http://localhost:3000/api/quotes \
  -H "Authorization: Bearer $TOKEN" | jq '.[] | {id, status, amount_cents}'
```

Expected: `POST` returns the created quote with `"status": "pending"` and `"amount_cents": 105000000`.

### 5. Un-skip the E2E spec

`frontend/e2e/carrier-offer.spec.ts` is skipped pending seeded fixtures. To run it:

1. Run the seed (step 2 above).
2. Remove the `test.skip(true, …)` line.
3. Update the hardcoded `pickup_date` to a date within Window 1's current range.
4. Run `just frontend-test-e2e`.

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
