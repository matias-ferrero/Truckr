# Frontend Testing — Modus Operandi

Two-layer strategy. Pick the right layer for the question you're answering.

## Layer 1 — Unit + Component (Vitest)

Fast feedback. Runs in `happy-dom`. No browser, no network.

| Concern | Tooling |
|---------|---------|
| Test runner | `vitest` |
| DOM | `happy-dom` |
| Component rendering | `@testing-library/react` |
| Custom matchers | `@testing-library/jest-dom` |
| User interaction | `@testing-library/user-event` |
| Network mocking | `msw` (handlers in `src/test/mocks/`) |
| Coverage | `@vitest/coverage-v8`, target ≥ 80% on `src/` (excludes `src/test/`, `src/main.tsx`, `*.d.ts`) |

**Location**: co-locate with source, `<name>.test.ts(x)`. Example: `src/App.test.tsx` next to `src/App.tsx`.

**Setup file**: `src/test/setup.ts` — registers `jest-dom` matchers, starts the MSW server, and resets handlers between tests.

**MSW**: default handlers live in `src/test/mocks/handlers.ts`; the Node-mode server is exposed from `src/test/mocks/server.ts`. Override per-test with `server.use(...)`. Unhandled requests are configured to **error** (`onUnhandledRequest: "error"`) to surface real network leaks.

**Commands**:
```sh
deno task test            # watch mode
deno task test:run        # single run
deno task test:coverage   # single run + v8 coverage report
just frontend-test        # alias for test:run
```

**Conventions**:
- Test behavior, not markup. Prefer `getByRole`, `getByText`, `getByLabelText` over class/test-id queries.
- Test type guards and pure utils first — they're the cheapest, most defensible boundary.
- For component behavior, simulate users via `@testing-library/user-event`, not raw `fireEvent`.
- One `describe` block per source file. One `it` per behavior.
- No snapshot tests.

## Layer 2 — End-to-End (Playwright)

Browser-real. Catches what unit/component tests can't: routing, real network, real CSS, real focus management.

| Concern | Tooling |
|---------|---------|
| Test runner | `@playwright/test` |
| Default browser | Chromium |
| Opt-in browsers | Firefox, WebKit (configured in `projects:`, run via `deno task test:e2e:all` or `--project=firefox`) |
| Web server | `vite preview` on port `4173`, started by Playwright before the run, reused locally |

**Location**: `frontend/e2e/*.spec.ts`. Example: `frontend/e2e/smoke.spec.ts`.

**Config**: `frontend/playwright.config.ts`. The `webServer` block runs `deno task build && deno task preview --port 4173`. In CI: retries=2, workers=1, `forbidOnly`. Locally: no retries, parallel, server reused if already running.

**First-time setup** (downloads ~100 MB):
```sh
deno task test:e2e:install   # installs system deps + browsers
# or:
deno run -A npm:playwright install chromium   # chromium-only
```

**Commands**:
```sh
deno task test:e2e             # chromium only (default)
deno task test:e2e:all         # all configured browsers
just frontend-test-e2e         # alias
```

**Scope**:
- Start small. One smoke test per major surface ("homepage loads", "sign-up form submits", "shipment timeline renders").
- Add real user journeys as features land. **Do not** mirror unit tests at the E2E layer.
- No exhaustive Playwright suites. The E2E layer is the slowest layer; treat its time budget as scarce.

**Conventions**:
- Use `baseURL` and relative paths (`page.goto("/")`) — never hardcode `http://localhost:...`.
- Prefer Playwright's `getByRole` / `getByText` accessibility-first locators.
- Trace on first retry (`trace: "on-first-retry"`). Open the HTML report with `npx playwright show-report` after a failure.

## When to Reach for Which Layer

| Question | Layer |
|----------|-------|
| Does this pure function compute the right thing? | Vitest unit |
| Does this component render the right text/buttons given props? | Vitest + RTL |
| Does this user interaction update the UI correctly? | Vitest + RTL + user-event |
| Does the API request get sent with the right shape? | Vitest + MSW |
| Does the deployed bundle work end-to-end in a real browser? | Playwright |
| Does the routing / focus / CSS-driven behavior work? | Playwright |

## Don'ts

- Don't mock network calls inside component tests with hand-rolled `fetch` stubs — use MSW handlers, even for one-off cases (use `server.use(...)`).
- Don't add `factory_bot`-style data builders before there are 3+ specs that need them.
- Don't run E2E in pre-commit. CI only.
- Don't gate PRs on cross-browser E2E (Firefox/WebKit) — run on chromium by default; cross-browser is opt-in.
- Don't write tests against implementation details (component state, internal hooks). Test what the user sees.

## File Layout (Reference)

```
frontend/
├── src/
│   ├── App.tsx
│   ├── App.test.tsx              # co-located component test
│   └── test/
│       ├── setup.ts              # vitest setupFiles entry
│       └── mocks/
│           ├── handlers.ts       # MSW request handlers
│           └── server.ts         # MSW Node server
├── e2e/
│   └── smoke.spec.ts             # Playwright specs
├── vitest.config.ts
├── playwright.config.ts
└── deno.json                     # tasks: test, test:run, test:coverage, test:e2e, test:e2e:install
```
