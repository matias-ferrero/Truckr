import { test, expect } from "@playwright/test";

test.describe("Carrier — shipment list (REQ-FE-00022)", () => {
    test("authenticated carrier sees the empty state when no shipments exist", async ({ page }) => {
        const email = `carrier-shipments-${Date.now()}@example.com`;
        const password = "Password1";

        await page.goto("/signup");
        await page.fill("#name", "Carrier E2E");
        await page.fill("#email", email);
        await page.fill("#password", password);
        await page.fill("#passwordConfirm", password);
        await page.check("#role-carrier");
        await page.getByRole("button", { name: /^crear cuenta$/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        await page.goto("/carrier/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();
        await expect(page.getByText("Aún no realizaste envíos")).toBeVisible();
    });

    test("non-carrier is redirected away from /carrier/shipments", async ({ page }) => {
        const email = `shipper-shipments-guard-${Date.now()}@example.com`;
        const password = "Password1";

        await page.goto("/signup");
        await page.fill("#name", "Shipper E2E");
        await page.fill("#email", email);
        await page.fill("#password", password);
        await page.fill("#passwordConfirm", password);
        await page.check("#role-shipper");
        await page.getByRole("button", { name: /^crear cuenta$/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        await page.goto("/carrier/shipments");
        // RequireCarrier redirects non-carriers to /
        await expect(page).not.toHaveURL(/\/carrier\/shipments/);
    });

    // Requires seeded shipments in the test database.
    test.skip("golden path: carrier with shipments sees list and navigates to detail", async ({ page }) => {
        await page.goto("/carrier/shipments");
        await expect(page.getByRole("list", { name: "Lista de envíos" })).toBeVisible();
        const firstLink = page.getByRole("link").first();
        await firstLink.click();
        await expect(page).toHaveURL(/\/carrier\/shipments\/\d+/);
    });
});
