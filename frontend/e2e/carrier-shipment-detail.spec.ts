import { test, expect } from "@playwright/test";

// REQ-FE-00024 / US39 — Shipment detail page, Carrier role.
//
// Uses the seeded operaciones@andinacargo.test account. Seeds create shipments in
// multiple states; in_transit sorts first (sort order weight 0), so the
// first row in the carrier list is reliably an in_transit shipment.

test.describe("Carrier — shipment detail (REQ-FE-00024 / US39)", () => {
    test.beforeEach(async ({ page }) => {
        await page.goto("/login");
        await page.fill("#email", "operaciones@andinacargo.test");
        await page.fill("#password", "Password123");
        await page.getByRole("button", { name: /ingresar|iniciar sesión/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();
    });

    test("golden path: navigates from list to detail and shows shipment data", async ({ page }) => {
        await page.goto("/carrier/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        const firstLink = page.getByRole("link", { name: /envío #\d+/i }).first();
        await expect(firstLink).toBeVisible();
        await firstLink.click();

        await expect(page).toHaveURL(/\/carrier\/shipments\/\d+$/);
        await expect(page.getByRole("heading", { name: /envío #\d+/i })).toBeVisible();

        // Back link points to carrier list
        const backLink = page.getByRole("link", { name: /volver a mis envíos/i });
        await expect(backLink).toBeVisible();
        await expect(backLink).toHaveAttribute("href", "/carrier/shipments");

        // Data grid fields. Exact match targets the <dt> labels, not the US51
        // "Abrir origen/destino en Google Maps" deep-link buttons.
        await expect(page.getByText("Origen", { exact: true })).toBeVisible();
        await expect(page.getByText("Destino", { exact: true })).toBeVisible();

        // Map placeholder anchor is always present (AC5 — anchor for US51)
        await expect(page.locator("#shipment-tracking-map")).toBeAttached();
    });

    test("carrier on in_transit shipment: detail shows state chip and deliver button", async ({ page }) => {
        await page.goto("/carrier/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        // in_transit sorts first (weight 0 in shipmentStateSortOrder) — first link is in_transit
        const firstLink = page.getByRole("link", { name: /en tránsito/i }).first();
        await expect(firstLink).toBeVisible();
        await firstLink.click();

        await expect(page).toHaveURL(/\/carrier\/shipments\/\d+$/);
        // Use the state chip locator to avoid matching the timeline event label too.
        await expect(page.locator(".shipmentStateChip").getByText("En tránsito")).toBeVisible();
        // The detail page still exposes the carrier action for this state.
        await expect(page.getByRole("button", { name: /confirmar entrega/i })).toBeVisible();

        // v2 §4 — state-aware navigation: while in_transit the delivery nav link
        // is promoted alongside the full-route deep-link.
        await expect(page.getByRole("link", { name: /navegar al punto de entrega/i })).toBeVisible();
        await expect(page.getByRole("link", { name: /ver ruta.*google maps/i })).toBeVisible();
    });

    test("404: non-existent shipment shows not-found screen with back CTA", async ({ page }) => {
        await page.goto("/carrier/shipments/99999");

        await expect(page.getByRole("heading", { name: /envío no encontrado/i })).toBeVisible();
        const cta = page.getByRole("link", { name: /volver al listado/i });
        await expect(cta).toBeVisible();
        await expect(cta).toHaveAttribute("href", "/carrier/shipments");
    });

    // US30 / REQ-BE-00044 — the review form is wired into the Carrier detail
    // view for delivered shipments (AC7). Non-mutating: asserts the form renders
    // end-to-end (real API serves the delivered shipment with carrier_review:
    // null, the page mounts CarrierReviewForm) but does NOT submit, so the
    // seeded shipment stays reviewable across runs.
    test("carrier on delivered shipment: shows the Shipper review form", async ({ page }) => {
        await page.goto("/carrier/shipments");
        await expect(page.getByRole("heading", { name: "Mis Envíos" })).toBeVisible();

        const deliveredLink = page.getByRole("link", { name: /entregado/i }).first();
        await expect(deliveredLink).toBeVisible();
        await deliveredLink.click();

        await expect(page).toHaveURL(/\/carrier\/shipments\/\d+$/);
        // Wait for the detail view to mount (the back link is detail-only) before
        // querying the state chip. The list renders one .shipmentStateChip per row,
        // so asserting mid-SPA-transition — while the list DOM lingers — would match
        // all five seeded delivered shipments and trip strict mode.
        await expect(page.getByRole("link", { name: /volver a mis envíos/i })).toBeVisible();
        await expect(page.locator(".shipmentStateChip").getByText("Entregado")).toBeVisible();

        // Shipment-detail v2 §6 — rail contact card links to the shipper's reputation.
        await expect(page.getByRole("link", { name: /ver reputación del expedidor/i })).toBeVisible();

        // v2 §5 — the rail CTA opens the review form in a modal. Close without
        // submitting so the seeded shipment stays reviewable across runs.
        const reviewCta = page.getByRole("button", { name: /dejá tu reseña/i });
        await expect(reviewCta).toBeVisible();
        await reviewCta.click();
        await expect(page.getByRole("heading", { name: /reseñar al expedidor/i })).toBeVisible();
        await expect(page.getByRole("radiogroup", { name: /puntuación/i })).toBeVisible();
        await expect(page.getByRole("button", { name: /enviar reseña/i })).toBeVisible();
        await page.getByRole("button", { name: /cerrar/i }).click();
        await expect(page.getByRole("radiogroup", { name: /puntuación/i })).not.toBeVisible();
    });

    // Full golden path requires the seeded in_transit shipment to actually
    // transition — which consumes the seed. Skipped to avoid cross-test contamination.
    test.skip("golden path: Carrier start_transit → deliver → chip updates to Entregado", async ({ page }) => {
        await page.goto("/carrier/shipments");

        // Find accepted+escrowed shipment showing "Confirmar Retiro"
        const acceptedLink = page.getByRole("link", { name: /aceptado/i }).first();
        await acceptedLink.click();

        await expect(page.getByRole("button", { name: /confirmar retiro/i })).toBeVisible();
        await page.getByRole("button", { name: /confirmar retiro/i }).click();

        const dialog = page.getByRole("dialog");
        await expect(dialog).toBeVisible();
        await dialog.getByRole("button", { name: /confirmar/i }).click();

        // Chip updates to in_transit
        await expect(page.getByText("En tránsito")).toBeVisible();
        await expect(page.getByRole("button", { name: /confirmar entrega/i })).toBeVisible();

        // Deliver
        await page.getByRole("button", { name: /confirmar entrega/i }).click();
        const dialog2 = page.getByRole("dialog");
        await expect(dialog2).toBeVisible();
        await dialog2.getByRole("button", { name: /confirmar/i }).click();

        await expect(page.getByText("Entregado")).toBeVisible();
        await expect(page.getByRole("button", { name: /iniciar|entregar|pagar/i })).not.toBeVisible();
    });
});
