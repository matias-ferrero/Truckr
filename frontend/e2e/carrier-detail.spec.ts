import { expect, test } from "@playwright/test";

// E2E: navigate to a public carrier profile and see the hero + transport
// windows. The "Ofertar" CTA was removed from this page (plan §9 D8) —
// offers now start from "Mis cargas" → the cargo-scoped matches screen.
// The carrier-profile behaviour is covered by the Vitest suite meanwhile.
//
// Skipped until a real backend with seeded data is wired into the fixtures.
test.describe("Public — carrier detail (US6)", () => {
    test.skip(true, "needs a seeded carrier (id=1) on the local backend");

    test("navigate → carrier profile renders, with no offer CTA", async ({ page }) => {
        await page.goto("/carriers/1");

        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
        await expect(
            page.getByRole("heading", { name: /disponibilidad/i }),
        ).toBeVisible();
        // The offer CTA must not exist on the carrier profile anymore.
        await expect(page.getByTestId("offer-cta-top")).toHaveCount(0);
    });
});
