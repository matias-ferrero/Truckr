import { expect, test } from "@playwright/test";

test("homepage loads and shows the Truckr® editorial hero", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Truckr/i);
    // Editorial h1 carries the value proposition.
    await expect(
        page.getByRole("heading", { name: /llevamos lo tuyo/i, level: 1 }),
    ).toBeVisible();
    // Brand mark is present in the topbar nav.
    await expect(page.getByText("Truckr®").first()).toBeVisible();
    // Both audience CTAs route into the para-quien section.
    await expect(page.getByRole("link", { name: /tengo un envío/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /tengo un camión/i })).toBeVisible();
});
