# Auth Setup

Add Better Auth to a TanStack Start + Convex project. Assumes `convex` skill setup is completed.

## Prerequisite: Set environment variables

Follow the `convex` skill's `flows/env-vars/FLOW.md` to add `BETTER_AUTH_SECRET=better-auth-local-secret`.

## Step 1: Install dependencies

```bash
bun add @convex-dev/better-auth better-auth@1.4.9
```

Pin `better-auth@1.4.9` — tested compatible version with `@convex-dev/better-auth`.

## Step 2: Create convex/convex.config.ts

```ts
import betterAuth from "@convex-dev/better-auth/convex.config";
import { defineApp } from "convex/server";

const app = defineApp();
app.use(betterAuth);

export default app;
```

If `convex.config.ts` already exists, just add `app.use(betterAuth)`.

## Step 3: Create convex/auth.config.ts

```ts
import { getAuthConfigProvider } from "@convex-dev/better-auth/auth-config";
import type { AuthConfig } from "convex/server";

export default {
  providers: [getAuthConfigProvider()],
} satisfies AuthConfig;
```

## Step 4: Create convex/auth.ts

```ts
import type { GenericCtx } from "@convex-dev/better-auth";
import { createClient } from "@convex-dev/better-auth";
import { convex } from "@convex-dev/better-auth/plugins";
import { betterAuth } from "better-auth/minimal";
import { components } from "./_generated/api";
import type { DataModel } from "./_generated/dataModel";
import authConfig from "./auth.config";
import { zq } from "./utils";

export const authComponent = createClient<DataModel>(components.betterAuth);

export const { getAuthUser } = authComponent.clientApi();

export function createAuth(ctx: GenericCtx<DataModel>) {
  return betterAuth({
    baseURL: String(process.env.SITE_URL),
    database: authComponent.adapter(ctx),
    plugins: [convex({ authConfig })],
  });
}

export const getCurrentUser = zq({
  args: {},
  handler: async (ctx) => {
    return await authComponent.getAuthUser(ctx);
  },
});
```

## Step 5: Create convex/http.ts

```ts
import { httpRouter } from "convex/server";
import { authComponent, createAuth } from "./auth";

const http = httpRouter();
authComponent.registerRoutes(http, createAuth);

export default http;
```

If `http.ts` already exists, just add the `registerRoutes` call.

## Step 6: Create src/lib/auth-client.ts

```ts
import { convexClient } from "@convex-dev/better-auth/client/plugins";
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  plugins: [convexClient()],
});
```

## Step 7: Create src/lib/auth-errors.ts

```ts
import { ConvexError } from "convex/values";

const AUTH_PATTERN = /auth/i;

export function isAuthError(error: unknown) {
  const message =
    (error instanceof ConvexError && error.data) || (error instanceof Error && error.message) || "";
  return AUTH_PATTERN.test(message);
}
```

## Step 8: Create src/lib/auth-server.ts

```ts
import { convexBetterAuthReactStart } from "@convex-dev/better-auth/react-start";
import { isAuthError } from "./auth-errors";
import { env } from "./env";

export const { handler, getToken } = convexBetterAuthReactStart({
  convexUrl: env.VITE_CONVEX_URL,
  convexSiteUrl: env.VITE_CONVEX_SITE_URL,
  jwtCache: { enabled: true, isAuthError },
});
```

## Step 9: Update src/lib/env.ts

Add `VITE_CONVEX_SITE_URL` to client variables:

```ts
client: {
  VITE_CONVEX_URL: z.string().url(),
  VITE_CONVEX_SITE_URL: z.string().url(),
},
```

## Step 10: Create src/routes/api/auth/$.ts

```ts
import { createFileRoute } from "@tanstack/react-router";
import { handler } from "@/lib/auth-server";

export const Route = createFileRoute("/api/auth/$")({
  server: {
    handlers: {
      GET: ({ request }) => handler(request),
      POST: ({ request }) => handler(request),
    },
  },
});
```

## Step 11: Create src/components/client-auth-boundary.tsx

