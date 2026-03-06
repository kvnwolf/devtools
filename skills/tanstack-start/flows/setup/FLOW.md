## Step 1: Install dependencies

1. Add production dependencies:

```bash
bun add @base-ui/react @tailwindcss/vite @tanstack/react-devtools @tanstack/react-form @tanstack/react-form-devtools @tanstack/react-query @tanstack/react-query-devtools @tanstack/react-router @tanstack/react-router-devtools @tanstack/react-router-ssr-query @tanstack/react-start react react-dom tailwindcss vite-tsconfig-paths
```

2. Add dev dependencies:

```bash
bun add -d @playwright/test @tanstack/devtools-vite @types/react @types/react-dom @vitejs/plugin-react @vitest/browser-playwright nitro vite vitest-browser-react
```

3. Install Playwright browsers:

```bash
bunx playwright install chromium
```

## Step 2: Update package.json

1. Add the following scripts:
   - `build`: `vite build`
   - `dev:vite`: `vite dev`
   - `preview`: `bun .output/server/index.mjs`
   - `e2e`: `playwright test`
2. Add `src/components/ui/**` to `knip.ignore`

## Step 3: Update turbo.json

1. Add the following tasks: `build`, `e2e`, `preview`
2. Add `dev:vite` with `"cache": false` and `"persistent": true`
3. Add `dev` with `"cache": false`, `"persistent": true`, and `"with": ["//#dev:vite"]`
4. `preview` must depend on `build`
5. `e2e` must depend on `build`
6. Add `build` as the first entry and `e2e` after `test` in the `validate` task's `dependsOn` array

## Step 3b: Update Makefile

Add a `dev` target after `setup`:

```makefile
dev:
	bun run turbo dev
```

## Step 3c: Update README.md

Add `3. Run \`make dev\`` to the Development section.

## Step 4: Update tsconfig.json

1. Set `compilerOptions.jsx` to `react-jsx`
2. Set `compilerOptions.lib` to `["dom", "dom.iterable", "esnext"]`
3. Add path alias `@/*` → `./src/*` in `compilerOptions.paths`
4. Add `vite/client` to `compilerOptions.types`
5. Set `include` to `["**/*.ts", "**/*.tsx"]`

## Step 5: Update biome.jsonc

1. Add `ultracite/react` to `extends`
2. Add the following `files` object below `extends`:

```jsonc
"files": {
  "includes": ["**", "!src/components/ui/**"]
}
```

3. Add the following override:

```jsonc
{
  "includes": ["**/$*.ts", "**/$*.tsx"],
  "linter": {
    "rules": {
      "style": {
        "useFilenamingConvention": "off"
      }
    }
  }
}
```

## Step 6: Update .gitignore

Add the following entries:

```
# tanstack
.nitro
.output
.tanstack
.vercel
.vinxi
dist

# playwright
playwright-report
test-results
```

## Step 7: Create vite.config.ts

```ts
import tailwindcss from "@tailwindcss/vite";
import { devtools } from "@tanstack/devtools-vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import viteReact from "@vitejs/plugin-react";
import { nitro } from "nitro/vite";
import { defineConfig } from "vite";
import viteTsConfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  plugins: [devtools(), viteTsConfigPaths(), tailwindcss(), tanstackStart({ router: { routeFileIgnorePattern: "\\.test\\." } }), nitro(), viteReact()],
});
```

## Step 8: Update vitest.config.ts

1. Add the following imports:

```ts
import { playwright } from "@vitest/browser-playwright";
import tailwindcss from "@tailwindcss/vite";
import viteReact from "@vitejs/plugin-react";
import viteTsConfigPaths from "vite-tsconfig-paths";
```

2. Add `viteTsConfigPaths()` to the root `plugins` array
3. Add the following project to `test.projects`:

```ts
{
  extends: true,
  plugins: [viteReact(), tailwindcss()],
  optimizeDeps: {
    exclude: [
      "@tanstack/react-start",
      "@tanstack/start-server-core",
      "@tanstack/start-client-core",
    ],
  },
  test: {
    name: "browser",
    include: ["src/**/*.browser.test.tsx"],
    setupFiles: ["src/test/browser.setup.ts"],
    browser: {
      provider: playwright(),
      enabled: true,
      instances: [{ browser: "chromium" }],
    },
  },
}
```

## Step 9: Create src/test/unit.setup.ts

This setup file mocks `createServerFn` globally for all unit tests, preserving the `inputValidator` pipeline so validation is exercised during tests.

