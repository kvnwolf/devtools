Every route MUST have a corresponding browser test file. No exceptions.

## File conventions

| Route file | Test file |
|------------|-----------|
| `src/routes/index.tsx` | `src/routes/index.browser.test.tsx` |
| `src/routes/about.tsx` | `src/routes/about.browser.test.tsx` |
| `src/routes/items/$itemId.tsx` | `src/routes/items/$itemId.browser.test.tsx` |
| `src/routes/_layout.tsx` | `src/routes/_layout.browser.test.tsx` |

## Step 1: Create the route

Use `createFileRoute` with the path matching the file location. Define a named function component — never export default or inline.

```tsx
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/about")({
  component: RouteComponent,
});

function RouteComponent() {
  return <div>About</div>;
}
```

For routes with loaders, add a `loader` option and access data via `Route.useLoaderData()`:

```tsx
export const Route = createFileRoute("/items")({
  loader: () => getItems(),
  component: RouteComponent,
});

function RouteComponent() {
  const items = Route.useLoaderData();
  return <ul>{items.map((i) => <li key={i.id}>{i.name}</li>)}</ul>;
}
```

## Step 2: Create the test

Use the `renderRoute` utility from `src/test/router.tsx`. Extract the component from `Route.options.component` — never pass the `Route` export directly (causes duplicate route ID conflicts with `createFileRoute`).

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { Route } = await import("./about");
const { renderRoute } = await import("@/test/router");

const AboutComponent = Route.options.component as () => React.ReactNode;

describe("AboutRoute", () => {
  test("renders about content", async () => {
    await renderRoute({ component: AboutComponent });
    await expect.element(page.getByText("About")).toBeVisible();
  });
});
```

### Testing routes with loaders

Mock the server function that the loader calls. The shared browser setup already mocks `@/routeTree.gen`, SSR query integration, env, theme, and CSS — only mock what's specific to your route.

```tsx
import { describe, expect, test, vi } from "vitest";
import { page } from "vitest/browser";

vi.mock("@/services/items", () => ({
  getItems: vi.fn(() => [
    { id: "1", name: "Item 1" },
    { id: "2", name: "Item 2" },
  ]),
}));

const { Route } = await import("./items");
const { renderRoute } = await import("@/test/router");

const ItemsComponent = Route.options.component as () => React.ReactNode;

describe("ItemsRoute", () => {
  test("renders item list", async () => {
    await renderRoute({ component: ItemsComponent });
    await expect.element(page.getByText("Item 1")).toBeVisible();
    await expect.element(page.getByText("Item 2")).toBeVisible();
  });
});
```

### Testing layout routes

Layout routes use `Outlet` to render children. Pass a `component` that serves as the child content, and set `initialPath` to match the layout's path.

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { Route } = await import("./_dashboard");
const { renderRoute } = await import("@/test/router");

const LayoutComponent = Route.options.component as () => React.ReactNode;

describe("DashboardLayout", () => {
  test("renders sidebar", async () => {
    await renderRoute({ component: LayoutComponent });
    await expect.element(page.getByRole("navigation")).toBeVisible();
  });
});
```

### Testing the root route

The root route has special considerations:

- `head()` — pure function, test with synchronous assertions
- `shellComponent` — SSR-only, not rendered by `RouterProvider`. Test with direct `render()` from `vitest-browser-react`
- `component` — typically just `<Outlet />`, tested implicitly through child routes

See `examples/root-route.md` for a complete test.

## Key constraints

- **Duplicate route IDs**: `createFileRoute` routes have internal IDs. Adding them to a different root route causes "Duplicate routes found with id" errors. Always extract via `Route.options.component`.
- **Shared mocks**: `src/test/browser.setup.ts` provides global mocks. Only add per-file mocks for route-specific dependencies (server functions, services).
- **`renderRoute` options**: `component` for extracted components, `initialPath` for testing not-found behavior, `route` for custom `createRoute` instances.
- **`shellComponent`**: Not rendered by `RouterProvider`. Use direct `render()` with mocked `HeadContent`/`Scripts`.
- **Dynamic imports**: Use `await import(...)` for the module under test so `vi.mock` declarations apply before the module loads.

## Testing patterns by route type

| Route type | What to test | Example |
|------------|-------------|---------|
| Simple page | Heading, key elements visible | `examples/simple-route.md` |
| Route with loader | Mocked data renders correctly | `examples/route-with-loader.md` |
| Layout route | Navigation, sidebar, Outlet children | `examples/layout-route.md` |
| Root route | `head()` meta, shell hydration, conditional devtools | `examples/root-route.md` |
| Route with params | Param-dependent content renders | `examples/route-with-params.md` |

## Acceptance checklist

- [ ] Route file created with `createFileRoute` and named component function
- [ ] Browser test file created as `*.browser.test.tsx` next to route file
- [ ] Component extracted via `Route.options.component` (not `Route` directly)
- [ ] `renderRoute` utility used for rendering (except `shellComponent`)
- [ ] Route-specific mocks added per-file, shared mocks left to `browser.setup.ts`
- [ ] Dynamic `await import(...)` used for module under test
- [ ] Route tree regenerated if needed (`vite build`)
- [ ] `make validate` passes
