# Testing Convex Functions

Write tests for Convex functions using convex-test with Vitest.

## Convention

Co-locate tests next to source: `convex/users.test.ts` next to `convex/users.ts`.

**First test cleanup:** If this is the first Convex test file in the project, remove `convex-test` from the `ignoreDependencies` array in `package.json`'s knip config.

## Imports

```ts
import { convexTest } from "convex-test";
import { describe, expect, test, vi } from "vitest";
import { api, internal } from "./_generated/api";
import schema from "./schema";

const modules = import.meta.glob("./**/*.ts");
```

The `modules` glob lets convex-test resolve function references at runtime. Declare it at module level.

## Setup

```ts
const t = convexTest(schema, modules);
```

## Testing Queries

```ts
describe("users", () => {
  test("lists all users", async () => {
    const t = convexTest(schema, modules);

    await t.run(async (ctx) => {
      await ctx.db.insert("users", { name: "Alice", email: "alice@test.com", role: "member" });
      await ctx.db.insert("users", { name: "Bob", email: "bob@test.com", role: "admin" });
    });

    const users = await t.query(api.users.list, {});

    expect(users).toHaveLength(2);
    expect(users[0].name).toBe("Alice");
  });

  test("returns null for non-existent user", async () => {
    const t = convexTest(schema, modules);

    const user = await t.query(api.users.get, { id: "invalid_id" as any });

    expect(user).toBeNull();
  });
});
```

### Filtered Queries

```ts
describe("orders", () => {
  test("filters orders by status", async () => {
    const t = convexTest(schema, modules);

    const customerId = await t.run(async (ctx) => {
      const id = await ctx.db.insert("customers", { name: "Alice" });
      await ctx.db.insert("orders", { customerId: id, status: "pending" });
      await ctx.db.insert("orders", { customerId: id, status: "shipped" });
      return id;
    });

    const pending = await t.query(api.orders.list, { customerId, status: "pending" });
    expect(pending).toHaveLength(1);
    expect(pending[0].status).toBe("pending");
  });
});
```

## Testing Mutations

Verify effects through queries, not direct DB access:

```ts
describe("users", () => {
  test("creates a user", async () => {
    const t = convexTest(schema, modules);

    const id = await t.mutation(api.users.create, {
      name: "Alice",
      email: "alice@test.com",
      role: "member",
    });

    const user = await t.query(api.users.get, { id });
    expect(user).not.toBeNull();
    expect(user!.name).toBe("Alice");
  });

  test("updates a user", async () => {
    const t = convexTest(schema, modules);

    const id = await t.mutation(api.users.create, {
      name: "Alice",
      email: "alice@test.com",
      role: "member",
    });

    await t.mutation(api.users.update, { _id: id, name: "Alice Updated" });

    const user = await t.query(api.users.get, { id });
    expect(user!.name).toBe("Alice Updated");
  });

  test("removes a user", async () => {
    const t = convexTest(schema, modules);

    const id = await t.mutation(api.users.create, {
      name: "Alice",
      email: "alice@test.com",
      role: "member",
    });

    await t.mutation(api.users.remove, { id });

    const user = await t.query(api.users.get, { id });
    expect(user).toBeNull();
  });
});
```

## Testing Actions

Mock `fetch` with `vi.stubGlobal`:

```ts
describe("github", () => {
  test("fetches GitHub repo data", async () => {
    const t = convexTest(schema, modules);

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () =>
          Promise.resolve({
            name: "convex",
            description: "The fullstack TypeScript development platform",
            stargazers_count: 1000,
          }),
      }),
    );

    const repo = await t.action(api.github.fetchGitHubRepo, {
      owner: "get-convex",
      repo: "convex",
    });

    expect(repo.name).toBe("convex");
    expect(repo.stargazers_count).toBe(1000);

    vi.unstubAllGlobals();
  });
});
```

### Mocking Convex Components

Mock the entire module with `vi.mock` **before** the `modules` glob:

