# Local Install

Migrate from the default component-based Better Auth install to a local install. Gives full control over the Better Auth schema and enables plugins that modify database tables (admin, organizations).

## Step 1: Create convex/betterAuth/convex.config.ts

```ts
import { defineComponent } from "convex/server";

const component = defineComponent("betterAuth");

export default component;
```

Replaces the pre-built component from `@convex-dev/better-auth/convex.config`.

## Step 2: Update convex/auth.ts

Split `createAuth` into `createAuthOptions` + `createAuth`. Add local schema to `createClient`:

```ts
import type { GenericCtx } from "@convex-dev/better-auth";
import { createClient } from "@convex-dev/better-auth";
import { convex } from "@convex-dev/better-auth/plugins";
import type { BetterAuthOptions } from "better-auth";
import { betterAuth } from "better-auth/minimal";
import { components } from "./_generated/api";
import type { DataModel } from "./_generated/dataModel";
import authConfig from "./auth.config";
import authSchema from "./betterAuth/schema";
import { zq } from "./utils";

export const authComponent = createClient<DataModel, typeof authSchema>(
  components.betterAuth,
  { local: { schema: authSchema } },
);

export const { getAuthUser } = authComponent.clientApi();

export function createAuthOptions(ctx: GenericCtx<DataModel>) {
  return {
    baseURL: String(process.env.SITE_URL),
    database: authComponent.adapter(ctx),
    plugins: [convex({ authConfig })],
  } satisfies BetterAuthOptions;
}

export function createAuth(ctx: GenericCtx<DataModel>) {
  return betterAuth(createAuthOptions(ctx));
}

export const getCurrentUser = zq({
  args: {},
  handler: async (ctx) => {
    return await authComponent.getAuthUser(ctx);
  },
});
```

Changes from the default install:
- `createClient` receives the local schema as second type parameter and option
- `createAuthOptions` extracted as named export (used by the adapter)
- `createAuth` delegates to `createAuthOptions`

## Step 3: Create convex/betterAuth/auth.ts

```ts
import { createAuth } from "../auth";

// biome-ignore lint/suspicious/noExplicitAny: Better Auth CLI requires a static export but this file is never called at runtime
export const auth = createAuth({} as any);
```

Entry point for the Better Auth CLI to introspect the config and generate the schema. Never called at runtime.

## Step 4: Generate the schema

```bash
cd convex/betterAuth && bunx @better-auth/cli generate -y
```

Creates `convex/betterAuth/schema.ts`. Re-run whenever plugins or schema-affecting options change.

## Step 5: Create convex/betterAuth/adapter.ts

```ts
import { createApi } from "@convex-dev/better-auth";
import { createAuthOptions } from "../auth";
import schema from "./schema";

export const {
  create,
  findOne,
  findMany,
  updateOne,
  updateMany,
  deleteOne,
  deleteMany,
} = createApi(schema, createAuthOptions);
```

These functions are internal Convex mutations/queries called by the Better Auth component. Never exposed to the internet.

## Step 6: Update convex/convex.config.ts

Change the import path from the package to the local component:

```ts
import { defineApp } from "convex/server";
import betterAuth from "./betterAuth/convex.config";

const app = defineApp();
app.use(betterAuth);

export default app;
```

## Acceptance checklist

- [ ] convex/betterAuth/convex.config.ts created
- [ ] convex/auth.ts split into createAuthOptions + createAuth with local schema
- [ ] convex/betterAuth/auth.ts created (CLI entry point)
- [ ] Schema generated with `bunx @better-auth/cli generate -y`
- [ ] convex/betterAuth/adapter.ts created
- [ ] convex/convex.config.ts imports from local component