```ts
import { vi } from "vitest";

vi.mock("@tanstack/react-start", () => ({
  createServerFn: () => {
    let validator: { parse: (data: unknown) => unknown } | undefined;

    const builder = {
      inputValidator: (v: typeof validator) => {
        validator = v;
        return builder;
      },
      handler: (fn: (opts: { data: unknown }) => unknown) => {
        return (opts?: { data?: unknown }) => {
          let data = opts?.data;
          if (validator) {
            data = validator.parse(data);
          }
          return fn({ data });
        };
      },
    };

    return builder;
  },
}));
```

Then add `setupFiles: ["src/test/unit.setup.ts"]` to the `unit` project's `test` config in `vitest.config.ts`.

## Step 9b: Create src/test/browser.setup.ts

This setup file provides shared mocks for all browser tests, avoiding repetition across test files. It mocks SSR-only modules, the generated route tree, CSS imports, env, and theme.

```ts
import { vi } from "vitest";

vi.mock("@tanstack/react-router-ssr-query", () => ({
  setupRouterSsrQueryIntegration: vi.fn(),
}));

vi.mock("@/routeTree.gen", async () => {
  const { createRootRoute, Outlet } = await import("@tanstack/react-router");
  return {
    routeTree: createRootRoute({
      component: Outlet,
      beforeLoad: () => ({ theme: "auto" as const }),
    }),
  };
});

vi.mock("@/styles/app.css?url", () => ({ default: "/app.css" }));

vi.mock("@/lib/env", () => ({
  env: { DEV: false },
}));

vi.mock("@/lib/theme", () => ({
  getTheme: vi.fn(() => "auto"),
  setTheme: vi.fn(() => Promise.resolve()),
  THEME_VALUES: ["light", "dark", "auto"] as const,
  themeSchema: { parse: (v: string) => v },
}));
```

## Step 9c: Create src/test/router.tsx

Reusable test utility for rendering routes with the project's real router config. Uses `createMemoryHistory` for in-memory navigation and spreads `getRouter()` options to inherit error/404 components and other defaults.

```tsx
import type { AnyRoute } from "@tanstack/react-router";
import {
  createMemoryHistory,
  createRoute,
  createRouter,
  RouterProvider,
} from "@tanstack/react-router";
import { render } from "vitest-browser-react";

interface TestRouterOptions {
  /** Override the default route's component (ignored when `route` is provided) */
  component?: () => React.ReactNode;
  /** Initial URL path. Defaults to "/" */
  initialPath?: string;
  /** Route to test. Pass the `Route` export from a route file. */
  route?: AnyRoute;
}

async function createTestRouter(options: TestRouterOptions = {}) {
  const { initialPath = "/", route, component } = options;
  const { getRouter } = await import("@/router");
  const projectRouter = getRouter();
  const { routeTree } = projectRouter;

  if (route) {
    routeTree.addChildren([route]);
  } else if (component) {
    routeTree.addChildren([
      createRoute({
        getParentRoute: () => routeTree,
        path: "/",
        component,
      }),
    ]);
  }

  return createRouter({
    ...projectRouter.options,
    routeTree,
    history: createMemoryHistory({ initialEntries: [initialPath] }),
    defaultPendingMinMs: 0,
  });
}

export async function renderRoute(options: TestRouterOptions = {}) {
  const router = await createTestRouter(options);
  const result = await render(<RouterProvider router={router} />);
  return { router, ...result };
}
```

**Important notes:**
- `createFileRoute` routes have internal IDs that conflict when added to different root routes ("Duplicate routes found with id"). Use `Route.options.component` to extract the component instead of passing the `Route` directly.
- `shellComponent` is SSR-only and not rendered by `RouterProvider`. Test it with direct `render()` instead of `renderRoute()`.

## Step 10: Create playwright.config.ts

```ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  use: {
    baseURL: "http://localhost:3000",
  },
  webServer: {
    command: "bun .output/server/index.mjs",
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

## Step 11: Create e2e/utils.ts

```ts
import { test as base } from "@playwright/test";

