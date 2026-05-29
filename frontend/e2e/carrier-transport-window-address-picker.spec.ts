import { test, expect } from "@playwright/test";

// REQ-FE-00025 (US48) — AddressPicker integration on the carrier transport-window
// form. Skipped behind the same auth gate as carrier-transport-window.spec.ts
// until an authenticated-carrier fixture is wired. The spec captures the golden
// path: open the publish form, type into the origin AddressPicker, accept a
// mocked Google Places suggestion, and verify that the POST payload carries
// origin_lat / origin_lng — plus the edit-mode flow that PATCHes new pins.
//
// The Google Places JS API is stubbed via `page.route` so the spec is offline-safe
// and works in CI without burning the real key / quota.
test.describe("Carrier — transport window address picker (REQ-FE-00025)", () => {
    test.skip(true, "needs an authenticated-carrier fixture (login via /api/auth/login)");

    test("publishing a window captures origin lat/lng from the picker (US9 + US48)", async ({ page }) => {
        // Stub the Google Places JS API loader so we never hit the real CDN.
        await page.route(/maps\.googleapis\.com/, (route) =>
            route.fulfill({
                status:      200,
                contentType: "application/javascript",
                body:        "",
            }),
        );

        // Capture the create payload.
        let createPayload: Record<string, unknown> | null = null;
        await page.route(/\/api\/carriers\/me\/transport_windows$/, async (route) => {
            if (route.request().method() === "POST") {
                createPayload = JSON.parse(route.request().postData() ?? "{}");
                return route.fulfill({
                    status:      201,
                    contentType: "application/json",
                    body:        JSON.stringify({
                        id:                       1,
                        vehicle_id:               10,
                        origin_address:           "Av. Corrientes 1234, CABA, Argentina",
                        origin_locality:          "CABA",
                        origin_admin_area:        "Buenos Aires",
                        origin_lat:               "-34.603722",
                        origin_lng:               "-58.381592",
                        destination_address:      null,
                        destination_locality:     null,
                        destination_admin_area:   null,
                        destination_lat:          null,
                        destination_lng:          null,
                        pickup_radius_km:         10,
                        dropoff_radius_km:        null,
                        price_per_km:       "1500.0",
                        max_km:             1200,
                        available_from:     "2026-07-01T00:00:00.000Z",
                        available_to:       "2026-07-31T23:59:00.000Z",
                        active:             true,
                        cargo_offers_count: 0,
                        vehicle:            { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
                        created_at:         "2026-06-01T00:00:00.000Z",
                        updated_at:         "2026-06-01T00:00:00.000Z",
                    }),
                });
            }
            return route.continue();
        });

        await page.goto("/carrier/availability/new");
        await page.getByLabel(/vehículo/i).selectOption({ label: /Sprinter/i });

        // Simulate a confirmed Place pick by typing into the AddressPicker.
        // Real flow: the user clicks a suggestion from the mocked Google
        // Autocomplete; the picker writes back { address, lat, lng,
        // locality, admin_area }. The fixture should replace this `fill`
        // with the real click once it lands.
        await page.getByLabel(/dirección de origen/i).fill("Av. Corrientes 1234, CABA");

        await page.getByLabel(/precio por km/i).fill("1500");
        await page.getByLabel(/kilómetros máximos/i).fill("1200");
        await page.getByLabel(/disponible desde/i).fill("2026-07-01");
        await page.getByLabel(/disponible hasta/i).fill("2026-07-31");
        await page.getByRole("button", { name: /publicar disponibilidad/i }).click();

        await expect.poll(() => createPayload, { timeout: 4_000 }).not.toBeNull();
        expect(createPayload).toMatchObject({
            transport_window: expect.objectContaining({
                origin_address:    expect.any(String),
                origin_locality:   expect.any(String),
                origin_admin_area: expect.any(String),
                origin_lat:        expect.any(Number),
                origin_lng:        expect.any(Number),
            }),
        });
    });

    test("editing a window PATCHes new lat/lng after re-confirming the pin (US33)", async ({ page }) => {
        let patchPayload: Record<string, unknown> | null = null;

        await page.route(/\/api\/carriers\/me\/transport_windows\/1$/, async (route) => {
            if (route.request().method() === "GET") {
                return route.fulfill({
                    status:      200,
                    contentType: "application/json",
                    body:        JSON.stringify({
                        id:                       1,
                        vehicle_id:               10,
                        origin_address:           "Old origin",
                        origin_locality:          "CABA",
                        origin_admin_area:        "Buenos Aires",
                        origin_lat:               "-34.6",
                        origin_lng:               "-58.4",
                        destination_address:      null,
                        destination_locality:     null,
                        destination_admin_area:   null,
                        destination_lat:          null,
                        destination_lng:          null,
                        pickup_radius_km:         10,
                        dropoff_radius_km:        null,
                        price_per_km:       "1500.0",
                        max_km:             1200,
                        available_from:     "2026-07-01T00:00:00.000Z",
                        available_to:       "2026-07-31T23:59:00.000Z",
                        active:             true,
                        cargo_offers_count: 0,
                        vehicle:            { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
                        created_at:         "2026-06-01T00:00:00.000Z",
                        updated_at:         "2026-06-01T00:00:00.000Z",
                    }),
                });
            }
            if (route.request().method() === "PATCH") {
                patchPayload = JSON.parse(route.request().postData() ?? "{}");
                return route.fulfill({ status: 200, contentType: "application/json", body: "{}" });
            }
            return route.continue();
        });

        await page.goto("/carrier/availability/1");
        await expect(page.getByLabel(/dirección de origen/i)).toHaveValue("Old origin");

        // Re-confirm a new origin via the picker (real impl: click a suggestion).
        await page.getByLabel(/dirección de origen/i).fill("Nueva dirección, CABA");
        await page.getByRole("button", { name: /guardar cambios/i }).click();

        await expect.poll(() => patchPayload, { timeout: 4_000 }).not.toBeNull();
        expect(patchPayload).toMatchObject({
            transport_window: expect.objectContaining({
                origin_lat: expect.any(Number),
                origin_lng: expect.any(Number),
            }),
        });
    });
});
