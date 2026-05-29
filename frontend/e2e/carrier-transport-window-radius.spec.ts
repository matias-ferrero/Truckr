import { test, expect } from "@playwright/test";

// REQ-BE-00039 (address-driven matching) — pickup + dropoff radius controls
// on the carrier transport-window form. Skipped behind the same auth gate as
// the sibling specs in carrier-transport-window-address-picker.spec.ts and
// carrier-transport-window.spec.ts, until an authenticated-carrier fixture
// (login via /api/auth/login) is wired.
//
// Golden paths covered:
//   1. Publish a bounded window (origin + destination both pinned) with both
//      radii customized; verify both land in the POST payload.
//   2. Publish an open-destination window (destination cleared); verify
//      destination_* fields are null and dropoff_radius_km is null.
//   3. Edit a bounded window and bump the dropoff radius via PATCH.
//
// The Google Maps JS API is stubbed via `page.route` so the spec is
// offline-safe and works in CI without burning the real key / quota.
test.describe("Carrier — transport window radius controls (REQ-BE-00039)", () => {
    test.skip(true, "needs an authenticated-carrier fixture (login via /api/auth/login)");

    test("publishing a bounded window persists both radii (US9 + US52)", async ({ page }) => {
        await page.route(/maps\.googleapis\.com/, (route) =>
            route.fulfill({
                status:      200,
                contentType: "application/javascript",
                body:        "",
            }),
        );

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
                        origin_address:           "Av. Corrientes 1234, CABA",
                        origin_locality:          "CABA",
                        origin_admin_area:        "Buenos Aires",
                        origin_lat:               "-34.603722",
                        origin_lng:               "-58.381592",
                        destination_address:      "Av. Colón 500, Córdoba",
                        destination_locality:     "Córdoba",
                        destination_admin_area:   "Córdoba",
                        destination_lat:          "-31.420083",
                        destination_lng:          "-64.188776",
                        price_per_km:             "1500.0",
                        max_km:                   1200,
                        pickup_radius_km:         25,
                        dropoff_radius_km:        40,
                        available_from:           "2026-07-01T00:00:00.000Z",
                        available_to:             "2026-07-31T23:59:00.000Z",
                        active:                   true,
                        cargo_offers_count:       0,
                        vehicle: { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
                        created_at:               "2026-06-01T00:00:00.000Z",
                        updated_at:               "2026-06-01T00:00:00.000Z",
                    }),
                });
            }
            return route.continue();
        });

        await page.goto("/carrier/availability/new");
        await page.getByLabel(/vehículo/i).selectOption({ label: /Sprinter/i });
        await page.getByLabel(/dirección de origen/i).fill("Av. Corrientes 1234, CABA");
        await page.getByLabel(/dirección de destino/i).fill("Av. Colón 500, Córdoba");
        await page.getByLabel(/radio de recogida/i).fill("25");
        await page.getByLabel(/radio de entrega/i).fill("40");
        await page.getByLabel(/precio por km/i).fill("1500");
        await page.getByLabel(/kilómetros máximos/i).fill("1200");
        await page.getByLabel(/disponible desde/i).fill("2026-07-01");
        await page.getByLabel(/disponible hasta/i).fill("2026-07-31");
        await page.getByRole("button", { name: /publicar disponibilidad/i }).click();

        await expect.poll(() => createPayload, { timeout: 4_000 }).not.toBeNull();
        expect(createPayload).toMatchObject({
            transport_window: expect.objectContaining({
                pickup_radius_km:  25,
                dropoff_radius_km: 40,
            }),
        });
    });

    test("publishing an open-destination window omits dropoff fields (US52)", async ({ page }) => {
        await page.route(/maps\.googleapis\.com/, (route) =>
            route.fulfill({ status: 200, contentType: "application/javascript", body: "" }),
        );

        let createPayload: Record<string, unknown> | null = null;
        await page.route(/\/api\/carriers\/me\/transport_windows$/, async (route) => {
            if (route.request().method() === "POST") {
                createPayload = JSON.parse(route.request().postData() ?? "{}");
                return route.fulfill({ status: 201, contentType: "application/json", body: "{}" });
            }
            return route.continue();
        });

        await page.goto("/carrier/availability/new");
        await page.getByLabel(/vehículo/i).selectOption({ label: /Sprinter/i });
        await page.getByLabel(/dirección de origen/i).fill("Av. Corrientes 1234, CABA");
        // Leave destination AddressPicker empty → dropoff radius control is
        // hidden and the form submits `null` for every destination_* + dropoff field.
        await expect(page.getByLabel(/radio de entrega/i)).toHaveCount(0);
        await page.getByLabel(/precio por km/i).fill("1500");
        await page.getByLabel(/kilómetros máximos/i).fill("1200");
        await page.getByLabel(/disponible desde/i).fill("2026-07-01");
        await page.getByLabel(/disponible hasta/i).fill("2026-07-31");
        await page.getByRole("button", { name: /publicar disponibilidad/i }).click();

        await expect.poll(() => createPayload, { timeout: 4_000 }).not.toBeNull();
        expect(createPayload).toMatchObject({
            transport_window: expect.objectContaining({
                destination_address:    null,
                destination_locality:   null,
                destination_admin_area: null,
                destination_lat:        null,
                destination_lng:        null,
                dropoff_radius_km:      null,
            }),
        });
    });

    test("editing a window PATCHes a new dropoff_radius_km (US33 + US52)", async ({ page }) => {
        let patchPayload: Record<string, unknown> | null = null;

        await page.route(/\/api\/carriers\/me\/transport_windows\/1$/, async (route) => {
            if (route.request().method() === "GET") {
                return route.fulfill({
                    status:      200,
                    contentType: "application/json",
                    body:        JSON.stringify({
                        id:                       1,
                        vehicle_id:               10,
                        origin_address:           "Old origin, CABA",
                        origin_locality:          "CABA",
                        origin_admin_area:        "Buenos Aires",
                        origin_lat:               "-34.6",
                        origin_lng:               "-58.4",
                        destination_address:      "Old dest, Córdoba",
                        destination_locality:     "Córdoba",
                        destination_admin_area:   "Córdoba",
                        destination_lat:          "-31.4",
                        destination_lng:          "-64.2",
                        price_per_km:             "1500.0",
                        max_km:                   1200,
                        pickup_radius_km:         25,
                        dropoff_radius_km:        20,
                        available_from:           "2026-07-01T00:00:00.000Z",
                        available_to:             "2026-07-31T23:59:00.000Z",
                        active:                   true,
                        cargo_offers_count:       0,
                        vehicle: { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
                        created_at:               "2026-06-01T00:00:00.000Z",
                        updated_at:               "2026-06-01T00:00:00.000Z",
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
        await expect(page.getByLabel(/radio de entrega/i)).toHaveValue("20");
        await page.getByLabel(/radio de entrega/i).fill("60");
        await page.getByRole("button", { name: /guardar cambios/i }).click();

        await expect.poll(() => patchPayload, { timeout: 4_000 }).not.toBeNull();
        expect(patchPayload).toMatchObject({
            transport_window: expect.objectContaining({ dropoff_radius_km: 60 }),
        });
    });
});