export const test = base.extend({
  page: async ({ page }, use) => {
    const originalGoto = page.goto.bind(page);
    page.goto = async (...args) => {
      const result = await originalGoto(...args);
      await page.waitForSelector("[data-hydrated]", { timeout: 10_000 });
      return result;
    };
    await use(page);
  },
});
```

## Step 12: Update src/lib/env.ts

1. Run the `/environment-variables` skill to configure env
2. Add `client: {}` to `createEnv`
3. Add `clientPrefix: "VITE_"` to `createEnv`
4. Update `runtimeEnv` to `{ ...process.env, ...import.meta.env }`
5. Add `DEV: z.boolean()` to `shared`

## Step 13: Update src/lib/env.test.ts

Add the following test:

```ts
test("DEV is a boolean", () => {
  expect(typeof env.DEV).toBe("boolean");
});
```

## Step 14: Set up shadcn/ui

1. Ask the user for their shadcn preset URL (configured at `ui.shadcn.com/create`)
2. Scaffold a temp project to extract config files:

```bash
rm -rf .tmp && mkdir .tmp && bunx --bun shadcn@latest create tmp -p "<preset-url>" -t vite -c .tmp
```

3. From `.tmp/tmp/`, extract:
   - `components.json` → copy to project root, update `tailwind.css` path to `src/styles/app.css`
   - `src/index.css` → copy to `src/styles/app.css`
   - `src/lib/utils.ts` → copy to `src/lib/utils.ts` if `cn()` doesn't exist yet
   - `package.json` → read to identify new dependencies, install them with `bun add`
4. Clean up:

```bash
rm -rf .tmp
```

5. Install base components:

```bash
bunx --bun shadcn@latest add button empty label
```

## Step 14b: Create src/lib/utils.test.ts

```ts
import { describe, expect, test } from "vitest";
import { cn } from "./utils";

describe("cn", () => {
  test("merges class names", () => {
    expect(cn("foo", "bar")).toBe("foo bar");
  });

  test("handles conditional classes", () => {
    expect(cn("foo", false, "baz")).toBe("foo baz");
  });

  test("deduplicates tailwind classes", () => {
    expect(cn("px-2", "px-4")).toBe("px-4");
  });

  test("returns empty string for no inputs", () => {
    expect(cn()).toBe("");
  });
});
```

## Step 15: Set up dark mode in src/styles/app.css

1. Replace the `@custom-variant dark` line with:

```css
@custom-variant dark {
  &:is(.dark *) {
    @slot;
  }

  @media (prefers-color-scheme: dark) {
    &:is(.auto *) {
      @slot;
    }
  }
}
```

2. Add these classes right after the `@custom-variant` block:

```css
.light {
  color-scheme: light;
}

.dark {
  color-scheme: dark;
}

.auto {
  color-scheme: light dark;
}
```

3. Merge the `:root` and `.dark` blocks into a single `:root` block using `light-dark()`:

```css
/* Before */
:root {
  --background: oklch(1 0 0);
}

.dark {
  --background: oklch(0.145 0 0);
}

/* After */
:root {
  --background: light-dark(oklch(1 0 0), oklch(0.145 0 0));
}
```

4. Delete the `.dark { ... }` block entirely

## Step 16: Create src/lib/theme.ts

```ts
import { createServerFn } from "@tanstack/react-start";
import { getCookie, setCookie } from "@tanstack/react-start/server";
import { z } from "zod";

const STORAGE_KEY = "app-theme";

export const THEME_VALUES = ["light", "dark", "auto"] as const;
export const themeSchema = z.enum(THEME_VALUES);

export const getTheme = createServerFn().handler(() => {
  return themeSchema.parse(getCookie(STORAGE_KEY) ?? "auto");
});

export const setTheme = createServerFn()
  .inputValidator(themeSchema)
  .handler(({ data }) => setCookie(STORAGE_KEY, data));
```

## Step 17: Create src/lib/theme.test.ts

```ts
import { afterEach, describe, expect, test, vi } from "vitest";

const mockGetCookie = vi.fn<(name: string) => string | undefined>();
const mockSetCookie = vi.fn<(name: string, value: string) => void>();

vi.mock("@tanstack/react-start/server", () => ({
  getCookie: (...args: Parameters<typeof mockGetCookie>) => mockGetCookie(...args),
  setCookie: (...args: Parameters<typeof mockSetCookie>) => mockSetCookie(...args),
}));

const { getTheme, setTheme, themeSchema, THEME_VALUES } = await import("./theme");

afterEach(() => {
  vi.clearAllMocks();
});

describe("themeSchema", () => {
  test.each(["light", "dark", "auto"] as const)('accepts "%s"', (value) => {
    expect(themeSchema.parse(value)).toBe(value);
  });

  test.each(["purple", "", "system", 42])('rejects "%s"', (value) => {
    expect(() => themeSchema.parse(value)).toThrow();
  });
});

describe("THEME_VALUES", () => {
  test("contains all valid themes", () => {
    expect(THEME_VALUES).toEqual(["light", "dark", "auto"]);
  });
});

