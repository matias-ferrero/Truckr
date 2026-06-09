import { test, expect } from "@playwright/test";

// REQ-FE-00028 / US51 — Map + Google Maps deep-link on the shipment detail.
//
// Hermetic by design: we abort the Google Maps JS API script so the test never
// depends on a live API key or network. <ShipmentMap /> then degrades to its
// service-unavailable state, but the deep-link button renders and works
// regardless (AC9) — it's a plain anchor built from the cargo coordinates.
//
// Coordinates are NOT NULL on every Cargo (US48/US49), so a seeded shipment
// always yields the route button.

test.describe("Shipment detail — map & Google Maps route link (REQ-FE-00028 / US51)", () => {
    test.beforeEach(async ({ page }) => {
        // Keep the run offline from Google: the button doesn't need the JS API.
        await page.route("https://maps.googleapis.com/**", (route) => route.abort());

        await page.goto("/login");
        await page.fill("#email", "carrier1@truckr.test");
        await page.fill("#password", "Password123");
        await page.getByRole("button", { name: /ingresar|iniciar sesión/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible({ timeout: 10_000 });
    });

    test("golden path: detail shows the map section with a Google Maps route deep-link", async ({ page }) => {
        await page.goto("/carrier/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        const firstLink = page.getByRole("link", { name: /envío #\d+/i }).first();
        await expect(firstLink).toBeVisible();
        await firstLink.click();

        await expect(page).toHaveURL(/\/carrier\/shipments\/\d+$/);

        // The US39 anchor is preserved and now hosts the map section (AC7).
        const mapSection = page.locator("section#shipment-tracking-map");
        await expect(mapSection).toBeAttached();
        await expect(mapSection.getByRole("heading", { name: /mapa del recorrido/i })).toBeVisible();

        // Single route deep-link with both origin and destination (AC1/AC2).
        const routeLink = page.getByRole("link", { name: /ver ruta.*google maps/i });
        await expect(routeLink).toBeVisible();

        const coord = "-?\\d+(\\.\\d{1,6})?";
        const deepLinkRe = new RegExp(
            `^https://www\\.google\\.com/maps/dir/\\?api=1&origin=${coord},${coord}&destination=${coord},${coord}$`,
        );
        expect(await routeLink.getAttribute("href")).toMatch(deepLinkRe);

        // Opens in a new tab with a safe rel (AC2).
        await expect(routeLink).toHaveAttribute("target", "_blank");
        await expect(routeLink).toHaveAttribute("rel", "noopener noreferrer");
    });
});
