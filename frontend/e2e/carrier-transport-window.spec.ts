import { test, expect } from "@playwright/test";

// REQ-FE-00016 (US9) — requires an authenticated carrier session.
// Wire a real login fixture before unblocking — until then the auth gate
// redirects to /login and the heading never appears.
test.describe("Carrier — transport window CRUD (REQ-FE-00016)", () => {
    test.skip(true, "needs an authenticated-carrier fixture (login via /api/auth/login)");

    test("create, list, and deactivate a transport window", async ({ page }) => {
        await page.goto("/carrier/availability");
        await expect(page.getByRole("heading", { name: /disponibilidad/i })).toBeVisible();
    });

    // Skipped until REQ-FE-00006 (public carrier search) lands.
    test("active window appears in public search, inactive does not", async ({ page }) => {
        void page; // depends on REQ-FE-00006 public search route
    });
});