describe("getTheme", () => {
  test("returns the theme from the cookie", () => {
    mockGetCookie.mockReturnValue("dark");
    expect(getTheme()).toBe("dark");
  });

  test('defaults to "auto" when no cookie exists', () => {
    mockGetCookie.mockReturnValue(undefined);
    expect(getTheme()).toBe("auto");
  });

  test("throws when cookie has an invalid value", () => {
    mockGetCookie.mockReturnValue("purple");
    expect(() => getTheme()).toThrow();
  });
});

describe("setTheme", () => {
  test.each(["light", "dark", "auto"] as const)('sets cookie to "%s"', (value) => {
    setTheme({ data: value });
    expect(mockSetCookie).toHaveBeenCalledWith("app-theme", value);
  });

  test("rejects invalid theme values", () => {
    expect(() => setTheme({ data: "purple" as never })).toThrow();
    expect(mockSetCookie).not.toHaveBeenCalled();
  });
});
```

## Step 18: Create src/components/form.tsx

```tsx
import { mergeProps } from "@base-ui/react/merge-props";
import { useRender } from "@base-ui/react/use-render";
import {
  type AnyFormApi,
  createFormHook,
  createFormHookContexts,
  useStore,
} from "@tanstack/react-form";
import { Button } from "@/components/ui/button";
import { Field, FieldError, FieldLabel as FieldLabelPrimitive } from "@/components/ui/field";

const { fieldContext, formContext, useFieldContext, useFormContext } = createFormHookContexts();

export const { useAppForm } = createFormHook({
  fieldContext,
  formContext,
  formComponents: {
    Root: FormRoot,
    Submit: FormSubmit,
  },
  fieldComponents: {
    Root: FieldRoot,
    Label: FieldLabel,
    Control: FieldControl,
    ErrorMessage: FieldErrorMessage,
  },
});

function FormRoot({
  form,
  ...props
}: React.ComponentProps<"form"> & {
  form: AnyFormApi & {
    AppForm: React.ComponentType<React.PropsWithChildren>;
  };
}) {
  return (
    <form.AppForm>
      <form
        noValidate
        onSubmit={(e) => {
          e.preventDefault();
          e.stopPropagation();
          form.handleSubmit();
        }}
        {...props}
      />
    </form.AppForm>
  );
}

function FormSubmit(props: Omit<React.ComponentProps<typeof Button>, "disabled" | "type">) {
  const form = useFormContext();
  const [isPristine, canSubmit, isSubmitting] = useStore(form.store, (state) => [
    state.isPristine,
    state.canSubmit,
    state.isSubmitting,
  ]);

  return <Button {...props} disabled={isPristine || !canSubmit || isSubmitting} type="submit" />;
}

function FieldRoot(props: React.ComponentProps<typeof Field>) {
  const field = useFieldContext();
  const isInvalid = field.state.meta.isTouched && !field.state.meta.isValid;
  return <Field data-invalid={isInvalid || undefined} {...props} />;
}

function FieldLabel(props: React.ComponentProps<typeof FieldLabelPrimitive>) {
  const field = useFieldContext();
  return <FieldLabelPrimitive htmlFor={field.name} {...props} />;
}

function FieldControl({ render, ...props }: useRender.ComponentProps<"input">) {
  const form = useFormContext();
  const field = useFieldContext<string>();
  const isSubmitting = useStore(form.store, (state) => state.isSubmitting);
  const isInvalid = field.state.meta.isTouched && !field.state.meta.isValid;

  return useRender({
    render,
    defaultTagName: "input",
    props: mergeProps<"input">(
      {
        id: field.name,
        disabled: isSubmitting,
        "aria-invalid": isInvalid || undefined,
        value: field.state.value,
        onBlur: field.handleBlur,
        onChange: ((eventOrValue: React.ChangeEvent<HTMLInputElement> | string) => {
          const value = typeof eventOrValue === "string" ? eventOrValue : eventOrValue.target.value;
          field.handleChange(value);
        }) as React.ChangeEventHandler<HTMLInputElement>,
      },
      props
    ),
  });
}

function FieldErrorMessage(props: Omit<React.ComponentProps<typeof FieldError>, "errors">) {
  const field = useFieldContext();
  const { errors } = field.state.meta;

  if (errors.length === 0) {
    return null;
  }

  return <FieldError errors={errors} {...props} />;
}
```

## Step 19: Create src/components/form.browser.test.tsx

```tsx
import { page } from "vitest/browser";
import { render } from "vitest-browser-react";
import { expect, test, vi } from "vitest";
import { z } from "zod";
import { useAppForm } from "./form";

