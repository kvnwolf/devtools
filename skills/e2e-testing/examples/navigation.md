# Navigation

Page transitions, link clicks, and URL assertions.

```ts
import { expect } from "@playwright/test";
import { test } from "./utils";

test("navigates from home to about page", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "About" }).click();

  await expect(page).toHaveURL("/about");
  await expect(page.getByRole("heading")).toHaveText("About Us");
});

test("navigates back after viewing details", async ({ page }) => {
  await page.goto("/products");
  await page.getByText("Widget Pro").click();

  await expect(page).toHaveURL(/\/products\/.+/);
  await page.getByRole("link", { name: "Back to products" }).click();
  await expect(page).toHaveURL("/products");
});
```
