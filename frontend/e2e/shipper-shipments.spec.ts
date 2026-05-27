import { test, expect } from "@playwright/test";

test.describe("Shipper — shipment list (REQ-FE-00023)", () => {
    test("authenticated shipper sees the empty state when no shipments exist", async ({ page }) => {
        const email = `shipper-ship-${Date.now()}@example.com`;
        const password = "Password1";

        await page.goto("/signup");
        await page.fill("#name", "Shipper E2E");
        await page.fill("#email", email);
        await page.fill("#password", password);
        await page.fill("#passwordConfirm", password);
        await page.check("#role-shipper");
        await page.getByRole("button", { name: /^crear cuenta$/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        await page.goto("/shipper/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();
        await expect(page.getByText("Aún no contrataste envíos")).toBeVisible();
    });

    test("non-shipper sees Forbidden page at /shipper/shipments", async ({ page }) => {
        const email = `carrier-ship-guard-${Date.now()}@example.com`;
        const password = "Password1";

        await page.goto("/signup");
        await page.fill("#name", "Carrier E2E");
        await page.fill("#email", email);
        await page.fill("#password", password);
        await page.fill("#passwordConfirm", password);
        await page.check("#role-carrier");
        await page.getByRole("button", { name: /^crear cuenta$/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        await page.goto("/shipper/shipments");
        // RequireShipper shows a Forbidden (403) page for non-shippers
        await expect(page.getByText("403")).toBeVisible();
    });

    // Requires seeded shipments in the test database.
    test.skip("golden path: shipper with shipments sees list and navigates to detail", async ({ page }) => {
        await page.goto("/shipper/shipments");
        await expect(page.getByRole("list", { name: "Lista de envíos" })).toBeVisible();
        const firstLink = page.getByRole("link").first();
        await firstLink.click();
        await expect(page).toHaveURL(/\/shipper\/shipments\/\d+/);
    });
});
