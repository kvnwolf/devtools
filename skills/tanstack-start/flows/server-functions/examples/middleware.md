# Middleware — Auth-protected server function

## Auth middleware

```ts
// src/lib/auth.middleware.ts
import { redirect } from "@tanstack/react-router";
import { createMiddleware } from "@tanstack/react-start";
import { getRequest } from "@tanstack/react-start/server";
import { auth } from "@/lib/auth";

export const authMiddleware = createMiddleware({ type: "function" }).server(
  async ({ next }) => {
    const request = getRequest();
    const session = await auth.api.getSession({ headers: request.headers });

    if (!session) {
      throw redirect({ to: "/login" });
    }

    return next({ context: { session } });
  }
);
```

## Protected server function

```ts
// src/services/todos.ts
import { createServerFn } from "@tanstack/react-start";
import { eq } from "drizzle-orm";
import { z } from "zod";
import { authMiddleware } from "@/lib/auth.middleware";
import { db } from "@/lib/db";
import { todos } from "@/lib/db/schema";

export const getTodos = createServerFn()
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    return db.select().from(todos).where(eq(todos.userId, context.session.user.id));
  });

export const createTodo = createServerFn({ method: "POST" })
  .middleware([authMiddleware])
  .inputValidator(z.object({ title: z.string().min(1) }))
  .handler(async ({ data, context }) => {
    return db.insert(todos).values({ ...data, userId: context.session.user.id }).returning();
  });
```

## Test

Testing server functions that use middleware — the global mock in `unit.setup.ts` does not execute middleware, so the handler receives `context` as `{ data }` only. Provide context values directly when needed.

```ts
// src/services/todos.test.ts
import { afterEach, describe, expect, test, vi } from "vitest";

const mockDb = {
  select: vi.fn(),
  insert: vi.fn(),
};

const mockFrom = vi.fn();
const mockWhere = vi.fn();
const mockValues = vi.fn();
const mockReturning = vi.fn();

mockDb.select.mockReturnValue({ from: mockFrom });
mockFrom.mockReturnValue({ where: mockWhere });
mockDb.insert.mockReturnValue({ values: mockValues });
mockValues.mockReturnValue({ returning: mockReturning });

vi.mock("@/lib/db", () => ({ db: mockDb }));
vi.mock("@/lib/db/schema", () => ({ todos: { userId: "user_id" } }));
vi.mock("@/lib/auth.middleware", () => ({
  authMiddleware: {},
}));

const { getTodos, createTodo } = await import("./todos");

afterEach(() => {
  vi.clearAllMocks();
});

describe("getTodos", () => {
  test("returns todos", () => {
    const todos = [{ id: "1", title: "Buy milk" }];
    mockWhere.mockReturnValue(todos);
    expect(getTodos()).toEqual(todos);
  });
});

describe("createTodo", () => {
  test("inserts and returns new todo", () => {
    const todo = { id: "1", title: "Buy milk" };
    mockReturning.mockReturnValue([todo]);
    expect(createTodo({ data: { title: "Buy milk" } })).toEqual([todo]);
  });

  test("rejects empty title", () => {
    expect(() => createTodo({ data: { title: "" } })).toThrow();
    expect(mockDb.insert).not.toHaveBeenCalled();
  });
});
```

## Key patterns

- Middleware itself is mocked out — unit tests focus on handler logic
- Auth middleware is tested separately in its own test file
- `context` values from middleware are not available in unit tests — the handler is tested in isolation
- For full auth flow testing, use e2e tests
