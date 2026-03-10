# Conditional Rendering

Testing components that show/hide content based on props or state.

```tsx
import { render } from "vitest-browser-react";
import { page } from "vitest/browser";
import { describe, expect, test } from "vitest";
import { Alert } from "./alert";
import { DataLoader } from "./data-loader";

describe("Alert", () => {
  test("shows message when visible", async () => {
    await render(<Alert message="Saved successfully" visible />);
    await expect.element(page.getByText("Saved successfully")).toBeInTheDocument();
  });

  test("hides message when not visible", async () => {
    await render(<Alert message="Saved successfully" visible={false} />);
    await expect.element(page.getByText("Saved successfully")).not.toBeInTheDocument();
  });

  test("dismisses on close click", async () => {
    await render(<Alert message="Saved successfully" visible />);

    await page.getByRole("button", { name: "Close" }).click();
    await expect.element(page.getByText("Saved successfully")).not.toBeInTheDocument();
  });
});

describe("DataLoader", () => {
  test("shows loading state initially", async () => {
    await render(<DataLoader loading data={null} />);
    await expect.element(page.getByText("Loading...")).toBeInTheDocument();
  });

  test("shows data when loaded", async () => {
    await render(<DataLoader loading={false} data="Results here" />);

    await expect.element(page.getByText("Loading...")).not.toBeInTheDocument();
    await expect.element(page.getByText("Results here")).toBeInTheDocument();
  });

  test("shows error state", async () => {
    await render(<DataLoader loading={false} data={null} error="Failed to fetch" />);
    await expect.element(page.getByText("Failed to fetch")).toBeInTheDocument();
  });
});
```
