# Layout route

Layout routes use pathless file names prefixed with `_` and render `<Outlet />` to display child routes.

## Route — `src/routes/_dashboard.tsx`

```tsx
import { createFileRoute, Outlet } from "@tanstack/react-router";

export const Route = createFileRoute("/_dashboard")({
  component: RouteComponent,
});

function RouteComponent() {
  return (
    <div className="flex min-h-svh">
      <nav className="w-64 border-r p-4" aria-label="Dashboard navigation">
        <ul className="space-y-2">
          <li>Overview</li>
          <li>Settings</li>
        </ul>
      </nav>
      <main className="flex-1 p-6">
        <Outlet />
      </main>
    </div>
  );
}
```

## Test — `src/routes/_dashboard.browser.test.tsx`

Layout components render `<Outlet />` which needs a router to resolve. Extract the component and test it through `renderRoute`. The `Outlet` will be empty since no child route is mounted, but we can verify the layout structure.

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { Route } = await import("./_dashboard");
const { renderRoute } = await import("@/test/router");

const LayoutComponent = Route.options.component as () => React.ReactNode;

describe("DashboardLayout", () => {
  test("renders navigation sidebar", async () => {
    await renderRoute({ component: LayoutComponent });
    await expect
      .element(page.getByRole("navigation", { name: "Dashboard navigation" }))
      .toBeVisible();
  });

  test("renders navigation items", async () => {
    await renderRoute({ component: LayoutComponent });
    await expect.element(page.getByText("Overview")).toBeVisible();
    await expect.element(page.getByText("Settings")).toBeVisible();
  });

  test("renders main content area", async () => {
    await renderRoute({ component: LayoutComponent });
    await expect.element(page.getByRole("main")).toBeVisible();
  });
});
```
