# Auth Persistence

Login once in a setup file, reuse the session across all tests.

## Setup File

```ts
// e2e/auth.setup.ts
import { test as setup } from "@playwright/test";

const AUTH_FILE = "e2e/.auth/user.json";

setup("authenticate", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill("test@test.com");
  await page.getByLabel("Password").fill("password");
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL("/dashboard");
  await page.context().storageState({ path: AUTH_FILE });
});
```

## Playwright Config

```ts
// playwright.config.ts
export default defineConfig({
  projects: [
    { name: "setup", testMatch: /auth\.setup\.ts/ },
    {
      name: "authenticated",
      dependencies: ["setup"],
      use: { storageState: "e2e/.auth/user.json" },
      testIgnore: /\.unauth\.spec\.ts$/,
    },
    {
      name: "unauthenticated",
      testMatch: /\.unauth\.spec\.ts$/,
    },
  ],
});
```

## Authenticated Tests

Tests in `"authenticated"` automatically have the saved session — no login needed:

```ts
// e2e/dashboard.spec.ts
import { expect } from "@playwright/test";
import { test } from "./utils";

test("authenticated user sees dashboard", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page.getByRole("heading")).toHaveText("Welcome back");
});
```

## Unauthenticated Tests

Use the `.unauth.spec.ts` extension. These run without session state — fresh browser, no cookies:

```ts
// e2e/login.unauth.spec.ts
import { expect } from "@playwright/test";
import { test } from "./utils";

test("redirects unauthenticated user to login", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page).toHaveURL("/login");
});

test("shows login form", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByLabel("Email")).toBeVisible();
  await expect(page.getByLabel("Password")).toBeVisible();
  await expect(page.getByRole("button", { name: "Sign in" })).toBeVisible();
});
```
