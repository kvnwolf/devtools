# Mutations

Write Zod-validated Convex mutations. Mutations can read and write the database.

## Imports

```ts
import { z } from "zod";
import { zx } from "zodvex/core";
import { zm, zim } from "./utils";    // zm = public, zim = internal
```

## Standard CRUD Mutation Names

Every table should export `create`, `update`, and `remove` as needed:

```ts
import { Users } from "./users";

export const create = zm({
  args: Users.schema.insert,
  returns: zx.id("users"),
  handler: async (ctx, args) => {
    return await ctx.db.insert("users", args);
  },
});

export const update = zm({
  args: Users.schema.update,
  handler: async (ctx, { _id, ...data }) => {
    await ctx.db.patch(_id, data);
  },
});

export const remove = zm({
  args: { id: zx.id("users") },
  handler: async (ctx, { id }) => {
    await ctx.db.delete(id);
  },
});
```

## Create with Computed Fields

When the mutation adds fields not provided by the caller:

```ts
export const create = zm({
  args: {
    name: z.string().min(1),
    email: z.string().email(),
    workspaceId: zx.id("workspaces"),
  },
  returns: zx.id("users"),
  handler: async (ctx, args) => {
    return await ctx.db.insert("users", { ...args, role: "member" });
  },
});
```

## Update Specific Fields (pick + extend)

Derive args from the schema with `.pick()`. Use `.extend()` to add extra args:

```ts
export const update = zim({
  args: Orders.schema.insert.pick({ status: true }).extend({
    id: zx.id("orders"),
  }),
  handler: async (ctx, { id, status }) => {
    await ctx.db.patch(id, { status });
  },
});
```

- Optional → required: chain `.required()`
- Required → optional: chain `.partial()`

```ts
export const update = zm({
  args: Users.schema.insert
    .pick({ name: true, email: true, avatarUrl: true })
    .partial()
    .extend({ id: zx.id("users") }),
  handler: async (ctx, { id, ...data }) => {
    await ctx.db.patch(id, data);
  },
});
```

## Internal Mutations

Not exposed in the public API. Only callable via `ctx.runMutation`.

```ts
export const create = zim({
  args: {
    externalId: z.string(),
    name: z.string(),
    email: z.string().email(),
  },
  returns: zx.id("users"),
  handler: async (ctx, args) => {
    return await ctx.db.insert("users", { ...args, role: "member" });
  },
});
```

## Context API

- `ctx.db` — Database reader + writer (query, get, insert, patch, replace, delete)
- `ctx.auth` — Authentication info
- `ctx.runQuery(internal.module.fn, args)` — Call a query
- `ctx.runMutation(internal.module.fn, args)` — Call another mutation
- `ctx.scheduler.runAfter(delay, internal.module.fn, args)` — Schedule a function

## Client Side — Service Layer

Create mutation hooks in `src/services/`. All mutations must include optimistic updates — never export a bare `useMutation` without `.withOptimisticUpdate()`.

**Naming convention:**

| Convex function | Service export | Pattern |
|---|---|---|
| `users.create` | `useCreateUser()` | `use` + `Create` + singular |
| `users.update` | `useUpdateUser()` | `use` + `Update` + singular |
| `users.remove` | `useRemoveUser()` | `use` + `Remove` + singular |

```ts
// src/services/users.ts
import { api } from "@convex";
import type { Doc } from "convex/_generated/dataModel";
import { useMutation } from "convex/react";

export function useCreateUser() {
  return useMutation(api.users.create).withOptimisticUpdate((store, args) => {
    const current = store.getQuery(api.users.list, {}) ?? [];
    store.setQuery(api.users.list, {}, [
      ...current,
      {
        _id: crypto.randomUUID() as Doc<"users">["_id"],
        _creationTime: Date.now(),
        ...args,
      },
    ]);
  });
}

export function useUpdateUser() {
  return useMutation(api.users.update).withOptimisticUpdate((store, args) => {
    const current = store.getQuery(api.users.get, { id: args._id });
    if (!current) return;
    store.setQuery(api.users.get, { id: args._id }, { ...current, ...args });
  });
}

export function useRemoveUser() {
  return useMutation(api.users.remove).withOptimisticUpdate((store, args) => {
    const current = store.getQuery(api.users.list, {}) ?? [];
    store.setQuery(
      api.users.list,
      {},
      current.filter((user) => user._id !== args.id),
    );
  });
}
```

## Call Mutations in Components

```tsx
import { useCreateUser } from "@/services/users";

function CreateUserForm() {
  const createUser = useCreateUser();

  async function handleSubmit(data: { name: string; email: string }) {
    await createUser(data);
  }

  return <form onSubmit={handleSubmit}>...</form>;
}
```

## Acceptance checklist

- [ ] Mutation uses `zm` (public) or `zim` (internal)
- [ ] Args validated with Zod, returns typed where applicable
- [ ] Uses standard names: `create`, `update`, `remove`
- [ ] Client hook uses `useMutation` with `.withOptimisticUpdate()`
- [ ] Naming follows `use` + verb + singular pattern
