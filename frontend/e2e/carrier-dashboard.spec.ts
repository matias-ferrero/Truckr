import { expect, test } from "@playwright/test";

/**
 * Carrier Dashboard v2 — golden path on a freshly-registered account.
 *
 * A brand-new Carrier has no vehicle, no windows, no offers and no shipments,
 * so the dashboard renders the first rung of the onboarding ladder. This path
 * is deterministic without seeded board data: register → land on the
 * dashboard → "agregá tu primer vehículo" CTA → vehicle form. It also proves
 * a carrier's index route ("/") redirects to the v2 dashboard (retiring the
 * old multi-section landing).
 *
 * Backend test server is auto-booted by playwright.config.ts.
 */
test("fresh carrier: greeting + onboarding ladder CTA → vehicle form", async ({ page }) => {
    const email = `pw-cdash-${Date.now()}@example.com`;
    const password = "Password1";

    // 1. Register a fresh Carrier.
    await page.goto("/signup");
    await page.fill("#name", "Flota Tester");
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.fill("#passwordConfirm", password);
    await page.check("#role-carrier");
    await page.getByRole("button", { name: /^crear cuenta$/i }).click();
    // SessionWidget's "Salir" button is the authenticated-state signal.
    await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

    // 2. Go to the dashboard; the greeting heading welcomes the carrier by name.
    await page.goto("/carrier/dashboard");
    await expect(
        page.getByRole("heading", { name: /Hola, Flota/ }),
    ).toBeVisible();

    // 3. No vehicle yet → the first onboarding rung is shown, with the
    //    progressive CTA pointing at the vehicle form.
    await expect(
        page.getByRole("heading", { name: /sumá tu primer vehículo/i }),
    ).toBeVisible();
    const vehicleCta = page
        .getByRole("link", { name: /agregá tu primer vehículo/i })
        .first();
    await expect(vehicleCta).toBeVisible();

    // 4. The quiet stats strip reflects the empty supply posture.
    await expect(page.getByRole("link", { name: /0 vehículos/i })).toBeVisible();

    // 5. Clicking the CTA lands on the vehicle creation form.
    await vehicleCta.click();
    await expect(page).toHaveURL(/\/carrier\/vehicle\/new$/);
});

test("carrier index route '/' redirects to the v2 dashboard", async ({ page }) => {
    const email = `pw-cnav-${Date.now()}@example.com`;
    const password = "Password1";

    await page.goto("/signup");
    await page.fill("#name", "Ruta Tester");
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.fill("#passwordConfirm", password);
    await page.check("#role-carrier");
    await page.getByRole("button", { name: /^crear cuenta$/i }).click();
    await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

    // The carrier's home is the job-funnel dashboard: visiting "/" (e.g. via
    // the Truckr brand link) redirects there instead of the legacy dashboard.
    await page.goto("/");
    await expect(page).toHaveURL(/\/carrier\/dashboard$/);
    await expect(
        page.getByRole("heading", { name: /Hola, Ruta/ }),
    ).toBeVisible();
});
