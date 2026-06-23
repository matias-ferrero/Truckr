import { test, expect } from "@playwright/test";

test("the persistent sidebar is shown and navigates the carrier between sections", async ({ page }) => {
    // Login as the seeded carrier.
    await page.goto("/login");
    await page.fill("#email", "operaciones@andinacargo.test");
    await page.fill("#password", "Password123");
    await page.getByRole("button", { name: /iniciar sesión/i }).click();
    await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

    const sidebar = page.getByRole("navigation", { name: "Navegación principal" });

    // Sidebar is present on a carrier page...
    await page.goto("/carrier/availability");
    await expect(sidebar).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Vehículos" })).toBeVisible();

    // "Ofertas" moved into the sidebar; the header no longer carries "Bandeja".
    await expect(sidebar.getByRole("link", { name: /ofertas/i })).toBeVisible();
    await expect(page.getByRole("banner").getByRole("link", { name: /bandeja/i }))
        .toHaveCount(0);

    // ...and golden path: clicking a sidebar item navigates to that section.
    await sidebar.getByRole("link", { name: "Mis Pagos" }).click();
    await expect(page).toHaveURL(/\/carrier\/payouts/);
    await expect(page.getByRole("heading", { name: "Mis Pagos" })).toBeVisible();
    // Active route is marked for assistive tech.
    await expect(sidebar.getByRole("link", { name: "Mis Pagos" }))
        .toHaveAttribute("aria-current", "page");

    // Still present after navigation (shown on every page).
    await sidebar.getByRole("link", { name: "Vehículos" }).click();
    await expect(page).toHaveURL(/\/carrier\/vehicles/);
    await expect(sidebar).toBeVisible();
});
