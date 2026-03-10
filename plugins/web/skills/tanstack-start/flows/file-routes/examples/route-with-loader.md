# Route with loader

## Server function — `src/services/items.ts`

```ts
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

const itemSchema = z.object({
  id: z.string(),
  name: z.string(),
  status: z.enum(["active", "archived"]),
});

type Item = z.infer<typeof itemSchema>;

export const getItems = createServerFn({ method: "GET" }).handler(
  async (): Promise<Item[]> => {
    // fetch from DB
    return [];
  }
);
```

## Route — `src/routes/items.tsx`

```tsx
import { createFileRoute } from "@tanstack/react-router";
import { getItems } from "@/services/items";

export const Route = createFileRoute("/items")({
  loader: () => getItems(),
  component: RouteComponent,
});

function RouteComponent() {
  const items = Route.useLoaderData();

  if (items.length === 0) {
    return <p>No items found.</p>;
  }

  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  );
}
```

## Test — `src/routes/items.browser.test.tsx`

The loader calls `getItems` on the server — mock the service, not the loader itself.
Since `renderRoute` renders only the component (not the loader), mock `Route.useLoaderData` to provide test data.

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { Route } = await import("./items");
const { renderRoute } = await import("@/test/router");

const ItemsComponent = Route.options.component as () => React.ReactNode;

describe("ItemsRoute", () => {
  test("renders empty state when no items", async () => {
    Route.useLoaderData = (() => []) as typeof Route.useLoaderData;
    await renderRoute({ component: ItemsComponent });
    await expect.element(page.getByText("No items found.")).toBeVisible();
  });

  test("renders item list", async () => {
    Route.useLoaderData = (() => [
      { id: "1", name: "Widget A", status: "active" },
      { id: "2", name: "Widget B", status: "archived" },
    ]) as typeof Route.useLoaderData;
    await renderRoute({ component: ItemsComponent });
    await expect.element(page.getByText("Widget A")).toBeVisible();
    await expect.element(page.getByText("Widget B")).toBeVisible();
  });
});
```

Key pattern: monkey-patch `Route.useLoaderData` to control the data the component receives, since `renderRoute` does not execute loaders.
