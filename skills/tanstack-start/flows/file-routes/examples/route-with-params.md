# Route with params

Dynamic segments use `$paramName` in the file name. Access params via `Route.useParams()`.

## Route — `src/routes/items/$itemId.tsx`

```tsx
import { createFileRoute } from "@tanstack/react-router";
import { getItem } from "@/services/items";

export const Route = createFileRoute("/items/$itemId")({
  loader: ({ params }) => getItem({ data: { id: params.itemId } }),
  component: RouteComponent,
});

function RouteComponent() {
  const item = Route.useLoaderData();

  return (
    <article>
      <h1 className="text-2xl font-bold">{item.name}</h1>
      <p>{item.description}</p>
    </article>
  );
}
```

## Test — `src/routes/items/$itemId.browser.test.tsx`

Mock `Route.useLoaderData` to provide a specific item. The param value doesn't matter since we bypass the loader.

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { Route } = await import("./$itemId");
const { renderRoute } = await import("@/test/router");

const ItemComponent = Route.options.component as () => React.ReactNode;

describe("ItemDetailRoute", () => {
  test("renders item name as heading", async () => {
    Route.useLoaderData = (() => ({
      id: "abc-123",
      name: "Widget Pro",
      description: "A premium widget.",
    })) as typeof Route.useLoaderData;
    await renderRoute({ component: ItemComponent });
    await expect
      .element(page.getByRole("heading", { name: "Widget Pro" }))
      .toBeVisible();
  });

  test("renders item description", async () => {
    Route.useLoaderData = (() => ({
      id: "abc-123",
      name: "Widget Pro",
      description: "A premium widget.",
    })) as typeof Route.useLoaderData;
    await renderRoute({ component: ItemComponent });
    await expect.element(page.getByText("A premium widget.")).toBeVisible();
  });
});
```
