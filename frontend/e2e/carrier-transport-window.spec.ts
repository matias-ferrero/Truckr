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

    test("create open-destination window (blank destination) shows Destino abierto in list", async ({ page }) => {
        await page.goto("/carrier/availability/new");
        // Leave destination fields blank — they are optional
        await page.getByLabel(/provincia de origen/i).fill("Buenos Aires");
        // destination_province intentionally left empty (open destination)
        await page.getByLabel(/precio por km/i).fill("1500");
        await page.getByLabel(/kilómetros máximos/i).fill("1200");
        await page.getByLabel(/disponible desde/i).fill("2026-07-01");
        await page.getByLabel(/disponible hasta/i).fill("2026-07-31");
        await page.getByRole("button", { name: /publicar disponibilidad/i }).click();

        await expect(page.getByText(/Buenos Aires → Destino abierto/i)).toBeVisible();
    });

    // Skipped until REQ-FE-00006 (public carrier search) lands.
    test("active window appears in public search, inactive does not", async ({ page }) => {
        void page; // depends on REQ-FE-00006 public search route
    });
});
