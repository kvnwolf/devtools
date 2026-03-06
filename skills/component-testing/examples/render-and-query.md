# Render and Query

Basic component rendering with role and text queries.

```tsx
import { render } from "vitest-browser-react";
import { page } from "vitest/browser";
import { describe, expect, test } from "vitest";
import { Welcome } from "./welcome";

describe("Welcome", () => {
  test("renders greeting with user name", async () => {
    await render(<Welcome name="Alice" />);
    await expect.element(page.getByRole("heading")).toHaveTextContent("Hello, Alice");
  });

  test("renders default greeting without name", async () => {
    await render(<Welcome />);
    await expect.element(page.getByRole("heading")).toHaveTextContent("Hello, stranger");
  });
});
```
