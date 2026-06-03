import { test, expect } from "@playwright/test";

// REQ-FE-00031 — symmetric inverse of REQ-FE-00030: when a Shipper creates a
// CargoOffer against a Carrier's TransportWindow, the Carrier gets an in-app
// toast.
//
// Orchestrating two real roles (Shipper offers against the Carrier's window)
// over a live socket is brittle for an e2e; per the plan we drive the *real*
// notification type through the dev broadcast endpoint and assert the toast
// copy, which comes from landingContent.notifications.cargo_offer_received.
const RECEIVED_TITLE = "Nueva oferta recibida";

// Fire the dev broadcast endpoint from inside the page so it carries the
// stored JWT and hits the same API origin the app uses.
async function broadcastOfferReceived(page: import("@playwright/test").Page): Promise<number> {
    return page.evaluate(async () => {
        const token = window.localStorage.getItem("truckr.jwt");
        const base = `${window.location.protocol}//${window.location.hostname}:3000`;
        const res = await fetch(`${base}/api/dev/notifications/broadcast`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({
                type: "cargo_offer_received",
                payload: { cargo_offer_id: 1, cargo_id: 1, transport_window_id: 1, amount_cents: 1_500_000, currency: "ARS" },
            }),
        });
        return res.status;
    });
}

test.describe("Cargo offer received notifications (REQ-FE-00031)", () => {
    test("a Carrier sees a toast when a Shipper sends them a cargo offer", async ({ page }) => {
        const email = `offer-received-e2e-${Date.now()}@example.com`;
        const password = "Password1";

        await page.goto("/signup");
        await page.fill("#name", "Offer Received E2E");
        await page.fill("#email", email);
        await page.fill("#password", password);
        await page.fill("#passwordConfirm", password);
        await page.check("#role-carrier");
        await page.getByRole("button", { name: /^crear cuenta$/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        // Retry until the toast shows: the WebSocket may still be connecting
        // right after signup, and delivery is best-effort live (ADR-013).
        await expect(async () => {
            const status = await broadcastOfferReceived(page);
            expect(status).toBe(204);
            await expect(page.getByText(RECEIVED_TITLE)).toBeVisible({ timeout: 1000 });
        }).toPass({ timeout: 25_000 });

        // The dismiss control removes the toast.
        await page.getByRole("button", { name: /descartar notificación/i }).first().click();
        await expect(page.getByText(RECEIVED_TITLE)).toHaveCount(0);
    });
});
