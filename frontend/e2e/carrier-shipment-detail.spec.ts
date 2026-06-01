import { test, expect } from "@playwright/test";

// REQ-FE-00024 / US39 — Shipment detail page, Carrier role.
//
// Uses the seeded carrier1@truckr.test account. Seeds create shipments in
// multiple states; in_transit sorts first (sort order weight 0), so the
// first row in the carrier list is reliably an in_transit shipment.

test.describe("Carrier — shipment detail (REQ-FE-00024 / US39)", () => {
    test.beforeEach(async ({ page }) => {
        await page.goto("/login");
        await page.fill("#email", "carrier1@truckr.test");
        await page.fill("#password", "Password123");
        await page.getByRole("button", { name: /ingresar|iniciar sesión/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();
    });

    test("golden path: navigates from list to detail and shows shipment data", async ({ page }) => {
        await page.goto("/carrier/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        const firstLink = page.getByRole("link", { name: /envío #\d+/i }).first();
        await expect(firstLink).toBeVisible();
        await firstLink.click();

        await expect(page).toHaveURL(/\/carrier\/shipments\/\d+$/);
        await expect(page.getByRole("heading", { name: /envío #\d+/i })).toBeVisible();

        // Back link points to carrier list
        const backLink = page.getByRole("link", { name: /volver a mis envíos/i });
        await expect(backLink).toBeVisible();
        await expect(backLink).toHaveAttribute("href", "/carrier/shipments");

        // Data grid fields
        await expect(page.getByText("Origen")).toBeVisible();
        await expect(page.getByText("Destino")).toBeVisible();

        // Map placeholder anchor is always present (AC5 — anchor for US51)
        await expect(page.locator("#shipment-tracking-map")).toBeAttached();
    });

    test("carrier on in_transit shipment: detail shows state chip and deliver button", async ({ page }) => {
        await page.goto("/carrier/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        // in_transit sorts first (weight 0 in shipmentStateSortOrder) — first link is in_transit
        const firstLink = page.getByRole("link", { name: /en tránsito/i }).first();
        await expect(firstLink).toBeVisible();
        await firstLink.click();

        await expect(page).toHaveURL(/\/carrier\/shipments\/\d+$/);
        // Use the state chip locator to avoid matching the timeline event label too.
        await expect(page.locator(".shipmentStateChip").getByText("En tránsito")).toBeVisible();
        // The detail page still exposes the carrier action for this state.
        await expect(page.getByRole("button", { name: /confirmar entrega/i })).toBeVisible();
    });

    test("404: non-existent shipment shows not-found screen with back CTA", async ({ page }) => {
        await page.goto("/carrier/shipments/99999");

        await expect(page.getByRole("heading", { name: /envío no encontrado/i })).toBeVisible();
        const cta = page.getByRole("link", { name: /volver al listado/i });
        await expect(cta).toBeVisible();
        await expect(cta).toHaveAttribute("href", "/carrier/shipments");
    });

    // Full golden path requires the seeded in_transit shipment to actually
    // transition — which consumes the seed. Skipped to avoid cross-test contamination.
    test.skip("golden path: Carrier start_transit → deliver → chip updates to Entregado", async ({ page }) => {
        await page.goto("/carrier/shipments");

        // Find accepted+escrowed shipment showing "Iniciar transporte"
        const acceptedLink = page.getByRole("link", { name: /aceptado/i }).first();
        await acceptedLink.click();

        await expect(page.getByRole("button", { name: /iniciar transporte/i })).toBeVisible();
        await page.getByRole("button", { name: /iniciar transporte/i }).click();

        const dialog = page.getByRole("dialog");
        await expect(dialog).toBeVisible();
        await dialog.getByRole("button", { name: /confirmar/i }).click();

        // Chip updates to in_transit
        await expect(page.getByText("En tránsito")).toBeVisible();
        await expect(page.getByRole("button", { name: /confirmar entrega/i })).toBeVisible();

        // Deliver
        await page.getByRole("button", { name: /confirmar entrega/i }).click();
        const dialog2 = page.getByRole("dialog");
        await expect(dialog2).toBeVisible();
        await dialog2.getByRole("button", { name: /confirmar/i }).click();

        await expect(page.getByText("Entregado")).toBeVisible();
        await expect(page.getByRole("button", { name: /iniciar|entregar|pagar/i })).not.toBeVisible();
    });
});
