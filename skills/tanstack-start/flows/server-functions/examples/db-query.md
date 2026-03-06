# DB Query — GET with error handling

## Server function

```ts
// src/services/posts.ts
import { createServerFn } from "@tanstack/react-start";
import { notFound } from "@tanstack/react-router";
import { eq } from "drizzle-orm";
import { z } from "zod";
import { db } from "@/lib/db";
import { posts } from "@/lib/db/schema";

export const listPosts = createServerFn().handler(async () => {
  return db.select().from(posts).orderBy(posts.createdAt);
});

export const getPost = createServerFn()
  .inputValidator(z.object({ id: z.string().uuid() }))
  .handler(async ({ data }) => {
    const [post] = await db.select().from(posts).where(eq(posts.id, data.id));
    if (!post) throw notFound();
    return post;
  });

export const createPost = createServerFn({ method: "POST" })
  .inputValidator(z.object({ title: z.string().min(1), body: z.string() }))
  .handler(async ({ data }) => {
    const [post] = await db.insert(posts).values(data).returning();
    return post;
  });
```

## Test

```ts
// src/services/posts.test.ts
import { afterEach, describe, expect, test, vi } from "vitest";

const mockDb = {
  select: vi.fn(),
  insert: vi.fn(),
};

// Chain mocks for drizzle query builder
const mockFrom = vi.fn();
const mockWhere = vi.fn();
const mockOrderBy = vi.fn();
const mockValues = vi.fn();
const mockReturning = vi.fn();

mockDb.select.mockReturnValue({ from: mockFrom });
mockFrom.mockReturnValue({ where: mockWhere, orderBy: mockOrderBy });
mockDb.insert.mockReturnValue({ values: mockValues });
mockValues.mockReturnValue({ returning: mockReturning });

vi.mock("@/lib/db", () => ({ db: mockDb }));
vi.mock("@/lib/db/schema", () => ({ posts: { id: "id", createdAt: "created_at" } }));
vi.mock("@tanstack/react-router", () => ({
  notFound: () => {
    const err = new Error("Not Found");
    err.name = "NotFoundError";
    return err;
  },
}));

const { listPosts, getPost, createPost } = await import("./posts");

afterEach(() => {
  vi.clearAllMocks();
});

describe("listPosts", () => {
  test("returns all posts", () => {
    const posts = [{ id: "1", title: "Hello" }];
    mockOrderBy.mockReturnValue(posts);
    expect(listPosts()).toEqual(posts);
  });
});

describe("getPost", () => {
  test("returns a post by id", () => {
    const post = { id: "550e8400-e29b-41d4-a716-446655440000", title: "Hello" };
    mockWhere.mockReturnValue([post]);
    expect(getPost({ data: { id: post.id } })).toEqual(post);
  });

  test("throws not found when post does not exist", () => {
    mockWhere.mockReturnValue([]);
    expect(() => getPost({ data: { id: "550e8400-e29b-41d4-a716-446655440000" } })).toThrow();
  });

  test("rejects invalid id format", () => {
    expect(() => getPost({ data: { id: "not-a-uuid" } })).toThrow();
  });
});

describe("createPost", () => {
  test("inserts and returns the new post", () => {
    const post = { id: "1", title: "New", body: "Content" };
    mockReturning.mockReturnValue([post]);
    expect(createPost({ data: { title: "New", body: "Content" } })).toEqual(post);
  });

  test("rejects empty title", () => {
    expect(() => createPost({ data: { title: "", body: "Content" } })).toThrow();
    expect(mockDb.insert).not.toHaveBeenCalled();
  });
});
```

## Key patterns

- Mock `@/lib/db` — external boundary (database)
- Chain mocks to simulate drizzle's query builder API
- Test not-found error path for missing records
- Test `inputValidator` rejects invalid UUID before DB is queried
- Test mutations verify the handler is not called on invalid input