function TestForm({ onSubmit = vi.fn() }: { onSubmit?: (data: { email: string }) => void }) {
  const form = useAppForm({
    defaultValues: { email: "" },
    validators: {
      onSubmit: z.object({ email: z.string().email("Invalid email") }),
    },
    onSubmit: ({ value }) => onSubmit(value),
  });

  return (
    <form.Root form={form}>
      <form.AppField name="email">
        {(field) => (
          <field.Root>
            <field.Label>Email</field.Label>
            <field.Control />
            <field.ErrorMessage />
          </field.Root>
        )}
      </form.AppField>
      <form.Submit>Submit</form.Submit>
    </form.Root>
  );
}

test("submit button is disabled when form is pristine", async () => {
  render(<TestForm />);
  await expect.element(page.getByRole("button", { name: "Submit" })).toBeDisabled();
});

test("submit button is enabled after valid input", async () => {
  render(<TestForm />);
  await page.getByLabelText("Email").fill("alice@test.com");
  await expect.element(page.getByRole("button", { name: "Submit" })).toBeEnabled();
});

test("shows error message for invalid input", async () => {
  render(<TestForm />);
  await page.getByLabelText("Email").fill("not-an-email");
  await page.getByRole("button", { name: "Submit" }).click();
  await expect.element(page.getByText("Invalid email")).toBeInTheDocument();
});

test("calls onSubmit with form data", async () => {
  const onSubmit = vi.fn();
  render(<TestForm onSubmit={onSubmit} />);
  await page.getByLabelText("Email").fill("alice@test.com");
  await page.getByRole("button", { name: "Submit" }).click();
  expect(onSubmit).toHaveBeenCalledWith({ email: "alice@test.com" });
});
```

## Step 20: Create src/components/devtools.tsx

```tsx
import { TanStackDevtools } from "@tanstack/react-devtools";
import { formDevtoolsPlugin } from "@tanstack/react-form-devtools";
import { ReactQueryDevtoolsPanel } from "@tanstack/react-query-devtools";
import { TanStackRouterDevtoolsPanel } from "@tanstack/react-router-devtools";

export function Devtools() {
  return (
    <TanStackDevtools
      config={{
        position: "bottom-right",
      }}
      plugins={[
        {
          name: "TanStack Router",
          render: <TanStackRouterDevtoolsPanel />,
        },
        {
          name: "TanStack Query",
          render: <ReactQueryDevtoolsPanel />,
        },
        formDevtoolsPlugin(),
      ]}
    />
  );
}
```

## Step 20b: Create src/components/devtools.browser.test.tsx

```tsx
import { describe, expect, test, vi } from "vitest";
import { page } from "vitest/browser";
import { render } from "vitest-browser-react";

vi.mock("@tanstack/react-devtools", () => ({
  TanStackDevtools: ({
    plugins,
  }: {
    plugins: Array<{ name: string; render: React.ReactNode }>;
  }) => (
    <div data-testid="devtools">
      {plugins.map((p) => (
        <span key={p.name}>{p.name}</span>
      ))}
    </div>
  ),
}));

vi.mock("@tanstack/react-form-devtools", () => ({
  formDevtoolsPlugin: () => ({ name: "TanStack Form", render: <div /> }),
}));

vi.mock("@tanstack/react-query-devtools", () => ({
  ReactQueryDevtoolsPanel: () => <div />,
}));

vi.mock("@tanstack/react-router-devtools", () => ({
  TanStackRouterDevtoolsPanel: () => <div />,
}));

import { Devtools } from "./devtools";

describe("Devtools", () => {
  test("renders devtools container", async () => {
    await render(<Devtools />);
    await expect.element(page.getByTestId("devtools")).toBeInTheDocument();
  });

  test("includes Router plugin", async () => {
    await render(<Devtools />);
    await expect.element(page.getByText("TanStack Router")).toBeInTheDocument();
  });

  test("includes Query plugin", async () => {
    await render(<Devtools />);
    await expect.element(page.getByText("TanStack Query")).toBeInTheDocument();
  });

  test("includes Form plugin", async () => {
    await render(<Devtools />);
    await expect.element(page.getByText("TanStack Form")).toBeInTheDocument();
  });
});
```

## Step 21: Create src/components/theme-toggle.tsx

Import sun, moon, and monitor icons from the icon library configured in `components.json`.

```tsx
import { useRouteContext, useRouter } from "@tanstack/react-router";
import { Monitor, Moon, Sun } from "<icon-library>";
import { setTheme, THEME_VALUES, themeSchema } from "@/lib/theme";
import { Button } from "./ui/button";

