import { test, expect } from "@playwright/test";

// REQ-BE-00032 (US27) — cargo-first offer funnel golden path (plan §9):
//   Dashboard "Mis cargas" → publish/select a cargo → cargo-scoped
//   transport-window search (/matches) → pick a window → offer.
//
// Requires real seeded fixtures the standalone FE env does not provide:
//   1. An authenticated Shipper (login via /api/auth/login).
//   2. A seeded Carrier with at least one active TransportWindow whose
//      origin/destination pins + radii + dates + vehicle capacity match the
//      cargo published below, so the matches screen shows at least one result.
//
// db/seeds.rb now provides the shipper + compatible-window fixtures, so the
// matches-screen test below runs against them. Only the publish-flow test
// stays skipped: its AddressPicker step needs a Places stub to capture
// lat/lng, which the standalone FE env still does not provide.
test.describe("Shipper — cargo-first offer funnel (REQ-BE-00032 / US27)", () => {
    test("dashboard → publish cargo → matches → offer → offer appears", async ({ page }) => {
        test.skip(
            true,
            "the AddressPicker publish step needs a Places stub to capture lat/lng",
        );
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
        // Address-driven matching (REQ-BE-00039): the form now exposes a
        // single AddressPicker per side that captures address + lat/lng +
        // locality + admin_area. The seeded fixture should fill those via
        // the picker once the auth/Places stubs land.
        await page.getByLabel(/dirección de retiro/i).fill("Av. Corrientes 1234, CABA");
        await page.getByLabel(/dirección de entrega/i).fill("Av. Colón 500, Córdoba");
        await page.fill("#pickup_window_start", "2026-06-01T08:00");
        await page.fill("#pickup_window_end", "2026-06-03T18:00");
        await page.click('button:has-text("Publicar carga")');

        // 4. Land on the cargo detail; open the transport-window search.
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+$/);
        await page.getByRole("link", { name: "Buscar transportistas" }).click();
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+\/matches$/);

        // 5. The matches screen (Cargo Matches v2) pins the cargo context bar
        //    and renders the comparison grid with its sort/filter controls;
        //    the card's primary CTA links straight to the offer screen.
        await expect(
            page.getByRole("heading", { name: "Transportistas disponibles" }),
        ).toBeVisible();
        await expect(page.getByText("Tu carga", { exact: true })).toBeVisible();
        await expect(page.getByLabel("Ordenar por")).toBeVisible();
        await page
            .getByRole("link", { name: /Enviar oferta a/ })
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

    // REQ-FE-00029 — from the matches screen, "Ver perfil" opens the carrier
    // profile; a Shipper who arrived this way gets a "Volver a la búsqueda"
    // link back to the same cargo's matches screen.
    //
    // Uses the seeded Shipper (shipper1@truckr.test) and the cargo db/seeds.rb
    // designates as the matches demo: "Pallets de granos (demo matching)"
    // (CABA → Córdoba, cargo1), which matches the still-free tw1 so the
    // matches screen shows at least one result with a "Ver perfil" link.
    test("matches → Ver perfil → Volver a la búsqueda returns to matches", async ({ page }) => {
        // 1. Login as the seeded Shipper.
        await page.goto("/login");
        await page.fill("#email", "shipper1@truckr.test");
        await page.fill("#password", "Password123");
        await page.click('button[type="submit"]');
        await page.waitForURL("/");

        // 2. Open cargo2's detail from the list, then its matches screen. The
        //    "Buscar transportistas" CTA lives on the detail, not the list row.
        await page.goto("/shipper/cargos");
        await page
            .locator("li", { hasText: "Pallets de granos" })
            .getByRole("link", { name: /ver detalle/i })
            .click();
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+$/);
        await page.getByRole("link", { name: /buscar transportistas/i }).first()
            .click();
        await expect(page).toHaveURL(/\/shipper\/cargos\/\d+\/matches$/);
        const matchesUrl = page.url();

        // 3. Cargo Matches v2: the sticky cargo context bar and the
        //    sort/filter controls render above the comparison grid, and each
        //    card's primary CTA targets the offer flow.
        await expect(page.getByText("Tu carga", { exact: true })).toBeVisible();
        await expect(page.getByLabel("Ordenar por")).toBeVisible();
        await expect(
            page.getByRole("link", { name: /Enviar oferta a/ }).first(),
        ).toBeVisible();

        // 4. Open the carrier profile from a match.
        await page.getByRole("link", { name: /ver perfil/i }).first().click();
        await expect(page).toHaveURL(/\/carriers\/\d+$/);

        // 4. The Shipper-only back link returns to the same matches screen.
        const back = page.getByRole("link", { name: /volver a la búsqueda/i });
        await expect(back).toBeVisible();
        await back.click();
        await expect(page).toHaveURL(matchesUrl);
    });
});
