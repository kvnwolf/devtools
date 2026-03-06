---
name: e2e-testing
description: Writes end-to-end tests with Playwright Test for full user flow verification. Use when adding, modifying, or removing user flows in an application. Do not use for isolated component behavior — use component-testing instead.
---

# E2E Testing

Playwright Test against the real application — real server, real browser, real data.

## Conventions

- Tests live in `e2e/` at the project root, NOT co-located with source
- Authenticated tests: `e2e/flow-name.spec.ts` — run with saved session automatically
- Unauthenticated tests: `e2e/flow-name.unauth.spec.ts` — fresh browser, no session
- Run with `bun run e2e`
- Test data lives in `e2e/seeds/` as JSON files
- Import `test` from `./utils` (shared fixture), `expect` from `@playwright/test`

```ts
import { expect } from "@playwright/test";
import { test } from "./utils";
```

The shared `test` fixture waits for `[data-hydrated]` after every `page.goto()` — buttons and handlers are ready immediately.

## Playwright API

| API | Use |
|-----|-----|
| `page.goto("/path")` | Navigate to URL |
| `page.getByRole("button", { name })` | Query by ARIA role |
| `page.getByText("text")` | Query by text content |
| `page.getByLabel("label")` | Query by form label |
| `locator.click()` | Click interaction |
| `locator.fill("value")` | Type into input |
| `expect(page).toHaveURL(pattern)` | Assert current URL |
| `expect(locator).toBeVisible()` | Assert element visible |
| `page.waitForURL(pattern)` | Wait for navigation |
| `page.context().storageState()` | Save auth state |

## E2E vs Component Test

| Scenario | Test type |
|----------|-----------|
| Multi-step user flow across pages | E2E |
| Authentication and authorization | E2E |
| CRUD lifecycle | E2E |
| API integration across pages | E2E |
| Isolated UI component behavior | Component |
| Form validation feedback | Component |
| Component state management | Component |

**Rule of thumb:** involves chained steps across the real app → E2E. Tests isolated UI behavior → component test.

## Examples

See `examples/` for complete test examples by pattern:

| Example | When to use |
|---------|-------------|
| `examples/navigation.md` | Page transitions, link clicks, URL assertions |
| `examples/form-submission.md` | Form fills, submissions, validation |
| `examples/crud-flow.md` | Create, edit, delete lifecycle |
| `examples/auth-persistence.md` | Login setup, session reuse, unauthenticated tests |

## Acceptance Checklist

- [ ] Test lives in `e2e/` directory
- [ ] Uses correct extension: `.spec.ts` (authenticated) or `.unauth.spec.ts` (unauthenticated)
- [ ] Imports `test` from `./utils`, `expect` from `@playwright/test`
- [ ] Tests a real user flow, not isolated component behavior
- [ ] Uses seed data from `e2e/seeds/` when needed
- [ ] No manual hydration waits (fixture handles it)
- [ ] Tests behavior, not implementation details
