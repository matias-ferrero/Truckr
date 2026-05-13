import { expect, test } from "@playwright/test";

/**
 * Golden path for the carrier-search section integrated into the shipper dashboard.
 *
 *   register (as shipper) → land on dashboard → fill search → submit
 *           → results render as dashboard cards → click card → carrier detail
 *
 * The transport_windows API is mocked so this spec is independent of backend
 * seed data — the integration we care about is the dashboard-embedded section,
 * not the upstream search endpoint (already covered by carrier-search.spec.ts).
 */
test("shipper dashboard — embedded carrier search renders results inline", async ({ page }) => {
    await page.route("**/api/transport_windows?**", async (route) => {
        await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify([
                {
                    id: 77,
                    legal_name: "Fletes Pampa",
                    display_name: "Fletes Pampa",
                    base_city: "Rosario",
                    province: "SF",
                    rating_avg: "4.9",
                    completed_shipments: 88,
                    transport_windows: [
                        {
                            id: 410,
                            origin_zone: "Buenos Aires",
                            destination_zone: "Córdoba",
                            price_per_km: "1800.00",
                            max_km: 900,
                            available_from: "2026-06-01T00:00:00.000Z",
                            available_to: "2026-06-30T00:00:00.000Z",
                            active: true,
                        },
                    ],
                },
            ]),
        });
    });

    const email = `pw-shipper-${Date.now()}@example.com`;
    const password = "Password1";

    await page.goto("/signup");
    await page.fill("#name", "Playwright Shipper");
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.fill("#passwordConfirm", password);
    await page.check("#role-shipper");
    await page.getByRole("button", { name: /^crear cuenta$/i }).click();

    // Lands on the shipper dashboard — the search section is the first thing below the hero.
    await expect(
        page.getByRole("heading", { level: 2, name: /encontrá un transportista/i }),
    ).toBeVisible();

    await page.getByLabel("Origen").fill("Buenos Aires");
    await page.getByLabel("Destino").fill("Córdoba");
    await page.getByLabel("Retiro desde").fill("2026-06-01");
    await page.getByLabel("Retiro hasta").fill("2026-06-30");

    await page.getByRole("button", { name: /^buscar$/i }).click();

    const card = page.getByRole("link", { name: /fletes pampa/i });
    await expect(card).toBeVisible();
    await expect(page.getByText(/buenos aires → córdoba/i)).toBeVisible();
    await expect(page.getByText(/4\.9 · 88 viajes · rosario, sf/i)).toBeVisible();

    await card.click();
    await expect(page).toHaveURL(/\/carriers\/77$/);
});
