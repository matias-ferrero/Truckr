import { test, expect } from "@playwright/test";

test("carrier can view their payouts history", async ({ page }) => {
    // Login as the seeded carrier
    await page.goto("/login");
    await page.fill("#email", "carrier1@truckr.test");
    await page.fill("#password", "Password123");
    await page.getByRole("button", { name: /iniciar sesión/i }).click();
    await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

    // The carrier lands on the v2 dashboard; "Mis Pagos" lives in the
    // persistent sidebar (the header link was consolidated away).
    await page.goto("/carrier/dashboard");
    await page.getByRole("navigation", { name: "Navegación principal" })
        .getByRole("link", { name: "Mis Pagos" }).click();

    // Verify URL and title
    await expect(page).toHaveURL(/\/carrier\/payouts/);
    await expect(page.getByRole("heading", { name: "Mis Pagos" })).toBeVisible();

    // Since this is a test environment, the table or empty state might show depending on the DB seeding.
    // We check that the page loaded correctly without crashing.
    await expect(page.getByRole("main")).toBeVisible();
});
