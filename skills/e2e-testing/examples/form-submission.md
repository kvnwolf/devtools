# Form Submission

Form fills, submissions, and post-submit verification.

```ts
import { expect } from "@playwright/test";
import { test } from "./utils";

test("creates a new user via form", async ({ page }) => {
  await page.goto("/users/new");

  await page.getByLabel("Name").fill("Alice");
  await page.getByLabel("Email").fill("alice@test.com");
  await page.getByRole("button", { name: "Create" }).click();

  await expect(page).toHaveURL(/\/users\/.+/);
  await expect(page.getByText("Alice")).toBeVisible();
});

test("shows validation errors on empty submit", async ({ page }) => {
  await page.goto("/users/new");
  await page.getByRole("button", { name: "Create" }).click();

  await expect(page.getByText("Name is required")).toBeVisible();
  await expect(page.getByText("Email is required")).toBeVisible();
});
```
