import { expect, test } from "@playwright/test";

// E2E: navigate to a carrier detail page, see the hero + estimate, click the
// CTA, land on /carriers/:id/ofertar (US7 page — not yet implemented, so the
// app's wildcard route catches it and renders the landing). This test asserts
// only the parts of the journey covered by US6.
//
// Skipped until a real backend with seeded data is wired into the playwright
// fixtures. The behaviour is exercised by the Vitest test suite in the meantime.
test.describe("Public — carrier detail (US6)", () => {
    test.skip(true, "needs a seeded carrier (id=1) on the local backend");

    test("navigate → detail → CTA dispatches to /ofertar", async ({ page }) => {
        await page.goto("/carriers/1?origin=Buenos%20Aires&destination=Rosario&weight_kg=2000&volume_cm3=6000000");

        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
        await expect(page.getByText(/costo estimado/i)).toBeVisible();
        await expect(page.getByText(/galería de la flota/i)).toBeVisible();

        await page.getByTestId("offer-cta-top").click();
        await expect(page).toHaveURL(/\/carriers\/1\/ofertar/);
    });
});
