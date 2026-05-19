import { test, expect } from "@playwright/test";

// REQ-FE-00015 (US7) — requires:
//   1. An authenticated Shipper fixture (login via /api/auth/login).
//   2. A seeded Carrier with at least one active TransportWindow.
//   3. The window's available_from / available_to to include a future pickup_date.
//
// Wire real fixtures before un-skipping. Until then the RequireShipper gate
// redirects to /login and the wizard never mounts.
test.describe("Shipper — create offer wizard (REQ-FE-00015 / US7)", () => {
    test.skip(true, "needs seeded shipper + carrier with active transport window");

    test("full wizard flow: addresses → cargo → date+km → confirmation", async ({ page }) => {
        // 1. Login as a seeded Shipper.
        await page.goto("/login");
        await page.fill('[name="email"]', "shipper@truckr.test");
        await page.fill('[name="password"]', "Password123");
        await page.click('button[type="submit"]');
        await page.waitForURL("/");

        // 2. Navigate to the seeded carrier's public profile.
        await page.goto("/carriers/1");
        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();

        // 3. Click the "Ofertar" CTA on the first transport window.
        const offerBtn = page.getByTestId("offer-cta-top").first();
        await expect(offerBtn).toBeVisible();
        await offerBtn.click();

        // 4. Assert wizard URL and step 1 heading.
        await expect(page).toHaveURL(/\/carriers\/1\/offers\/new/);
        await expect(
            page.getByText("¿Dónde retiramos y entregamos?"),
        ).toBeVisible();

        // 5. Fill step 1: Addresses (structured fields).
        await page.fill("#pickup_street", "Av. Corrientes");
        await page.fill("#pickup_number", "1234");
        await page.fill("#pickup_postal_code", "C1043");
        await page.fill("#pickup_city", "CABA");
        await page.selectOption("#pickup_province", "Ciudad Autónoma de Buenos Aires");

        await page.fill("#delivery_street", "Av. Colón");
        await page.fill("#delivery_number", "500");
        await page.fill("#delivery_postal_code", "X5000");
        await page.fill("#delivery_city", "Córdoba");
        await page.selectOption("#delivery_province", "Córdoba");

        await page.click('button:has-text("Siguiente")');

        // 6. Fill step 2: Cargo details.
        await expect(page.getByText("Detalle de la carga")).toBeVisible();
        await page.fill("#cargo_description", "Pallets de electrodomésticos");
        await page.fill("#weight_kg", "1500");
        await page.fill("#volume_cm3", "3000000");
        await page.fill("#declared_value_pesos", "50000");
        await page.click('button:has-text("Siguiente")');

        // 7. Fill step 3: Date + estimated km; verify cost estimate updates.
        await expect(page.getByText("Fecha y resumen del presupuesto")).toBeVisible();
        await page.fill("#pickup_date", "2026-05-25");
        await page.fill("#estimated_km", "700");

        const costEl = page.getByTestId("cost-estimate");
        await expect(costEl).not.toContainText("Ingresá los km");

        // 8. Submit.
        await page.click('button:has-text("Enviar oferta")');

        // 9. Assert confirmation screen with quote reference.
        await expect(page.getByTestId("confirmation-screen")).toBeVisible();
        await expect(page.getByText(/Referencia de oferta: #\d+/)).toBeVisible();
        await expect(page.getByText("Estado: pendiente de respuesta")).toBeVisible();
    });
});
