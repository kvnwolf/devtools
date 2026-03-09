# Admin API Patterns

## User Management

```ts
// List users with filtering, sorting, and pagination
const { data } = await authClient.admin.listUsers({
  query: {
    searchValue: "john",
    searchField: "email",                    // "email" | "name"
    searchOperator: "contains",              // "contains" | "starts_with" | "ends_with"
    limit: 10,
    offset: 0,
    sortBy: "createdAt",
    sortDirection: "desc",                   // "asc" | "desc"
    filterField: "role",
    filterValue: "admin",
    filterOperator: "eq",                    // "eq" | "ne" | "lt" | "gt" | "in" | etc.
  },
});
// Returns: { users: User[], total: number, limit: number, offset: number }

// Create a user
await authClient.admin.createUser({
  email: "user@example.com",
  password: "secure-password",
  name: "John Doe",
  role: "user",
  data: { /* extra fields */ },
});

// Update a user
await authClient.admin.updateUser({
  userId: "user-id",
  data: { name: "Jane Doe" },
});

// Remove a user (hard delete)
await authClient.admin.removeUser({ userId: "user-id" });
```

## Roles

```ts
// Set a user's role
await authClient.admin.setRole({ userId: "user-id", role: "admin" });

// Set a user's password
await authClient.admin.setUserPassword({ userId: "user-id", newPassword: "new-pass" });
```

## Banning

```ts
// Ban a user (revokes all existing sessions)
await authClient.admin.banUser({
  userId: "user-id",
  banReason: "Spamming",
  banExpiresIn: 86400,           // seconds, omit for permanent
});

// Unban a user
await authClient.admin.unbanUser({ userId: "user-id" });
```

## Session Management

```ts
// List a user's sessions
const { data } = await authClient.admin.listUserSessions({ userId: "user-id" });

// Revoke a single session
await authClient.admin.revokeUserSession({ sessionToken: "token" });

// Revoke all sessions for a user
await authClient.admin.revokeUserSessions({ userId: "user-id" });
```

## Impersonation

```ts
// Start impersonating (creates a temporary session as the target user)
await authClient.admin.impersonateUser({ userId: "user-id" });

// Stop impersonating (returns to admin session)
await authClient.admin.stopImpersonating();
```

Admins cannot impersonate other admins by default. To allow it, add `impersonate-admins` to the `user` actions in a custom role.

## Permission Checks

Client-side:

```ts
// Async — hits the server
const { data: allowed } = await authClient.admin.hasPermission({
  permissions: { project: ["create"] },
});

// Sync — no request, checks role definition locally
const can = authClient.admin.checkRolePermission({
  permissions: { user: ["delete"] },
  role: "admin",
});
```

Server-side:

```ts
const auth = createAuth(ctx);
await auth.api.userHasPermission({
  body: {
    userId: "user-id",
    permissions: { project: ["create"] },
  },
});
```

## Custom Access Control

For granular permissions beyond the default `admin`/`user` split, define a shared access control configuration.

### 1. Create convex/permissions.ts

```ts
import { createAccessControl } from "better-auth/plugins/access";
import { adminAc, defaultStatements } from "better-auth/plugins/admin/access";

const statement = {
  ...defaultStatements,
  project: ["create", "read", "update", "delete"],
} as const;

export const ac = createAccessControl(statement);

export const roles = {
  user: ac.newRole({
    project: ["read"],
  }),
  admin: ac.newRole({
    ...adminAc.statements,
    project: ["create", "read", "update", "delete"],
  }),
};
```

`defaultStatements` includes the built-in `user` and `session` resource permissions. `adminAc.statements` grants all default admin permissions to a role.

### 2. Register on the server

Update the `admin()` call in `convex/auth.ts`:

```ts
import { ac, roles } from "./permissions";

admin({ ac, roles }),
```

When using custom `ac` and `roles`, the `adminRoles` option is not needed — permissions are determined by what each role grants.

### 3. Register on the client

Update `src/lib/auth-client.ts`:

```ts
import { ac, roles } from "@convex/permissions";

adminClient({ ac, roles }),
```

### Default admin permissions

| Resource | Actions |
|----------|---------|
| `user` | `create`, `list`, `set-role`, `ban`, `impersonate`, `delete`, `set-password` |
| `session` | `list`, `revoke`, `delete` |

To allow impersonating other admins, add `impersonate-admins` to the `user` actions in your custom role.
