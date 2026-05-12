import { expect, test } from "@playwright/test";

/**
 * Full JWT lifecycle (ADR-011):
 *
 *   register → reload (token persists) → logout → reload (anonymous)
 *           → login    → reload (token persists)
 *
 * Each reload step proves that the stored `localStorage["truckr.jwt"]`
 * survives a full page navigation — the user stays signed in without
 * any server-side session. Each anonymous step proves the token is
 * actually cleared on logout (no stale identity).
 *
 * Backend test server is auto-booted by playwright.config.ts.
 */
test("register → reload → logout → reload → login → reload", async ({ page }) => {
    const email = `pw-${Date.now()}@example.com`;
    const password = "Password1";

    // 1. Register and land on the home screen.
    await page.goto("/signup");
    await page.fill("#name", "Playwright User");
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.fill("#passwordConfirm", password);
    await page.check("#role-shipper");
    await page.getByRole("button", { name: /^crear cuenta$/i }).click();
    await expect(page.getByText(email)).toBeVisible();

    // 2. Token survives a full reload — SessionWidget still shows the email.
    await page.reload();
    await expect(page.getByText(email)).toBeVisible();
    const jwtAfterRegister = await page.evaluate(() => localStorage.getItem("truckr.jwt"));
    expect(jwtAfterRegister).toMatch(/^[\w-]+\.[\w-]+\.[\w-]+$/);

    // 3. Logout — redirected to /login; token gone from storage.
    await page.getByRole("button", { name: /salir/i }).click();
    await expect(page).toHaveURL(/\/login/);
    const jwtAfterLogout = await page.evaluate(() => localStorage.getItem("truckr.jwt"));
    expect(jwtAfterLogout).toBeNull();

    // 4. Reload while logged out — still anonymous (login form on /login).
    await page.reload();
    await expect(page).toHaveURL(/\/login/);
    await expect(page.getByRole("heading", { name: /iniciar sesión/i })).toBeVisible();

    // 5. Log back in with the same credentials.
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.getByRole("button", { name: /^iniciar sesión$/i }).click();
    await expect(page.getByText(email)).toBeVisible();

    // 6. Token from the new login survives a reload too.
    await page.reload();
    await expect(page.getByText(email)).toBeVisible();
    const jwtAfterLogin = await page.evaluate(() => localStorage.getItem("truckr.jwt"));
    expect(jwtAfterLogin).toMatch(/^[\w-]+\.[\w-]+\.[\w-]+$/);
});