```ts
const sendEmailSpy = vi.fn();

vi.mock("@convex-dev/resend", () => ({
  Resend: class MockResend {
    sendEmail = sendEmailSpy;
  },
}));

const modules = import.meta.glob("./**/*.ts");

describe("sendOtp", () => {
  test("calls resend.sendEmail with correct arguments", async () => {
    const t = convexTest(schema, modules);
    sendEmailSpy.mockResolvedValue(undefined);

    await t.action(internal.email.sendOtp, {
      email: "test@example.com",
      otp: "123456",
      subject: "Sign in code",
    });

    expect(sendEmailSpy).toHaveBeenCalledOnce();
    const [, options] = sendEmailSpy.mock.calls[0];
    expect(options.to).toBe("test@example.com");
    expect(options.subject).toBe("Sign in code");
  });
});
```

### Actions with Side Effects

Verify side effects through queries after the action completes:

```ts
describe("releases", () => {
  test("syncs releases from GitHub", async () => {
    const t = convexTest(schema, modules);

    const projectId = await t.run(async (ctx) => {
      return await ctx.db.insert("projects", { fullName: "owner/repo" });
    });

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve([{ tag_name: "v1.0", body: "Release notes" }]),
      }),
    );

    await t.action(api.releases.syncFromGitHub, { projectId });

    const releases = await t.query(api.releases.list, { projectId });
    expect(releases).toHaveLength(1);
    expect(releases[0].tagName).toBe("v1.0");

    vi.unstubAllGlobals();
  });
});
```

## Testing with Auth

Use `register(t)` to create authenticated users via the Better Auth component adapter, then pass `{ subject, sessionId }` to `withIdentity`:

```ts
import { components } from "./_generated/api";

async function register(t: ReturnType<typeof convexTest>) {
  const userId = await t.run(async (ctx) => {
    const result = await ctx.runMutation(components.betterAuth.adapter.create, {
      input: {
        model: "user" as const,
        data: {
          name: "Alice",
          email: "alice@test.com",
          emailVerified: true,
          createdAt: Date.now(),
          updatedAt: Date.now(),
        },
      },
    });
    return result.id;
  });

  const sessionId = await t.run(async (ctx) => {
    const result = await ctx.runMutation(components.betterAuth.adapter.create, {
      input: {
        model: "session" as const,
        data: {
          userId,
          token: crypto.randomUUID(),
          expiresAt: Date.now() + 1000 * 60 * 60 * 24,
          createdAt: Date.now(),
          updatedAt: Date.now(),
        },
      },
    });
    return result.id;
  });

  return t.withIdentity({ subject: userId, sessionId });
}

describe("tasks", () => {
  test("authenticated user can create tasks", async () => {
    const t = convexTest(schema, modules);
    const asUser = await register(t);

    const id = await asUser.mutation(api.tasks.create, { title: "Buy milk" });

    const task = await asUser.query(api.tasks.get, { id });
    expect(task!.title).toBe("Buy milk");
  });

  test("unauthenticated user cannot create tasks", async () => {
    const t = convexTest(schema, modules);

    await expect(
      t.mutation(api.tasks.create, { title: "Buy milk" }),
    ).rejects.toThrow();
  });
});
```

## Direct DB Access (Use Sparingly)

Use `t.run()` for test setup when the public API is insufficient. Prefer public API calls for both setup and assertions:

```ts
// Good -- setup data that has no public create API
await t.run(async (ctx) => {
  await ctx.db.insert("systemConfig", { key: "maxRetries", value: 3 });
});

// Avoid -- don't use t.run() for assertions when a query exists
// Bad:
await t.run(async (ctx) => {
  const user = await ctx.db.query("users").first();
  expect(user!.name).toBe("Alice");
});
// Good:
const users = await t.query(api.users.list, {});
expect(users[0].name).toBe("Alice");
```

## Schema Validation Tests

```ts
import { Users } from "./users";

describe("Users schema", () => {
  test("accepts valid user data", () => {
    expect(() =>
      Users.schema.insert.parse({
        name: "Alice",
        email: "alice@test.com",
        role: "member",
      }),
    ).not.toThrow();
  });

  test("rejects invalid email", () => {
    expect(() =>
      Users.schema.insert.parse({
        name: "Alice",
        email: "not-an-email",
        role: "member",
      }),
    ).toThrow();
  });

  test("rejects invalid role", () => {
    expect(() =>
      Users.schema.insert.parse({
        name: "Alice",
        email: "alice@test.com",
        role: "superadmin",
      }),
    ).toThrow();
  });
});
```
