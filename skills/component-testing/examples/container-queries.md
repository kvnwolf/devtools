# Container Queries

Testing DOM structure and attributes that page locators can't reach.

```tsx
import { render } from "vitest-browser-react";
import { page } from "vitest/browser";
import { describe, expect, test } from "vitest";
import { StatusBadge } from "./status-badge";

describe("StatusBadge", () => {
  test("renders with correct data-status attribute", async () => {
    const { container } = await render(<StatusBadge status="active" />);
    expect(container.querySelector("[data-status='active']")).not.toBeNull();
  });

  test("renders with correct aria attributes", async () => {
    const { container } = await render(<StatusBadge status="error" />);
    expect(container.querySelector("[role='alert']")).not.toBeNull();
  });

  test("displays status text", async () => {
    await render(<StatusBadge status="active" />);
    await expect.element(page.getByText("Active")).toBeInTheDocument();
  });
});
```

Use synchronous `expect()` for `container.querySelector()` — plain DOM nodes, not locators.
