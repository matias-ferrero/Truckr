import { expect, test } from "@playwright/test";

/**
 * Happy-path: register → /me → logout.
 *
 * This test assumes a live Rails backend is reachable from the dev preview
 * server's process at the address baked into VITE_API_BASE_URL (defaults to
 * http://localhost:3000). CI skips this spec when the backend isn't booted.
 */
test("register → me → logout", async ({ page }) => {
    const email = `pw-${Date.now()}@example.com`;

    await page.goto("/signup");
    await page.fill("#name", "Playwright User");
    await page.fill("#email", email);
    await page.fill("#password", "Password1");
    await page.fill("#passwordConfirm", "Password1");
    await page.check("#role-shipper");

    await page.getByRole("button", { name: /^crear cuenta$/i }).click();

    // After register, AuthContext sets the Me state — the SessionWidget renders the email.
    await expect(page.getByText(email)).toBeVisible();

    await page.getByRole("button", { name: /salir/i }).click();
    await expect(page).toHaveURL(/\/login/);
});