export function ThemeToggle(props: React.ComponentProps<typeof Button>) {
  const { theme } = useRouteContext({ from: "__root__" });
  const router = useRouter();

  function toggleTheme() {
    const next =
      THEME_VALUES[(THEME_VALUES.indexOf(theme) + 1) % THEME_VALUES.length];
    setTheme({ data: themeSchema.parse(next) }).then(() =>
      router.invalidate(),
    );
  }

  const THEME_LABELS = {
    light: "Light",
    dark: "Dark",
    auto: "System",
  } as const;

  let Icon = Monitor;
  if (theme === "dark") {
    Icon = Moon;
  } else if (theme === "light") {
    Icon = Sun;
  }

  return (
    <Button
      aria-label="Toggle theme"
      onClick={toggleTheme}
      size="sm"
      variant="outline"
      {...props}
    >
      <Icon />
      {THEME_LABELS[theme]}
    </Button>
  );
}
```

## Step 22: Create src/components/theme-toggle.browser.test.tsx

```tsx
import { page } from "vitest/browser";
import { render } from "vitest-browser-react";
import { expect, test, vi } from "vitest";

const { mockSetTheme, mockInvalidate } = vi.hoisted(() => ({
  mockSetTheme: vi.fn(() => Promise.resolve()),
  mockInvalidate: vi.fn(),
}));

vi.mock("@tanstack/react-router", () => ({
  useRouteContext: vi.fn(() => ({ theme: "auto" })),
  useRouter: vi.fn(() => ({ invalidate: mockInvalidate })),
}));

vi.mock("@/lib/theme", () => ({
  setTheme: mockSetTheme,
  THEME_VALUES: ["light", "dark", "auto"] as const,
  themeSchema: { parse: (v: string) => v },
}));

import { useRouteContext } from "@tanstack/react-router";
import { ThemeToggle } from "./theme-toggle";

test("displays System label for auto theme", async () => {
  render(<ThemeToggle />);
  await expect.element(page.getByRole("button", { name: "Toggle theme" })).toHaveTextContent("System");
});

test("displays Light label for light theme", async () => {
  vi.mocked(useRouteContext).mockReturnValue({ theme: "light" });
  render(<ThemeToggle />);
  await expect.element(page.getByRole("button", { name: "Toggle theme" })).toHaveTextContent("Light");
});

test("displays Dark label for dark theme", async () => {
  vi.mocked(useRouteContext).mockReturnValue({ theme: "dark" });
  render(<ThemeToggle />);
  await expect.element(page.getByRole("button", { name: "Toggle theme" })).toHaveTextContent("Dark");
});

test("calls setTheme on click", async () => {
  vi.mocked(useRouteContext).mockReturnValue({ theme: "auto" });
  render(<ThemeToggle />);
  await page.getByRole("button", { name: "Toggle theme" }).click();
  expect(mockSetTheme).toHaveBeenCalled();
});
```

## Step 23: Create src/routes/__root.tsx

```tsx
import type { QueryClient } from "@tanstack/react-query";
import { createRootRouteWithContext, HeadContent, Outlet, Scripts } from "@tanstack/react-router";
import { lazy, Suspense, useEffect } from "react";
import { env } from "../lib/env";
import { getTheme } from "../lib/theme";
import appCss from "../styles/app.css?url";

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  beforeLoad: async () => ({ theme: await getTheme() }),
  head: () => ({
    meta: [
      {
        charSet: "utf-8",
      },
      {
        name: "viewport",
        content: "width=device-width, initial-scale=1",
      },
      {
        title: "<AppName>",
      },
    ],
    links: [
      {
        rel: "stylesheet",
        href: appCss,
      },
    ],
  }),
  component: RootComponent,
  shellComponent: RootDocument,
});

function RootComponent() {
  return <Outlet />;
}

const Devtools = lazy(() =>
  import("../components/devtools").then((mod) => ({ default: mod.Devtools })),
);

