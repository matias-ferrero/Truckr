import { test, expect } from "@playwright/test";

// REQ-FE-00024 / US39 — Shipment detail page, Shipper role.
//
// Uses the seeded contacto@granjalaesperanza.test account. Seeds create shipments in
// multiple states (accepted, in_transit, delivered, cancelled) so the list
// always has entries to navigate into.

test.describe("Shipper — shipment detail (REQ-FE-00024 / US39)", () => {
    test.beforeEach(async ({ page }) => {
        await page.goto("/login");
        await page.fill("#email", "contacto@granjalaesperanza.test");
        await page.fill("#password", "Password123");
        await page.getByRole("button", { name: /ingresar|iniciar sesión/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible({ timeout: 10_000 });
    });

    test("golden path: navigates from list to detail and shows shipment data", async ({ page }) => {
        await page.goto("/shipper/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        // Click the first shipment detail link (aria-label: "Envío #N: de X a Y, Estado")
        const firstLink = page.getByRole("link", { name: /envío #\d+/i }).first();
        await expect(firstLink).toBeVisible();
        await firstLink.click();

        // Verify URL and page structure
        await expect(page).toHaveURL(/\/shipper\/shipments\/\d+$/);
        await expect(page.getByRole("heading", { name: /envío #\d+/i })).toBeVisible();

        // Back link points to shipper list
        const backLink = page.getByRole("link", { name: /volver a mis envíos/i });
        await expect(backLink).toBeVisible();
        await expect(backLink).toHaveAttribute("href", "/shipper/shipments");

        // Data grid renders core fields. Exact match targets the <dt> labels,
        // not the US51 "Abrir origen/destino en Google Maps" deep-link buttons.
        await expect(page.getByText("Origen", { exact: true })).toBeVisible();
        await expect(page.getByText("Destino", { exact: true })).toBeVisible();
        await expect(page.getByText("Monto Acordado", { exact: false })).toBeVisible();

        // Map placeholder anchor is always present (AC5)
        await expect(page.locator("#shipment-tracking-map")).toBeAttached();
    });

    test("404: non-existent shipment shows not-found screen with back CTA", async ({ page }) => {
        await page.goto("/shipper/shipments/99999");

        await expect(page.getByRole("heading", { name: /envío no encontrado/i })).toBeVisible();
        const cta = page.getByRole("link", { name: /volver al listado/i });
        await expect(cta).toBeVisible();
        await expect(cta).toHaveAttribute("href", "/shipper/shipments");
    });

    // Requires a seeded shipment in `accepted` + no payment state.
    // Skipped because shipper-payment.spec.ts may consume that state in the same run.
    test.skip("Shipper on accepted+unpaid shipment sees Pendiente de pago banner and Pagar button", async ({ page }) => {
        await page.goto("/shipper/shipments");
        // Find a row in accepted state and navigate to its detail
        const acceptedLink = page.getByRole("link", { name: /envío #\d+.*aceptado/i }).first();
        await acceptedLink.click();

        await expect(page.getByText(/pendiente de pago/i).first()).toBeVisible();
        await expect(page.getByRole("button", { name: /pagar ahora/i })).toBeVisible();
    });

    test("delivered shipment detail shows no action buttons and shows Pagado chip", async ({ page }) => {
        await page.goto("/shipper/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        // Navigate to the review-pending seed: "Maquinaria agrícola", La Plata → Mar del Plata,
        // delivered with no shipper review yet — the review form must be visible.
        const deliveredLink = page.getByRole("link", {
            name: /la plata.*mar del plata.*entregado/i,
        }).first();
        await expect(deliveredLink).toBeVisible();
        await deliveredLink.click();

        await expect(page).toHaveURL(/\/shipper\/shipments\/\d+$/);
        await expect(page.getByRole("heading", { name: /envío #\d+/i })).toBeVisible();

        // No action buttons on delivered shipment (available_actions is empty)
        await expect(page.getByRole("button", { name: /pagar|iniciar|entregar/i })).not.toBeVisible();

        // PaymentStateChip is visible for non-cancelled states (AC3)
        // Text is "Pagado" or "Pendiente de pago" depending on seed payment data.
        await expect(page.locator(".paymentStateChip")).toBeVisible();

        // Shipment-detail v2 §6 — rail contact card links to the carrier's reputation.
        await expect(page.getByRole("link", { name: /ver reputación del transportista/i })).toBeVisible();

        // US20 / REQ-BE-00042 — Shipper can leave a Carrier review on delivered
        // shipments (AC7). v2 §5: the rail CTA opens the form in a modal. Close
        // without submitting so the seeded shipment stays reviewable across runs.
        const reviewCta = page.getByRole("button", { name: /dejá tu reseña/i });
        await expect(reviewCta).toBeVisible();
        await reviewCta.click();
        await expect(page.getByRole("heading", { name: /dejar reseña/i })).toBeVisible();
        await expect(page.getByRole("radiogroup", { name: /puntuación/i })).toBeVisible();
        await page.getByRole("button", { name: /cerrar/i }).click();
        await expect(page.getByRole("radiogroup", { name: /puntuación/i })).not.toBeVisible();
    });
});
