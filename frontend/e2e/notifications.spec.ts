import { test, expect } from "@playwright/test";

// INF-FE-00005 — realtime notifications framework, golden path:
// sign up → backend pushes a `ping` via POST /api/dev/notifications/ping →
// the toast appears in the browser over the live Action Cable socket.
//
// The toast copy comes from landingContent.notifications.ping (the i18n
// bundle); asserted here as visible UI text.
const PING_TITLE = "Notificaciones activas";

// Fire the dev ping endpoint from inside the page so it carries the stored JWT
// and hits the same API origin the app uses.
async function triggerPing(page: import("@playwright/test").Page): Promise<number> {
    return page.evaluate(async () => {
        const token = window.localStorage.getItem("truckr.jwt");
        const base = `${window.location.protocol}//${window.location.hostname}:3000`;
        const res = await fetch(`${base}/api/dev/notifications/ping`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({ message: "e2e" }),
        });
        return res.status;
    });
}

test.describe("Notifications framework (INF-FE-00005)", () => {
    test("a pushed ping surfaces a toast in the browser", async ({ page }) => {
        const email = `notif-e2e-${Date.now()}@example.com`;
        const password = "Password1";

        await page.goto("/signup");
        await page.fill("#name", "Notif E2E");
        await page.fill("#email", email);
        await page.fill("#password", password);
        await page.fill("#passwordConfirm", password);
        await page.check("#role-shipper");
        await page.getByRole("button", { name: /^crear cuenta$/i }).click();
        await expect(page.getByRole("button", { name: /salir/i })).toBeVisible();

        // Retry the ping until the toast shows: the WebSocket may still be
        // connecting right after login, and delivery is best-effort live —
        // a ping sent before the socket is up is simply lost (ADR-013).
        await expect(async () => {
            const status = await triggerPing(page);
            expect(status).toBe(204);
            await expect(page.getByText(PING_TITLE)).toBeVisible({ timeout: 1000 });
        }).toPass({ timeout: 25_000 });

        // The dismiss control removes the toast.
        await page.getByRole("button", { name: /descartar notificación/i }).first().click();
        await expect(page.getByText(PING_TITLE)).toHaveCount(0);
    });
});
