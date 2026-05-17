import { expect, test } from "@playwright/test";

/**
 * US3 / REQ-FE-00012 — Modificar perfil.
 *
 * Full round trip: register → land on dashboard → /profile → edit
 * name → save → re-read /api/auth/me on reload → see the change
 * stuck. Proves both the frontend wiring and the backend PATCH end
 * up persisting against the same row.
 */
test("user edits their name on /profile and the change persists across reload", async ({ page }) => {
    const email = `pw-profile-${Date.now()}@example.com`;
    const password = "Password1";

    // 1. Register a fresh shipper so the test owns its row.
    await page.goto("/signup");
    await page.fill("#name", "Original Name");
    await page.fill("#email", email);
    await page.fill("#password", password);
    await page.fill("#passwordConfirm", password);
    await page.check("#role-shipper");
    await page.getByRole("button", { name: /^crear cuenta$/i }).click();
    // Wait until the dashboard recognises us — the header profile link
    // (labelled "Mi perfil — <name>") shows up once /api/auth/me resolves
    // with the just-issued JWT.
    const headerProfileLink = page
        .getByRole("banner")
        .getByRole("link", { name: /^mi perfil — original name$/i });
    await expect(headerProfileLink).toBeVisible();

    // 2. Navigate to /profile via the single header profile entry point.
    await headerProfileLink.click();
    await expect(page).toHaveURL(/\/profile/);
    await expect(page.getByRole("heading", { name: /^mi perfil$/i })).toBeVisible();

    // 3. Form is pre-populated with current data and Save is disabled.
    const nameInput = page.getByLabel(/nombre completo/i);
    await expect(nameInput).toHaveValue("Original Name");
    const saveBtn = page.getByRole("button", { name: /^guardar cambios$/i });
    await expect(saveBtn).toBeDisabled();

    // 4. Edit the name and confirm Save unlocks.
    await nameInput.fill("Updated Name");
    await expect(saveBtn).toBeEnabled();

    // 5. Save and observe the success toast.
    await saveBtn.click();
    await expect(page.getByText(/actualizados correctamente/i)).toBeVisible();
    // Save goes back to disabled because the draft now matches the server.
    await expect(saveBtn).toBeDisabled();

    // 6. Full reload — the change must survive (real persistence, not
    //    just a local setState). After the reload the form is re-hydrated
    //    from a fresh GET /api/auth/me, so seeing "Updated Name" here
    //    means the row really changed in the database.
    await page.reload();
    await expect(page.getByLabel(/nombre completo/i)).toHaveValue("Updated Name");
});
