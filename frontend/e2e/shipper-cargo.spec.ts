import { test, expect } from "@playwright/test";

// REQ-BE-00032 (US27) — cargo-first offer funnel golden path (plan §9):
//   Dashboard "Mis cargas" → publish/select a cargo → cargo-scoped
//   transport-window search (/matches) → pick a window → offer.
//
// Requires real seeded fixtures the standalone FE env does not provide:
//   1. An authenticated Shipper (login via /api/auth/login).
//   2. A seeded Carrier with at least one active TransportWindow whose zones
//      + dates + vehicle capacity match the cargo published below, so the
//      matches screen shows at least one result.
//
// Per plan §5, ship with `test.skip` until db/seeds.rb provides those
// fixtures. Un-skip once the backend half is deployed with seeds.
test.describe("Shipper — cargo-first offer funnel (REQ-BE-00032 / US27)", () => {
    test.skip(
        true,
        "needs a seeded shipper + a zone/date/capacity-compatible active transport window",
    );

    test("dashboard → publish cargo → matches → offer → offer appears", async ({ page }) => {
        // 1. Login as a seeded Shipper.
        await page.goto("/login");
        await page.fill('[name="email"]', "shipper@truckr.test");
        await page.fill('[name="password"]', "Password123");
        await page.click('button[type="submit"]');
        await page.waitForURL("/");

        // 2. The dashboard leads with the "Mis cargas" section.
        await expect(
            page.getByRole("heading", { name: "Mis cargas" }),
        ).toBeVisible();

        // 3. Publish a cargo.
        await page.goto("/shipper/cargos/new");
        await page.fill("#cargo_description", "Pallets de electrodomésticos");
        await page.fill("#weight_kg", "1500");
        await page.fill("#declared_value_cents", "5000000");
        await page.fill("#pickup_address", "Av. Corrientes 1234, CABA");
        await page.fill("#delivery_address", "Av. Colón 500, Córdoba");
        await page.selectOption("#pickup_zone", "Buenos Aires");
        await page.selectOption("#delivery_zone", "Córdoba");
        await page.fill("#pickup_window_start", "2026-06-01T08:00");
        await page.fill("#pickup_window_end", "2026-06-03T18:00");
        await page.click('button:has-text("Publicar carga")');

        // 4. Land on the cargo detail; open the transport-window search.
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+$/);
        await page.getByRole("link", { name: "Buscar transportistas" }).click();
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+\/matches$/);

        // 5. The matches screen pins the selected cargo; pick a result —
        //    the whole match card links straight to the offer screen.
        await expect(
            page.getByRole("heading", { name: "Transportistas disponibles" }),
        ).toBeVisible();
        await page
            .getByRole("link", { name: /Ofertar para el tramo/ })
            .first()
            .click();

        // 6. Offer against the matched window.
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+\/offers\/new/);
        await page.fill("#estimated_km", "700");
        await page.click('button:has-text("Enviar oferta")');

        // 7. Back on the detail, the offer shows under "Mis ofertas".
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+$/);
        await expect(
            page.getByRole("heading", { name: "Mis ofertas" }),
        ).toBeVisible();
        await expect(page.getByText("Pendiente")).toBeVisible();
    });
});