function RootDocument({ children }: { children: React.ReactNode }) {
  const { theme } = Route.useRouteContext();

  useEffect(() => {
    document.body.dataset.hydrated = "";
  }, []);

  return (
    <html className={theme} lang="en">
      <head>
        <HeadContent />
      </head>
      <body className="bg-background font-sans text-foreground antialiased">
        {children}
        {env.DEV && (
          <Suspense>
            <Devtools />
          </Suspense>
        )}
        <Scripts />
      </body>
    </html>
  );
}
```

## Step 23b: Create src/routes/__root.browser.test.tsx

Tests the `head()` pure function and the `shellComponent` (RootDocument) for hydration marker, conditional devtools rendering, and children. The shell is tested with direct `render()` since `RouterProvider` does not render `shellComponent`.

```tsx
import { afterEach, describe, expect, test, vi } from "vitest";
import { page } from "vitest/browser";
import { render } from "vitest-browser-react";

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

Route.useRouteContext = (() => ({ theme: "auto" })) as typeof Route.useRouteContext;

const head = Route.options.head as () => { meta: unknown[]; links: unknown[] };

const ShellComponent = (Route.options as unknown as Record<string, unknown>)
  .shellComponent as React.ComponentType<{
  children: React.ReactNode;
}>;

afterEach(() => {
  delete document.body.dataset.hydrated;
  (env as { DEV: boolean }).DEV = false;
});

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

## Step 24: Create src/routes/index.tsx

```tsx
import { createFileRoute } from "@tanstack/react-router";
import { ThemeToggle } from "../components/theme-toggle";

export const Route = createFileRoute("/")({
  component: RouteComponent,
});

function RouteComponent() {
  return (
    <main className="grid min-h-svh place-items-center">
      <ThemeToggle />
      <h1 className="text-4xl font-bold"><AppName></h1>
    </main>
  );
}
```

## Step 24b: Create src/routes/index.browser.test.tsx

Uses the `renderRoute` utility to test the index route component. Extracts the component from `Route.options.component` to avoid the duplicate route ID conflict from `createFileRoute`.

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { Route } = await import("./index");
const { renderRoute } = await import("@/test/router");

const IndexComponent = Route.options.component as () => React.ReactNode;

describe("IndexRoute", () => {
  test("renders <AppName> heading", async () => {
    await renderRoute({ component: IndexComponent });
    await expect.element(page.getByRole("heading", { name: "<AppName>" })).toBeVisible();
  });

  test("renders theme toggle", async () => {
    await renderRoute({ component: IndexComponent });
    await expect.element(page.getByRole("button", { name: "Toggle theme" })).toBeVisible();
  });
});
```

## Step 25: Generate route tree

Run `vite build` to generate `src/routeTree.gen.ts`. This must happen before creating `src/router.tsx` which imports the generated route tree.

```bash
bunx --bun vite build
```

## Step 26: Create src/router.tsx

```tsx
import { QueryClient } from "@tanstack/react-query";
import { createRouter, type ErrorComponentProps, Link } from "@tanstack/react-router";
import { setupRouterSsrQueryIntegration } from "@tanstack/react-router-ssr-query";
import { Button } from "./components/ui/button";
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "./components/ui/empty";
import { env } from "./lib/env";
import { routeTree } from "./routeTree.gen";

export function getRouter() {
  const queryClient = new QueryClient();

  const router = createRouter({
    routeTree,
    scrollRestoration: true,
    defaultPreload: "intent",
    defaultErrorComponent: DefaultErrorComponent,
    defaultNotFoundComponent: DefaultNotFoundComponent,
    context: { queryClient },
  });

  setupRouterSsrQueryIntegration({
    router,
    queryClient,
  });

  return router;
}

function DefaultErrorComponent({ error }: ErrorComponentProps) {
  return (
    <ErrorLayout
      description={env.DEV ? error.message : "An unexpected error occurred"}
      title="Something went wrong"
    />
  );
}

function DefaultNotFoundComponent() {
  return (
    <ErrorLayout
      description="The page you are looking for does not exist."
      title="Page not found"
    />
  );
}

function ErrorLayout({
  title,
  description,
}: {
  title: React.ReactNode;
  description: React.ReactNode;
}) {
  return (
    <div className="grid min-h-svh place-items-center px-4">
      <Empty className="max-w-lg border">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            {/* Import and render a warning/error icon from the project's icon library */}
          </EmptyMedia>
          <EmptyTitle>{title}</EmptyTitle>
          <EmptyDescription>{description}</EmptyDescription>
        </EmptyHeader>
        <Button nativeButton={false} render={<Link to="/" />}>
          Go home
        </Button>
      </Empty>
    </div>
  );
}

declare module "@tanstack/react-router" {
  interface Register {
    router: ReturnType<typeof getRouter>;
  }
}
```

## Step 26b: Create src/router.browser.test.tsx

Tests `getRouter()` defaults and the `DefaultNotFoundComponent`/`DefaultErrorComponent` using the `renderRoute` utility.

```tsx
import { describe, expect, test } from "vitest";
import { page } from "vitest/browser";

