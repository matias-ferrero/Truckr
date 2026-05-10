import { test, expect } from "@playwright/test";

// Happy path: a carrier registers a vehicle, sees it in the fleet, deletes
// it, and lands on the empty state. Wire a real login fixture before
// unblocking — until then the auth gate redirects to /login.
test.describe("Carrier — vehicle CRUD (REQ-BE-00009 + REQ-BE-00010)", () => {
    test.skip(true, "needs an authenticated-carrier fixture (login via /api/auth/login)");

    test("create → list → delete", async ({ page }) => {
        await page.goto("/carrier/vehicle/new");

        await page.getByLabel(/marca/i).fill("Mercedes-Benz");
        await page.getByLabel(/modelo/i).fill("Sprinter");
        await page.getByLabel(/patente/i).fill("AB123CD");
        await page.getByLabel(/capacidad de carga/i).fill("3500");
        await page.getByRole("button", { name: /registrar vehículo/i }).click();

        await expect(page).toHaveURL(/\/carrier\/vehicles$/);
        await expect(page.getByText(/AB123CD/)).toBeVisible();

        page.on("dialog", (d) => d.accept());
        await page.getByRole("button", { name: /eliminar/i }).click();
        await expect(page.getByText(/todavía no registraste/i)).toBeVisible();
    });
});
