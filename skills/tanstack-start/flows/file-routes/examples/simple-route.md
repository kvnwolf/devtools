# Simple route

## Route — `src/routes/about.tsx`

```tsx
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/about")({
  component: RouteComponent,
});

function RouteComponent() {
  return (
    <main className="grid min-h-svh place-items-center px-4">
      <div className="max-w-2xl space-y-4">
        <h1 className="text-4xl font-bold">About</h1>
        <p>This is the about page.</p>
      </div>
    </main>
  );
}
```

## Test — `src/routes/about.browser.test.tsx`

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { Route } = await import("./about");
const { renderRoute } = await import("@/test/router");

const AboutComponent = Route.options.component as () => React.ReactNode;

describe("AboutRoute", () => {
  test("renders heading", async () => {
    await renderRoute({ component: AboutComponent });
    await expect.element(page.getByRole("heading", { name: "About" })).toBeVisible();
  });

  test("renders description", async () => {
    await renderRoute({ component: AboutComponent });
    await expect.element(page.getByText("This is the about page.")).toBeVisible();
  });
});
```
