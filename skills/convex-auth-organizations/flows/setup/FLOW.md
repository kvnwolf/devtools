# Organization Plugin Setup

Add the Better Auth organization plugin for multi-tenant support: organizations, members, invitations, and role-based access control.

> **Requires local install.** The organization plugin modifies the Better Auth database schema. If the project is not yet using a local install, follow the `convex-auth` local-install flow first, then return here.

## Step 1: Add the organization plugin to the server

Update `convex/auth.ts` — add `organization` to the plugins array inside `createAuthOptions`:

```ts
import { organization } from "better-auth/plugins";

export function createAuthOptions(ctx: GenericCtx<DataModel>) {
  return {
    baseURL: String(process.env.SITE_URL),
    database: authComponent.adapter(ctx),
    plugins: [
      convex({ authConfig }),
      organization(),
    ],
  } satisfies BetterAuthOptions;
}
```

If the project uses invitations, pass the `sendInvitationEmail` callback:

```ts
import { requireActionCtx } from "@convex-dev/better-auth/utils";

organization({
  async sendInvitationEmail(data) {
    const actionCtx = requireActionCtx(ctx);
    const inviteLink = `${String(process.env.SITE_URL)}/invite/${data.id}`;
    await actionCtx.runAction(internal.email.sendInvitation, {
      email: data.email,
      inviterName: data.inviter.user.name,
      organizationName: data.organization.name,
      inviteLink,
    });
  },
}),
```

## Step 2: Add the organization plugin to the client

Update `src/lib/auth-client.ts`:

```ts
import { convexClient } from "@convex-dev/better-auth/client/plugins";
import { organizationClient } from "better-auth/client/plugins";
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  plugins: [convexClient(), organizationClient()],
});
```

## Step 3: Regenerate the component schema

```bash
cd convex/betterAuth && bunx @better-auth/cli generate -y
```

This adds the `organization`, `member`, and `invitation` tables to `convex/betterAuth/schema.ts`.

## Acceptance checklist

- [ ] `organization` plugin added to `createAuthOptions` in `convex/auth.ts`
- [ ] `organizationClient()` added to `src/lib/auth-client.ts`
- [ ] Component schema regenerated
