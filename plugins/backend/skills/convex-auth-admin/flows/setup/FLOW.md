# Admin Plugin Setup

Add the Better Auth admin plugin for user management: roles, banning, session control, and impersonation.

> **Requires local install.** The admin plugin adds fields to the `user` and `session` tables. If the project is not yet using a local install, follow the `convex-auth` local-install flow first, then return here.

## Step 1: Add the admin plugin to the server

Update `convex/auth.ts` — add `admin` to the plugins array inside `createAuthOptions`:

```ts
import { admin } from "better-auth/plugins";

export function createAuthOptions(ctx: GenericCtx<DataModel>) {
  return {
    baseURL: String(process.env.SITE_URL),
    database: authComponent.adapter(ctx),
    plugins: [
      convex({ authConfig }),
      admin({
        defaultRole: "user",
        adminRoles: ["admin"],
      }),
    ],
  } satisfies BetterAuthOptions;
}
```

Configuration options:

| Option | Default | Description |
|--------|---------|-------------|
| `defaultRole` | `"user"` | Role assigned to new users |
| `adminRoles` | `["admin"]` | Roles that grant admin API access |
| `adminUserIds` | `[]` | User IDs that always have admin access (bypasses role check) |
| `impersonationSessionDuration` | `3600` | Impersonation session lifetime in seconds |
| `defaultBanReason` | `"No reason"` | Default reason when banning without specifying one |
| `defaultBanExpiresIn` | `undefined` | Default ban duration in seconds (`undefined` = permanent) |

## Step 2: Add the admin plugin to the client

Update `src/lib/auth-client.ts`:

```ts
import { convexClient } from "@convex-dev/better-auth/client/plugins";
import { adminClient } from "better-auth/client/plugins";
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  plugins: [convexClient(), adminClient()],
});
```

## Step 3: Regenerate the component schema

```bash
cd convex/betterAuth && bunx @better-auth/cli generate -y
```

This adds the following fields:

**`user` table:**

| Field | Type | Description |
|-------|------|-------------|
| `role` | `string` | User role (e.g., `"user"`, `"admin"`) |
| `banned` | `boolean` | Whether the user is banned |
| `banReason` | `string \| null` | Reason for the ban |
| `banExpires` | `number \| null` | Ban expiration timestamp |

**`session` table:**

| Field | Type | Description |
|-------|------|-------------|
| `impersonatedBy` | `string \| null` | ID of the admin impersonating this session |

## Step 4: Update the seed user

Update `convex/init.ts` — add `role: "admin"` and `banned: false` to the seed user's `data` object so there is at least one admin after setup:

```ts
await ctx.runMutation(components.betterAuth.adapter.create, {
  input: {
    model: "user" as const,
    data: {
      name: userSeed.name,
      email: userSeed.email,
      emailVerified: true,
      role: "admin",
      banned: false,
      createdAt: Date.now(),
      updatedAt: Date.now(),
    },
  },
});
```

## Acceptance checklist

- [ ] `admin` plugin added to `createAuthOptions` in `convex/auth.ts`
- [ ] `adminClient()` added to `src/lib/auth-client.ts`
- [ ] Component schema regenerated
- [ ] Seed user has `role: "admin"` and `banned: false`
