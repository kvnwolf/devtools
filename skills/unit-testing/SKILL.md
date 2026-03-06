---
name: unit-testing
description: Writes unit tests following behavior-driven conventions with vitest. Use when creating tests, adding test coverage, or writing regression tests.
---

# Unit Testing

## Conventions

- Co-locate tests: `foo.test.ts` next to `foo.ts`
- Always wrap in `describe` named after the unit under test
- Use `test`, not `it`
- Test behavior through public interfaces, not implementation details
- Good tests survive refactors — if the public API doesn't change, tests shouldn't break

```ts
describe("createCart", () => {
  test("calculates total for multiple items", () => { ... });
  test("returns empty items for new cart", () => { ... });
});
```

## Vitest API

```ts
import { describe, expect, test, vi } from "vitest";
```

| API | Use |
|-----|-----|
| `describe("group", fn)` | Group related tests |
| `test("desc", fn)` | Single test |
| `test.each([...])("desc %s", fn)` | Parameterized |
| `expect(v).toBe(x)` | Strict equality |
| `expect(v).toEqual(x)` | Deep equality |
| `expect(fn).toThrow()` | Assert throws |
| `vi.fn()` | Mock function |

## Mocking Rules

Mock **only** at system boundaries:
- External APIs, databases, time (`Date.now`), randomness (`Math.random`), file system

**Never** mock things you control:
- Your own modules, internal collaborators, utility functions, data transformations

If you feel the need to mock an internal module, the code is doing too much or you're testing at the wrong level.

For mocking patterns and DI examples, see `references/mocking.md`.

## Acceptance Checklist

- [ ] Test describes behavior, not implementation
- [ ] Test uses the public interface
- [ ] Test would survive an internal refactor
- [ ] Mocks only at system boundaries
- [ ] Co-located next to source file
