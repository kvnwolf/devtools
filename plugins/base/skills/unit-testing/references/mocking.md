# Mocking Patterns

## Dependency Injection

Accept dependencies as parameters instead of importing directly:

```ts
// Hard to test
export async function getUser(id: string) {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
}

// Easy to test
export async function getUser(id: string, fetcher = fetch) {
  const res = await fetcher(`/api/users/${id}`);
  return res.json();
}
```

## SDK-style Interfaces

Wrap external services in thin SDK classes. Mock the SDK, not raw HTTP:

```ts
// Good — mock GitHubClient
class GitHubClient {
  async getRepo(owner: string, repo: string) { ... }
}

// Bad — mock fetch globally
vi.stubGlobal("fetch", vi.fn(...))
```

## Good: Mock External API

```ts
test("fetches user from API", async () => {
  const mockFetch = vi.fn().mockResolvedValue({
    ok: true,
    json: () => Promise.resolve({ id: "1", name: "Alice" }),
  });

  const user = await getUser("1", mockFetch);
  expect(user).toEqual({ id: "1", name: "Alice" });
});
```

## Bad: Mock Internal Module

```ts
// DON'T — mocking your own utility
vi.mock("./utils", () => ({
  formatName: vi.fn((name) => name.toUpperCase()),
}));
```

## Bad: Testing Private Methods

```ts
// Bad — testing internal helper directly
import { _normalizeEmail } from "./users";
test("normalizes email", () => {
  expect(_normalizeEmail("User@Example.COM")).toBe("user@example.com");
});

// Good — test through public API
import { createUser } from "./users";
test("normalizes email on creation", () => {
  const user = createUser({ email: "User@Example.COM", name: "Test" });
  expect(user.email).toBe("user@example.com");
});
```
