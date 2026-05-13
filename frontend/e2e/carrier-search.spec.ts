import { expect, test } from "@playwright/test";

test("carrier search happy path with mocked results", async ({ page }) => {
    await page.route("**/api/transport_windows?**", async (route) => {
        await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify([
                {
                    id: 42,
                    legal_name: "Fletes del Centro",
                    display_name: "Fletes del Centro",
                    base_city: "Buenos Aires",
                    province: "CABA",
                    rating_avg: "4.8",
                    completed_shipments: 124,
                    transport_windows: [
                        {
                            id: 301,
                            origin_zone: "Buenos Aires",
                            destination_zone: "Córdoba",
                            price_per_km: "2300.00",
                            max_km: 1200,
                            available_from: "2026-05-12T09:00:00.000Z",
                            available_to: "2026-05-16T18:00:00.000Z",
                            active: true,
                        },
                    ],
                },
            ]),
        });
    });

    await page.goto("/transport_windows/search");

    await page.getByLabel("Zona de origen").fill("Buenos Aires");
    await page.getByLabel("Zona de destino").fill("Córdoba");
    await page.getByLabel("Retiro desde").fill("2026-05-12");
    await page.getByLabel("Retiro hasta").fill("2026-05-14");

    await page.getByRole("button", { name: "Buscar" }).click();

    await expect(page.getByRole("heading", { name: "Fletes del Centro" })).toBeVisible();
    await page.getByRole("link", { name: "Ver detalle" }).click();

    await expect(page).toHaveURL(/\/carriers\/42$/);
    await expect(page.getByRole("heading", { name: "Detalle del transportista" })).toBeVisible();
});
