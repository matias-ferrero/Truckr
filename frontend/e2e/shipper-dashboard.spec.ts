import { expect, test } from "@playwright/test";

/**
 * Shipper Dashboard v2 — golden path on a freshly-registered account.
 *
 * A brand-new Shipper has no cargos and no shipments, so the dashboard renders
 * the onboarding empty state. This path is deterministic without any seeded
 * board data: register → land on the dashboard → publish-carga CTA → cargo form.
 * It also proves a shipper's index route ("/") redirects to the v2 dashboard.
 *
 * Backend test server is auto-booted by playwright.config.ts.
 */
test("fresh shipper: dashboard greeting + onboarding CTA → cargo creation form", async ({ page }) => {
    const email = `pw-dash-${Date.now()}@example.com`;
    const password = "Password1";

    // 1. Register a fresh Shipper.
    await page.goto("/signup");
    await page.fill("#name", "Panel Tester");
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.fill("#passwordConfirm", password);
    await page.check("#role-shipper");
    await page.getByRole("button", { name: /^crear cuenta$/i }).click();
    // SessionWidget's "Salir" button is the authenticated-state signal.
    await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

    // 2. Go to the dashboard; the greeting heading welcomes the shipper by name.
    await page.goto("/shipper/dashboard");
    await expect(
        page.getByRole("heading", { name: /Hola, Panel/ }),
    ).toBeVisible();

    // 3. A brand-new account is empty → the "Publicar carga" CTA is visible.
    const publishCta = page.getByRole("link", { name: "Publicar carga" }).first();
    await expect(publishCta).toBeVisible();

    // 4. Clicking it lands on the cargo creation form.
    await publishCta.click();
    await expect(page).toHaveURL(/\/shipper\/cargos\/new$/);
    await expect(page.locator("#cargo_description")).toBeVisible();
});

test("shipper index route '/' redirects to the v2 dashboard", async ({ page }) => {
    const email = `pw-nav-${Date.now()}@example.com`;
    const password = "Password1";

    await page.goto("/signup");
    await page.fill("#name", "Nav Tester");
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.fill("#passwordConfirm", password);
    await page.check("#role-shipper");
    await page.getByRole("button", { name: /^crear cuenta$/i }).click();
    await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

    // The shipper's home is the Cargo-centric dashboard: visiting "/" (e.g. via
    // the Truckr brand link) redirects there instead of the legacy dashboard.
    await page.goto("/");
    await expect(page).toHaveURL(/\/shipper\/dashboard$/);
    await expect(
        page.getByRole("heading", { name: /Hola, Nav/ }),
    ).toBeVisible();
});
