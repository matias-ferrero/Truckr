import { test, expect, type Page } from "@playwright/test";

const carrierEmail = "operaciones@andinacargo.test";
const carrierPassword = "Password123";

async function loginAsCarrier(page: Page) {
    await page.goto("/login");
    await page.getByLabel(/email/i).fill(carrierEmail);
    await page.getByLabel(/contraseña/i).fill(carrierPassword);
    await page.getByRole("button", { name: /iniciar sesión/i }).click();
    await page.waitForURL("/");
}

// Happy path: a carrier registers a vehicle, sees it in the fleet, gives it
// a soft-delete, and confirms the row disappears. The seeded carrier already
// has one historical vehicle, which we keep for the blocked-path case.
test.describe("Carrier — vehicle CRUD (REQ-BE-00009 + REQ-BE-00010)", () => {
    test("create → list → discard", async ({ page }) => {
        await loginAsCarrier(page);
        await page.goto("/carrier/vehicle/new");

        await page.getByLabel(/marca/i).fill("Mercedes-Benz");
        await page.getByLabel(/modelo/i).fill("Sprinter");
        await page.getByLabel(/patente/i).fill("AZ999ZA");
        await page.getByLabel(/año/i).fill("2024");
        await page.getByLabel(/capacidad de carga/i).fill("3500");
        await page.getByRole("button", { name: /agregar vehículo/i }).click();

        await expect(page).toHaveURL(/\/carrier\/vehicles$/);
        const createdCard = page.locator("li.vehicleCard", { hasText: "AZ999ZA" });
        await expect(createdCard).toBeVisible();

        await createdCard.getByRole("button", { name: /dar de baja/i }).click();
        await expect(page.getByRole("dialog")).toBeVisible();
        await page.getByRole("dialog").getByRole("button", { name: /^dar de baja$/i }).click();

        await expect(page.getByRole("status")).toContainText(/vehículo dado de baja/i);
        await expect(page.getByText("AZ999ZA")).toHaveCount(0);
    });

    test("blocks discard when the vehicle still has active windows", async ({ page }) => {
        await loginAsCarrier(page);
        await page.goto("/carrier/vehicles");

        const blockedCard = page.locator("li.vehicleCard", { hasText: "AD789GH" });
        await expect(blockedCard).toBeVisible();

        await blockedCard.getByRole("button", { name: /dar de baja/i }).click();
        await page.getByRole("dialog").getByRole("button", { name: /^dar de baja$/i }).click();

        await expect(page.getByRole("alert")).toContainText(/ventanas de transporte activas/i);
        await expect(page.getByRole("link", { name: /ir a mis ventanas/i })).toHaveAttribute("href", "/carrier/availability");
    });
});
