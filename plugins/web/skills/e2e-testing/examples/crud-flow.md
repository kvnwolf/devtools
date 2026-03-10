# CRUD Flow

Full create, edit, delete lifecycle in a single flow.

```ts
import { expect } from "@playwright/test";
import { test } from "./utils";

test("creates, edits, and deletes an item", async ({ page }) => {
  // Create
  await page.goto("/items");
  await page.getByRole("button", { name: "New Item" }).click();
  await page.getByLabel("Name").fill("Test Item");
  await page.getByRole("button", { name: "Save" }).click();
  await expect(page.getByText("Test Item")).toBeVisible();

  // Edit
  await page.getByText("Test Item").click();
  await page.getByLabel("Name").fill("Updated Item");
  await page.getByRole("button", { name: "Save" }).click();
  await expect(page.getByText("Updated Item")).toBeVisible();

  // Delete
  await page.getByRole("button", { name: "Delete" }).click();
  await page.getByRole("button", { name: "Confirm" }).click();
  await expect(page.getByText("Updated Item")).not.toBeVisible();
});
```
