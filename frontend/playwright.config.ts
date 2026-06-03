import { defineConfig, devices } from "@playwright/test";

const PORT = 4173;
const BASE_URL = `http://localhost:${PORT}`;
const isCI = !!process.env.CI;

export default defineConfig({
    testDir: "./e2e",
    fullyParallel: true,
    forbidOnly: isCI,
    retries: isCI ? 2 : 0,
    workers: isCI ? 1 : undefined,
    reporter: [["list"], ["html", { open: "never" }]],
    use: {
        baseURL: BASE_URL,
        trace: "on-first-retry",
    },
    projects: [
        {
            name: "chromium",
            use: { ...devices["Desktop Chrome"] },
        },
        {
            name: "firefox",
            use: { ...devices["Desktop Firefox"] },
            // opt-in: deno task test:e2e --project=firefox
        },
        {
            name: "webkit",
            use: { ...devices["Desktop Safari"] },
            // opt-in: deno task test:e2e --project=webkit
        },
    ],
    webServer: [
        {
            command: `deno task build && deno task preview --port ${PORT}`,
            url: BASE_URL,
            reuseExistingServer: !isCI,
            timeout: 120_000,
        },
        {
            command:
                "cd ../backend && bundle exec rails db:test:prepare && bundle exec rails db:seed && bundle exec rails server -e test -p 3000",
            url: "http://localhost:3000/up",
            reuseExistingServer: !isCI,
            timeout: 180_000,
            // `async` so Action Cable actually delivers broadcasts over the live
            // socket (the default `test` adapter only captures them in-memory
            // for RSpec). See backend/config/cable.yml (INF-FE-00005).
            env: { RAILS_ENV: "test", ACTION_CABLE_ADAPTER: "async" },
        },
    ],
});
