import { test, expect } from "@playwright/test";

// REQ-FE-00026 (US49) — AddressPicker integration on the shipper cargo form.
// Skipped behind the same auth gate as shipper-cargo.spec.ts until a seeded
// shipper fixture is wired. The spec captures the golden path: open the
// publish form, confirm both pickup and delivery addresses, and verify that
// the POST payload carries the four coordinates. A second spec covers edit
// mode — re-confirming a pin PATCHes the new lat/lng.
//
// The Google Places JS API is stubbed via `page.route` so the spec is
// offline-safe in CI without burning the real key / quota.
test.describe("Shipper — cargo address picker (REQ-FE-00026)", () => {
    test.skip(true, "needs an authenticated-shipper fixture (login via /api/auth/login)");

    test("publishing a cargo captures the four coordinates from the pickers (US27 + US49)", async ({ page }) => {
        await page.route(/maps\.googleapis\.com/, (route) =>
            route.fulfill({
                status:      200,
                contentType: "application/javascript",
                body:        "",
            }),
        );

        let createPayload: Record<string, unknown> | null = null;
        await page.route(/\/api\/cargos$/, async (route) => {
            if (route.request().method() === "POST") {
                createPayload = JSON.parse(route.request().postData() ?? "{}");
                return route.fulfill({
                    status:      201,
                    contentType: "application/json",
                    body:        JSON.stringify({
                        id:                   1,
                        shipper_id:           1,
                        status:               "open",
                        cargo_description:    "Pallets de electrodomésticos",
                        pickup_address:       "Av. Corrientes 1234, CABA",
                        pickup_lat:           "-34.603722",
                        pickup_lng:           "-58.381592",
                        delivery_address:     "Av. Colón 500, Córdoba",
                        delivery_lat:         "-31.420083",
                        delivery_lng:         "-64.188776",
                        pickup_locality:      "CABA",
                        pickup_admin_area:    "Buenos Aires",
                        delivery_locality:    "Córdoba",
                        delivery_admin_area:  "Córdoba",
                        pickup_window_start:  "2026-06-01T08:00:00.000Z",
                        pickup_window_end:    "2026-06-03T18:00:00.000Z",
                        weight_kg:            "1500.0",
                        volume_cm3:           null,
                        declared_value_cents: 5_000_000,
                        cancelled_at:         null,
                        created_at:           "2026-06-01T00:00:00.000Z",
                        updated_at:           "2026-06-01T00:00:00.000Z",
                        editable:             true,
                        pending_offers_count: 0,
                        cargo_offers:         [],
                    }),
                });
            }
            return route.continue();
        });

        await page.goto("/shipper/cargos/new");
        await page.fill("#cargo_description", "Pallets de electrodomésticos");
        await page.fill("#weight_kg", "1500");
        await page.fill("#declared_value_cents", "5000000");

        // Real flow: type into the AddressPicker, click a suggestion. The
        // fixture will replace these placeholders with the autocompleted
        // confirmation once the auth fixture lands.
        await page.getByLabel(/dirección de retiro/i).fill("Av. Corrientes 1234, CABA");
        await page.getByLabel(/dirección de entrega/i).fill("Av. Colón 500, Córdoba");

        await page.fill("#pickup_window_start", "2026-06-01T08:00");
        await page.fill("#pickup_window_end", "2026-06-03T18:00");
        await page.getByRole("button", { name: /publicar carga/i }).click();

        await expect.poll(() => createPayload, { timeout: 4_000 }).not.toBeNull();
        expect(createPayload).toMatchObject({
            cargo: expect.objectContaining({
                pickup_lat:   expect.any(Number),
                pickup_lng:   expect.any(Number),
                delivery_lat: expect.any(Number),
                delivery_lng: expect.any(Number),
            }),
        });
    });

    test("editing a cargo PATCHes new lat/lng after re-confirming both pins (US47 + US49)", async ({ page }) => {
        let patchPayload: Record<string, unknown> | null = null;

        await page.route(/\/api\/cargos\/1$/, async (route) => {
            if (route.request().method() === "GET") {
                return route.fulfill({
                    status:      200,
                    contentType: "application/json",
                    body:        JSON.stringify({
                        id:                   1,
                        shipper_id:           1,
                        status:               "open",
                        cargo_description:    "Pallets",
                        pickup_address:       "Old pickup",
                        pickup_lat:           "-34.6",
                        pickup_lng:           "-58.4",
                        delivery_address:     "Old delivery",
                        delivery_lat:         "-31.4",
                        delivery_lng:         "-64.2",
                        pickup_locality:      "CABA",
                        pickup_admin_area:    "Buenos Aires",
                        delivery_locality:    "Córdoba",
                        delivery_admin_area:  "Córdoba",
                        pickup_window_start:  "2026-06-01T08:00:00.000Z",
                        pickup_window_end:    "2026-06-03T18:00:00.000Z",
                        weight_kg:            "1500.0",
                        volume_cm3:           null,
                        declared_value_cents: 5_000_000,
                        cancelled_at:         null,
                        created_at:           "2026-06-01T00:00:00.000Z",
                        updated_at:           "2026-06-01T00:00:00.000Z",
                        editable:             true,
                        pending_offers_count: 0,
                        cargo_offers:         [],
                    }),
                });
            }
            if (route.request().method() === "PATCH") {
                patchPayload = JSON.parse(route.request().postData() ?? "{}");
                return route.fulfill({
                    status:      200,
                    contentType: "application/json",
                    body:        JSON.stringify({ id: 1 }),
                });
            }
            return route.continue();
        });

        await page.goto("/shipper/cargos/1/edit");
        await expect(page.getByLabel(/dirección de retiro/i)).toHaveValue("Old pickup");

        await page.getByLabel(/dirección de retiro/i).fill("Nueva dirección, CABA");
        await page.getByLabel(/dirección de entrega/i).fill("Nuevo destino, Córdoba");
        await page.getByRole("button", { name: /guardar cambios/i }).click();

        await expect.poll(() => patchPayload, { timeout: 4_000 }).not.toBeNull();
        expect(patchPayload).toMatchObject({
            cargo: expect.objectContaining({
                pickup_lat:   expect.any(Number),
                pickup_lng:   expect.any(Number),
                delivery_lat: expect.any(Number),
                delivery_lng: expect.any(Number),
            }),
        });
    });
});
