# Root route

The root route (`__root.tsx`) has a unique structure with `head()`, `component`, and `shellComponent`. Each requires a different testing approach.

## Test — `src/routes/__root.browser.test.tsx`

```tsx
import { afterEach, describe, expect, test, vi } from "vitest";
import { page } from "vitest/browser";
import { render } from "vitest-browser-react";

// Mock SSR-specific components that don't work outside the server
vi.mock("@tanstack/react-router", async (importOriginal) => {
  const mod = await importOriginal<typeof import("@tanstack/react-router")>();
  return {
    ...mod,
    HeadContent: () => null,
    Scripts: () => null,
  };
});

vi.mock("@/components/devtools", () => ({
  Devtools: () => <div data-testid="devtools">devtools</div>,
}));

const { env } = await import("@/lib/env");
const { Route } = await import("./__root");

// Monkey-patch useRouteContext since there's no real router for shell tests
Route.useRouteContext = (() => ({ theme: "auto" })) as typeof Route.useRouteContext;

const head = Route.options.head as () => { meta: unknown[]; links: unknown[] };

// shellComponent is not in the public type — double cast to access
const ShellComponent = (Route.options as unknown as Record<string, unknown>)
  .shellComponent as React.ComponentType<{
  children: React.ReactNode;
}>;

afterEach(() => {
  delete document.body.dataset.hydrated;
  (env as { DEV: boolean }).DEV = false;
});

// head() is a pure function — test with synchronous assertions
describe("Route head", () => {
  test("returns charset meta", () => {
    expect(head().meta).toContainEqual({ charSet: "utf-8" });
  });

  test("returns viewport meta", () => {
    expect(head().meta).toContainEqual({
      name: "viewport",
      content: "width=device-width, initial-scale=1",
    });
  });

  test("returns title", () => {
    expect(head().meta).toContainEqual({ title: "<AppName>" });
  });

  test("links the app stylesheet", () => {
    expect(head().links).toContainEqual({ rel: "stylesheet", href: "/app.css" });
  });
});

// shellComponent is SSR-only — use direct render(), not renderRoute()
describe("RootDocument", () => {
  test("sets data-hydrated on body after mount", async () => {
    await render(
      <ShellComponent>
        <div>content</div>
      </ShellComponent>
    );
    expect(document.body.dataset.hydrated).toBe("");
  });

  test("does not render devtools when DEV is false", async () => {
    await render(
      <ShellComponent>
        <div>content</div>
      </ShellComponent>
    );
    expect(page.getByTestId("devtools").elements()).toHaveLength(0);
  });

  test("renders devtools when DEV is true", async () => {
    (env as { DEV: boolean }).DEV = true;
    await render(
      <ShellComponent>
        <div>content</div>
      </ShellComponent>
    );
    await expect.element(page.getByTestId("devtools")).toBeInTheDocument();
  });

  test("renders children", async () => {
    await render(
      <ShellComponent>
        <div>child content</div>
      </ShellComponent>
    );
    await expect.element(page.getByText("child content")).toBeVisible();
  });
});
```

## Key patterns

- `head()` — pure function, no rendering needed
- `shellComponent` — direct `render()` because `RouterProvider` doesn't render it
- `HeadContent`/`Scripts` — mock to `() => null` (they depend on SSR context)
- `Route.useRouteContext` — monkey-patch since no router provides context
- `env.DEV` — cast and mutate to test conditional devtools rendering
- `document.body.dataset.hydrated` — clean up in `afterEach`
