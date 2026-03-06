## File organization

Co-locate server functions in the file where they are used. When a server function is shared across multiple consumers, place it in `src/services/<service-name>.ts`.

Server functions must be defined at the **top level** of a file — not inside components or other functions.

## API

```ts
createServerFn({ method: "GET" | "POST" })   // default: GET
  .middleware([...])                           // optional
  .inputValidator(zodSchema)                   // optional, required if function accepts input
  .handler(async ({ data, context }) => { })
```

### Method selection

| Method | When |
|--------|------|
| `GET` (default) | Read-only operations, data fetching |
| `POST` | Mutations, side effects, large payloads |

### Calling server functions

```ts
// From a route loader
export const Route = createFileRoute("/items")({
  loader: () => getItems(),
});

// With input
const item = await getItem({ data: { id: "abc-123" } });
```

## Input validation

Always use `inputValidator` with a Zod schema on every function that accepts input. Extract schemas to a shared file when used by both client forms and server functions.

## Middleware

Use `createMiddleware({ type: "function" })` for cross-cutting concerns (auth, logging). Chain with `.server()` and/or `.client()` handlers.

| Direction | How | Use case |
|-----------|-----|----------|
| Server → handler | `next({ context: { ... } })` | Auth session, DB connection |
| Client → server | `next({ sendContext: { ... } })` | Workspace ID, trace ID |
| Server → client | `next({ sendContext: { ... } })` | Server timing, trace ID |

## Error handling

Use `notFound()` for 404, `redirect()` for redirects, `throw new Error()` for generic errors — all from `@tanstack/react-router`.

## Testing

The global `createServerFn` mock in `src/test/unit.setup.ts` makes server functions directly callable in tests while preserving `inputValidator` validation.

1. **Mock external boundaries** — DB, cookies, external APIs. Never mock your own modules
2. **Dynamic import** the module under test (`await import(...)`) so mocks apply
3. **`vi.clearAllMocks()`** in `afterEach` to reset call history
4. **Test valid inputs** — verify the handler produces correct results
5. **Test invalid inputs** — verify `inputValidator` rejects bad data before the handler runs
6. **Test error paths** — verify the handler throws for not-found, unauthorized, etc.

See `examples/` for complete server function + test pairs:

| Example | Pattern |
|---------|---------|
| `examples/cookies.md` | GET/POST with cookies (`getCookie`/`setCookie`) |
| `examples/db-query.md` | GET with DB query and error handling |
| `examples/middleware.md` | Auth middleware protecting a server function |

## Acceptance checklist

- [ ] Server function defined at top level
- [ ] Co-located in the file where it's used, or in `src/services/` if shared
- [ ] `inputValidator` with Zod schema on every function that accepts input
- [ ] `method: "POST"` for mutations
- [ ] Middleware for cross-cutting concerns (auth, logging)
- [ ] Unit test co-located next to source file
- [ ] Tests cover valid inputs, invalid inputs, and error paths
- [ ] External boundaries mocked, internal modules not mocked
