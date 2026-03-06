---
name: component-testing
description: Writes component tests using Vitest Browser Mode with Playwright for real-browser testing. Use when testing React components, writing browser-based tests, verifying UI behavior, testing forms, or deciding whether a component needs a test.
---

# Component Testing

Vitest Browser Mode with Playwright. Tests run in real Chromium — every DOM API, CSS layout, and browser behavior is authentic.

## Conventions

- Co-locate tests: `foo.browser.test.tsx` next to `foo.tsx`
- Always wrap in `describe` named after the component
- Use `test`, not `it`
- `render()` is async — always `await` it
- Test behavior through rendered output, not implementation details
- Do NOT test shadcn/ui primitives — only test your own components that compose them

```ts
describe("SearchFilter", () => {
  test("filters results on input change", async () => { ... });
  test("shows empty state when no matches", async () => { ... });
});
```

## When to Test

Test when a component has:
- `useState` or state management logic
- `useEffect` or side effects
- Event handlers with conditional logic
- Conditional rendering based on props or state
- Complex prop transformations

Skip when a component:
- Is a pure style wrapper (just applies CSS classes)
- Has no logic — only passes props through
- Is a thin layout component
- Is a shadcn/ui primitive

## Vitest Browser API

```ts
import { render } from "vitest-browser-react";
import { page } from "vitest/browser";
import { describe, expect, test, vi } from "vitest";
```

| API | Use |
|-----|-----|
| `await render(<C />)` | Mount component |
| `page.getByRole("button", { name })` | Query by ARIA role |
| `page.getByText("text")` | Query by text content |
| `page.getByLabelText("label")` | Query by label |
| `locator.click()` | Click interaction |
| `locator.fill("value")` | Type into input |
| `await expect.element(locator)` | Auto-retry assertion (1s) |
| `expect(value)` | Synchronous assertion |

## `expect.element()` vs `expect()`

| Use | When |
|-----|------|
| `await expect.element(locator)` | Page locator queries — auto-retries until pass |
| `expect(value)` | Mock assertions, `container.querySelector()`, non-DOM values |

## What NOT to Test

- **CSS classes** — test visible behavior instead
- **Internal state** — verify through rendered output
- **Implementation details** — don't test hook call order

## Examples

See `examples/` for complete test examples by pattern:

| Example | When to use |
|---------|-------------|
| `examples/render-and-query.md` | Basic rendering, role and text queries |
| `examples/user-interactions.md` | Clicks, toggles, stateful interactions |
| `examples/form-testing.md` | Form inputs, submission, validation |
| `examples/conditional-rendering.md` | Show/hide content based on props or state |
| `examples/container-queries.md` | DOM structure, `data-*` attributes, `container.querySelector()` |
| `examples/compound-components.md` | Multi-part composed components |

## Acceptance Checklist

- [ ] Test file uses `.browser.test.tsx` extension
- [ ] Co-located next to the component
- [ ] Wrapped in `describe` named after the component
- [ ] Uses `test`, not `it`
- [ ] `render()` is awaited
- [ ] Uses `expect.element()` for locator assertions
- [ ] Tests behavior, not implementation details
- [ ] Mocks only at system boundaries
