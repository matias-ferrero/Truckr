import { expect, test } from "@playwright/test";

test("homepage loads and shows the Truckr® hero", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Truckr/i);
    await expect(
        page.getByRole("heading", { name: "Truckr®", level: 1 }),
    ).toBeVisible();
});
