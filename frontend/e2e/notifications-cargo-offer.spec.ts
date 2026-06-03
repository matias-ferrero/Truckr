import { test, expect } from "@playwright/test";

// REQ-FE-00030 — first business consumer of the realtime notifications
// framework: when a Carrier resolves the Shipper's cargo offer, the Shipper
// gets an in-app toast (in addition to the durable email).
//
// Orchestrating two real roles (Shipper offers, Carrier accepts) over a live
// socket is brittle for an e2e; per the plan we drive the *real* notification
// type through the dev broadcast endpoint and assert the toast copy, which
// comes from landingContent.notifications.cargo_offer_accepted (the i18n
// bundle).
const ACCEPTED_TITLE = "Tu oferta fue aceptada";

// Fire the dev broadcast endpoint from inside the page so it carries the
// stored JWT and hits the same API origin the app uses.
async function broadcastOfferAccepted(page: import("@playwright/test").Page): Promise<number> {
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
                type: "cargo_offer_accepted",
                payload: { cargo_offer_id: 1, cargo_id: 1, amount_cents: 1_500_000, currency: "ARS", shipment_id: 1 },
            }),
        });
        return res.status;
    });
}

test.describe("Cargo offer resolution notifications (REQ-FE-00030)", () => {
    test("a Shipper sees a toast when their cargo offer is accepted", async ({ page }) => {
        const email = `offer-notif-e2e-${Date.now()}@example.com`;
        const password = "Password1";

        await page.goto("/signup");
        await page.fill("#name", "Offer Notif E2E");
        await page.fill("#email", email);
        await page.fill("#password", password);
        await page.fill("#passwordConfirm", password);
        await page.check("#role-shipper");
        await page.getByRole("button", { name: /^crear cuenta$/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        // Retry until the toast shows: the WebSocket may still be connecting
        // right after signup, and delivery is best-effort live (ADR-013).
        await expect(async () => {
            const status = await broadcastOfferAccepted(page);
            expect(status).toBe(204);
            await expect(page.getByText(ACCEPTED_TITLE)).toBeVisible({ timeout: 1000 });
        }).toPass({ timeout: 25_000 });

        // The dismiss control removes the toast.
        await page.getByRole("button", { name: /descartar notificación/i }).first().click();
        await expect(page.getByText(ACCEPTED_TITLE)).toHaveCount(0);
    });
});
