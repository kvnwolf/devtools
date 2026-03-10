# Tables

Define Convex tables using zodvex's `zodTable` with Zod schemas.

## Imports

```ts
import { z } from "zod";
import { zx } from "zodvex/core";
import { zodTable } from "zodvex/server";
```

## Defining a Table

Each table lives in its own file under `convex/`. The file exports the `zodTable` definition and all related queries/mutations.

```ts
// convex/users.ts
export const Users = zodTable("users", {
  name: z.string(),
  email: z.string().email(),
  avatarUrl: z.string().url().optional(),
  role: z.enum(["admin", "member"]),
  workspaceId: zx.id("workspaces"),
});
```

## zodTable Return Value

```ts
Users.table          // Convex table definition (for defineSchema)
Users.tableName      // "users"
Users.shape          // Raw Zod shape object
Users.schema.doc     // Zod schema with _id + _creationTime (for returns)
Users.schema.docArray // Array of docs
Users.schema.base    // User-defined fields only
Users.schema.insert  // Alias for base (for insert args)
Users.schema.update  // Partial user fields + required _id (for patch args)
```

## Convex-specific Zod Types

```ts
zx.id("users")          // Convex document ID
zx.date()               // Date codec (wire: number, runtime: Date)
```

Use `zx.date()` instead of `z.date()` — native `z.date()` is not supported by Convex.

## Assembling Schema

Import all table definitions into `convex/schema.ts`:

```ts
import { defineSchema } from "convex/server";
import { Users } from "./users";
import { Workspaces } from "./workspaces";

export default defineSchema({
  users: Users.table
    .index("by_email", ["email"])
    .index("by_workspace", ["workspaceId"]),
  workspaces: Workspaces.table
    .index("by_slug", ["slug"]),
});
```

- Use `Table.table` as the value
- Chain `.index("name", ["field1", "field2"])` for database indexes
- Indexes are required for any field you query with `.withIndex()`

## Acceptance checklist

- [ ] Table defined with `zodTable` in its own file under `convex/`
- [ ] Uses `zx.id()` for document ID references, `zx.date()` for dates
- [ ] Table registered in `convex/schema.ts` with `Table.table`
- [ ] Indexes added for fields queried with `.withIndex()`