```tsx
import { api } from "@convex";
import { AuthBoundary } from "@convex-dev/better-auth/react";
import { useNavigate } from "@tanstack/react-router";
import { authClient } from "@/lib/auth-client";
import { isAuthError } from "@/lib/auth-errors";

export function ClientAuthBoundary({ children }: React.PropsWithChildren) {
  const navigate = useNavigate();
  return (
    <AuthBoundary
      authClient={authClient}
      getAuthUserFn={api.auth.getAuthUser}
      isAuthError={isAuthError}
      onUnauth={() => navigate({ to: "/login" })}
    >
      {children}
    </AuthBoundary>
  );
}
```

## Step 12: Update vite.config.ts

Add SSR bundling:

```ts
export default defineConfig({
  ssr: {
    noExternal: ["@convex-dev/better-auth"],
  },
});
```

## Step 13: Update src/router.tsx

1. Add `expectAuth: true` to `ConvexQueryClient`:

```ts
const convexQueryClient = new ConvexQueryClient(env.VITE_CONVEX_URL, {
  expectAuth: true,
});
```

2. Add `convexQueryClient` to the router context:

```ts
const router = createRouter({
  // ...
  context: { queryClient, convexQueryClient },
});
```

## Step 14: Update src/routes/__root.tsx

Replace `ConvexProvider` with `ConvexBetterAuthProvider`. Add SSR token:

```tsx
import { ConvexBetterAuthProvider } from "@convex-dev/better-auth/react";
import type { ConvexQueryClient } from "@convex-dev/react-query";
import type { QueryClient } from "@tanstack/react-query";
import { createServerFn } from "@tanstack/react-start";
import { authClient } from "@/lib/auth-client";
import { getToken } from "@/lib/auth-server";

const getAuth = createServerFn({ method: "GET" }).handler(async () => {
  return await getToken();
});

export const Route = createRootRouteWithContext<{
  queryClient: QueryClient;
  convexQueryClient: ConvexQueryClient;
}>()({
  beforeLoad: async (ctx) => {
    const token = await getAuth();
    if (token) {
      ctx.context.convexQueryClient.serverHttpClient?.setAuth(token);
    }
    return { isAuthenticated: !!token, token };
  },
  component: RootComponent,
});

function RootComponent() {
  const { convexQueryClient, token } = useRouteContext({ from: Route.id });

  return (
    <ConvexBetterAuthProvider
      authClient={authClient}
      client={convexQueryClient.convexClient}
      initialToken={token}
    >
      <Outlet />
    </ConvexBetterAuthProvider>
  );
}
```

## Step 15: Create src/routes/_authed/route.tsx

Auth layout guard. All authenticated routes go inside `src/routes/_authed/`.

```tsx
import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { ClientAuthBoundary } from "@/components/client-auth-boundary";

export const Route = createFileRoute("/_authed")({
  beforeLoad: ({ context }) => {
    if (!context.isAuthenticated) {
      throw redirect({ to: "/login" });
    }
  },
  component: () => (
    <ClientAuthBoundary>
      <Outlet />
    </ClientAuthBoundary>
  ),
});
```

Move existing `src/routes/index.tsx` to `src/routes/_authed/index.tsx`.

## Step 16: Create src/services/auth.ts

```ts
import { api } from "@convex";
import { convexQuery } from "@convex-dev/react-query";
import { authClient } from "@/lib/auth-client";

export function getCurrentUser() {
  return convexQuery(api.auth.getCurrentUser, {});
}

export async function logout() {
  await authClient.signOut({
    fetchOptions: {
      onSuccess: () => {
        location.reload();
      },
    },
  });
}
```

## Step 17: Create the login page

```bash
bunx shadcn@latest add card skeleton
```

Create `src/routes/login.tsx` with a slot-based `LoginContext`. Auth method skills (email OTP, GitHub, Google) place their components inside `CardContent` and use `LoginContext` to transition between steps.

