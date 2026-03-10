# User Interactions

Testing click handlers, toggles, and stateful interactions.

```tsx
import { render } from "vitest-browser-react";
import { page } from "vitest/browser";
import { describe, expect, test } from "vitest";
import { Counter } from "./counter";

describe("Counter", () => {
  test("starts at zero", async () => {
    await render(<Counter />);
    await expect.element(page.getByText("Count: 0")).toBeInTheDocument();
  });

  test("increments on click", async () => {
    await render(<Counter />);

    await page.getByRole("button", { name: "Increment" }).click();
    await expect.element(page.getByText("Count: 1")).toBeInTheDocument();
  });

  test("decrements on click", async () => {
    await render(<Counter initialCount={5} />);

    await page.getByRole("button", { name: "Decrement" }).click();
    await expect.element(page.getByText("Count: 4")).toBeInTheDocument();
  });
});
```
