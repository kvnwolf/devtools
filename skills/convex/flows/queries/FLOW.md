# Queries

Write Zod-validated Convex queries. Queries are read-only.

## Imports

```ts
import { z } from "zod";
import { zx } from "zodvex/core";
import { zq, ziq } from "./utils";    // zq = public, ziq = internal
```

## Standard CRUD Query Names

Every table should export `get` (single record) and `list` (multiple records):

```ts
import { Users } from "./users";

export const get = zq({
  args: { id: zx.id("users") },
  returns: Users.schema.doc.nullable(),
  handler: async (ctx, { id }) => {
    return await ctx.db.get(id);
  },
});

export const list = zq({
  args: {},
  returns: Users.schema.docArray,
  handler: async (ctx) => {
    return await ctx.db.query("users").collect();
  },
});
```

## Adding Filters

Derive args from the schema using `.pick()` instead of redeclaring field types. Use `.extend()` for extra args:

```ts
export const list = zq({
  args: Orders.schema.insert.pick({ customerId: true }).extend({
    status: Orders.shape.status.optional(),
  }),
  returns: Orders.schema.docArray,
  handler: async (ctx, { customerId, status }) => {
    if (status) {
      return await ctx.db
        .query("orders")
        .withIndex("by_customer_status", (q) => q.eq("customerId", customerId).eq("status", status))
        .collect();
    }
    return await ctx.db
      .query("orders")
      .withIndex("by_customer", (q) => q.eq("customerId", customerId))
      .collect();
  },
});
```

## Internal Queries

Not exposed in the public API. Only callable from other Convex functions via `ctx.runQuery`.

```ts
export const get = ziq({
  args: { externalId: z.string() },
  returns: Users.schema.doc.nullable(),
  handler: async (ctx, { externalId }) => {
    return await ctx.db
      .query("users")
      .withIndex("by_external_id", (q) => q.eq("externalId", externalId))
      .first();
  },
});
```

## Context API

- `ctx.db` — Database reader (query, get)
- `ctx.auth` — Authentication info
- `ctx.runQuery(internal.module.fn, args)` — Call another query

## Client Side — Service Layer

Create query option factory functions in `src/services/`. Follow the **RoRo (Receive Object, Return Object)** pattern — all args are always objects.

**Naming convention:**

| Convex function | Service export | Pattern |
|---|---|---|
| `users.get` | `getUser(args)` | `get` + singular |
| `users.list` | `listUsers(args)` | `list` + plural |
| `auth.getCurrentUser` | `getCurrentUser()` | Keep as-is |

```ts
// src/services/users.ts
import { api } from "@convex";
import { convexQuery } from "@convex-dev/react-query";
import type { Id } from "convex/_generated/dataModel";

export function listUsers() {
  return convexQuery(api.users.list, {});
}

export function getUser(args: { id: Id<"users"> }) {
  return convexQuery(api.users.get, args);
}
```

`convexQuery` returns a React Query options object — use with `useSuspenseQuery`, `useQuery`, or `prefetchQuery`.

## Prefetch in Route Loader (SSR)

```tsx
import { createFileRoute } from "@tanstack/react-router";
import { listUsers } from "@/services/users";

export const Route = createFileRoute("/users")({
  loader: ({ context }) => {
    context.queryClient.prefetchQuery(listUsers());
  },
  component: UsersPage,
});
```

## Read Data in Component

Place a `<Suspense>` boundary around **each component that fetches data**, not around the entire route. Each boundary gets its own `<Skeleton>` fallback matching the shape of the content it wraps.

```tsx
// Correct — one Suspense per data-fetching component
function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<UserListSkeleton />}>
        <UserList />
      </Suspense>
      <Suspense fallback={<OrderTableSkeleton />}>
        <OrderTable />
      </Suspense>
    </div>
  );
}
```

### Full Example

```tsx
import { Suspense } from "react";
import { useSuspenseQuery } from "@tanstack/react-query";
import { Skeleton } from "@/components/ui/skeleton";
import { listUsers } from "@/services/users";

export function UsersPage() {
  return (
    <Suspense fallback={<UserListSkeleton />}>
      <UserList />
    </Suspense>
  );
}

function UserListSkeleton() {
  return (
    <ul className="space-y-2">
      {Array.from({ length: 5 }).map((_, i) => (
        <li key={i}>
          <Skeleton className="h-6 w-48" />
        </li>
      ))}
    </ul>
  );
}

function UserList() {
  const { data: users } = useSuspenseQuery(listUsers());

  return (
    <ul>
      {users.map((user) => (
        <li key={user._id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

## Acceptance checklist

- [ ] Query uses `zq` (public) or `ziq` (internal)
- [ ] Args validated with Zod, returns typed with table schema
- [ ] Uses `.withIndex()` for filtered queries (index must exist in schema)
- [ ] Client service function uses `convexQuery` and RoRo pattern
- [ ] Route loader prefetches with `prefetchQuery`
- [ ] Each data-fetching component wrapped in its own `<Suspense>` with skeleton