```tsx
import { createFileRoute, redirect } from "@tanstack/react-router";
import { createContext, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export const Route = createFileRoute("/login")({
  beforeLoad: ({ context }) => {
    if (context.isAuthenticated) {
      throw redirect({ to: "/" });
    }
  },
  component: LoginPage,
});

type Slot = React.ReactNode | null | undefined;

export const LoginContext = createContext({
  setTitle: (_value: Slot) => {
    return;
  },
  setDescription: (_value: Slot) => {
    return;
  },
  setContent: (_value: Slot) => {
    return;
  },
});

function LoginPage() {
  const [title, setTitle] = useState<Slot>(undefined);
  const [description, setDescription] = useState<Slot>(undefined);
  const [content, setContent] = useState<Slot>(undefined);

  return (
    <LoginContext.Provider value={{ setTitle, setDescription, setContent }}>
      <div className="grid min-h-svh place-items-center px-4">
        <Card className="w-full max-w-sm">
          {(title !== null || description !== null) && (
            <CardHeader>
              {title !== null && <CardTitle>{title || "Welcome back"}</CardTitle>}
              {description !== null && (
                <CardDescription>
                  {description || "Sign in to your account to continue"}
                </CardDescription>
              )}
            </CardHeader>
          )}
          {content !== null && (
            <CardContent>
              {content || (
                // biome-ignore lint/complexity/noUselessFragments: placeholder for auth method components
                <>
                  {/* Auth method components go here */}
                </>
              )}
            </CardContent>
          )}
        </Card>
      </div>
    </LoginContext.Provider>
  );
}
```

Slot convention: `undefined` = show default, `null` = hide, any other value = replace.

## Step 18: Update scripts/setup.ts

Add `BETTER_AUTH_SECRET` to the `envVars` array in `scripts/setup.ts`. Add a `seedDatabase` step after `setupConvexEnvVars`:

```ts
async function seedDatabase() {
  await $`npx convex run init`.quiet();
  console.log("Database seeded");
}
```

## Step 19: Update CI env vars

Add to the CI workflow's `env` block:

```yaml
env:
  SITE_URL: http://localhost:3000
  BETTER_AUTH_SECRET: better-auth-local-secret
  CONVEX_AGENT_MODE: anonymous
```

## Step 20: Create e2e/seeds/user.json

```json
{
  "name": "Test User",
  "email": "e2e@example.com"
}
```

## Step 21: Create convex/init.ts

Idempotent seed — creates a test user via the Better Auth component adapter. Uses `zia` (internal action).

```ts
import userSeed from "../e2e/seeds/user.json";
import { components } from "./_generated/api";
import { zia } from "./utils";

const seed = zia({
  args: {},
  handler: async (ctx) => {
    const existing = await ctx.runQuery(
      components.betterAuth.adapter.findOne,
      {
        model: "user" as const,
        where: [
          {
            field: "email",
            operator: "eq" as const,
            value: userSeed.email,
          },
        ],
      }
    );

    if (existing) {
      console.log(`[seed] User already exists: ${userSeed.email}`);
      return;
    }

    await ctx.runMutation(components.betterAuth.adapter.create, {
      input: {
        model: "user" as const,
        data: {
          name: userSeed.name,
          email: userSeed.email,
          emailVerified: true,
          createdAt: Date.now(),
          updatedAt: Date.now(),
        },
      },
    });

    console.log(`[seed] User created: ${userSeed.email}`);
  },
});

export default seed;
```

- Better Auth timestamps are `number` (epoch ms), not ISO strings
- `as const` on model names satisfies the adapter's literal type constraints
- Exported as `default` so it runs with `npx convex run init`

## Step 22: Run make setup

Run `make setup` to propagate environment variables to Convex and seed the database.

## Acceptance checklist

- [ ] Dependencies installed (pinned better-auth version)
- [ ] convex/convex.config.ts registers Better Auth component
- [ ] convex/auth.config.ts, convex/auth.ts, convex/http.ts created
- [ ] src/lib auth files created (auth-client, auth-errors, auth-server)
- [ ] src/lib/env.ts has VITE_CONVEX_SITE_URL
- [ ] API route proxy at src/routes/api/auth/$.ts
- [ ] ClientAuthBoundary component created
- [ ] vite.config.ts, router.tsx, __root.tsx updated
- [ ] _authed route layout created, index moved
- [ ] services/auth.ts created
- [ ] Login page with LoginContext slot system
- [ ] Environment variables set, scripts/setup.ts updated
- [ ] e2e/seeds/user.json and convex/init.ts created
- [ ] CI env vars updated
