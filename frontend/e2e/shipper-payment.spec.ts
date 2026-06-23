import { test, expect } from "@playwright/test";

// REQ-BE-00033 / US8 — Shipper payment flow with fake gateway.
//
// Golden path against the seeded contacto@granjalaesperanza.test account, which owns
// (per `backend/db/seeds.rb`) the "Semillas de maíz en bolsas" shipment in
// `accepted + payment pending` — the exact precondition for the Pagar CTA. Its
// carrier is the independent transporter Diego Sosa.
test.describe("Shipper — payment flow (REQ-BE-00033 / US8)", () => {
    test("golden path: shipper pays an accepted shipment and sees the carrier's contact info", async ({ page }) => {
        await page.goto("/login");
        await page.fill("#email", "contacto@granjalaesperanza.test");
        await page.fill("#password", "Password123");
        await page.getByRole("button", { name: /ingresar|iniciar sesión/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        await page.goto("/shipper/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        const payButton = page.getByRole("button", { name: /^Pagar /i }).first();
        await expect(payButton).toBeVisible();
        await payButton.click();

        // Confirmation dialog opens before navigating to checkout.
        const payDialog = page.getByRole("dialog");
        await expect(payDialog).toBeVisible();
        await payDialog.getByRole("button", { name: /confirmar/i }).click();

        await expect(page).toHaveURL(/\/shipper\/shipments\/\d+\/pay$/);
        await expect(page.getByRole("heading", { name: "Pagar envío" })).toBeVisible();

        await page.fill("#payCardNumber", "4242 4242 4242 4242");
        await page.fill("#payExpiry", "12/30");
        await page.fill("#payCvv", "123");
        await page.fill("#payHolder", "Shipper Demo");
        await page.fill("#payStreet", "Av. Demo 1234");
        await page.fill("#payCity", "Buenos Aires");
        await page.selectOption("#payProvince", "CABA");
        await page.fill("#payPostalCode", "1414");

        await page.getByRole("button", { name: /^Realizar pago$/ }).click();

        await expect(page).toHaveURL(/\/shipper\/shipments\/\d+\/pay\/success$/);
        await expect(page.getByRole("heading", { name: "Pago confirmado" })).toBeVisible();

        // Contact reveal — at least the email comes from a seeded User row.
        const contactPanel = page.getByLabel("Datos de contacto del transportista");
        await expect(contactPanel).toBeVisible();
        await expect(contactPanel.getByText("diego.sosa@truckr.test")).toBeVisible();

        await page.getByRole("link", { name: "Volver a Mis Envíos" }).click();
        await expect(page).toHaveURL(/\/shipper\/shipments$/);

        // Post-payment interlock: the just-paid shipment advanced to
        // `pending_payment`, so its Pagar CTA is gone and the carrier's
        // legal name (seeded as "Diego Sosa") is unmasked.
        await expect(
            page.getByText("Diego Sosa").first(),
        ).toBeVisible();
    });
});