const { getRouter } = await import("./router");
const { renderRoute } = await import("./test/router");

describe("getRouter", () => {
  test("returns a router with expected defaults", () => {
    const router = getRouter();
    expect(router.options.defaultPreload).toBe("intent");
    expect(router.options.scrollRestoration).toBe(true);
  });

  test("includes a queryClient in context", () => {
    const router = getRouter();
    expect(router.options.context).toHaveProperty("queryClient");
  });
});

describe("DefaultNotFoundComponent", () => {
  test("renders not found message for unknown routes", async () => {
    await renderRoute({ initialPath: "/unknown" });
    await expect.element(page.getByText("Page not found")).toBeVisible();
  });

  test("renders go home button", async () => {
    await renderRoute({ initialPath: "/unknown" });
    await expect.element(page.getByRole("button", { name: "Go home" })).toBeVisible();
  });
});

describe("DefaultErrorComponent", () => {
  test("renders error message when a route throws", async () => {
    await renderRoute({
      component: () => {
        throw new Error("boom");
      },
    });
    await expect.element(page.getByText("Something went wrong")).toBeVisible();
  });
});
```

## Step 27: Update .github/workflows/ci.yml

Add a step to install Playwright browsers before `make validate`:

```yaml
- name: Install Playwright browsers
  run: bunx playwright install --with-deps chromium
```

## Step 28: Create e2e/app.spec.ts

```ts
import { expect } from "@playwright/test";
import { test } from "./utils";

test("homepage loads", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading")).toBeVisible();
});

test("theme toggle cycles through modes", async ({ page }) => {
  await page.goto("/");

  const toggle = page.getByRole("button", { name: "Toggle theme" });

  await expect(toggle).toContainText("System");

  await toggle.click();
  await expect(toggle).toContainText("Light");

  await toggle.click();
  await expect(toggle).toContainText("Dark");

  await toggle.click();
  await expect(toggle).toContainText("System");
});
```

## Step 29: Update AGENTS.md

1. Add the following entries to the **Tech Stack** section:

```markdown
- **Framework:** TanStack Start (SSR with Nitro)
- **Routing:** TanStack Router
- **Data fetching:** TanStack Query
- **Forms:** TanStack Form
- **UI:** shadcn/ui (Base UI) + Tailwind CSS v4 + Remixicon
- **Validation:** Zod
- **E2E testing:** Playwright
```

2. Add the following entries to the **Conventions** section:

```markdown
- **Import alias:** `@/*` maps to `./src/*`
- **UI components:** prefer installing shadcn/ui components (`bunx --bun shadcn@latest add <name>`) over building custom ones. Never edit `src/components/ui/` manually.
- **Polymorphic components:** use the `render` prop (Base UI pattern) to change the rendered element, e.g. `<Button render={<Link to="/" />}>`
```

## Acceptance checklist

- [ ] All dependencies installed (production, dev, Playwright browsers)
- [ ] package.json scripts and knip.ignore configured
- [ ] turbo.json tasks (including `e2e` dependsOn `build`), Makefile, and README updated
- [ ] tsconfig.json, biome.jsonc, and .gitignore updated
- [ ] vite.config.ts (with `routeFileIgnorePattern`) and vitest.config.ts created/updated
- [ ] Unit test setup file with createServerFn mock created
- [ ] Browser test setup file with shared mocks created
- [ ] Test router utility (`src/test/router.tsx`) created
- [ ] Playwright config (with `bun .output/server/index.mjs` and `!process.env.CI`) and e2e utils created
- [ ] Environment variables configured with `/environment-variables` skill
- [ ] shadcn/ui scaffolded with preset, base components installed
- [ ] Utils test (`src/lib/utils.test.ts`) created
- [ ] Dark mode with `light-dark()` and `@custom-variant` configured
- [ ] Theme server functions and tests created
- [ ] Form abstraction and browser tests created
- [ ] Devtools component and browser tests created
- [ ] Theme toggle component and browser tests created
- [ ] Root route created with head, shell, hydration marker, and conditional devtools
- [ ] Root route browser test created (head, hydration, devtools, children)
- [ ] Index route and browser test created
- [ ] Route tree generated with `vite build`
- [ ] Router with error/404 components and browser test created
- [ ] CI workflow updated with Playwright install step
- [ ] E2E smoke test created
- [ ] AGENTS.md updated with tech stack and conventions
- [ ] `make validate` passes
