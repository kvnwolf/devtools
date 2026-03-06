# Reference-style skill — no steps, lookup-based

Not procedural. Agent consults it as a knowledge base when relevant.

```markdown
---
name: error-handling
description: Defines error handling patterns and conventions for the project. Use when throwing errors, creating error classes, handling exceptions, or adding try-catch blocks.
---

## Error classes

```ts
class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number,
  ) {
    super(message);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, "NOT_FOUND", 404);
  }
}

class ValidationError extends AppError {
  constructor(field: string, reason: string) {
    super(`${field}: ${reason}`, "VALIDATION_ERROR", 400);
  }
}
```

## Patterns

| Scenario | Pattern |
|----------|---------|
| Missing resource | `throw new NotFoundError("User")` |
| Invalid input | `throw new ValidationError("email", "invalid format")` |
| External service failure | Retry 3x, then `throw new AppError(msg, "SERVICE_ERROR", 502)` |
| Unexpected error | Let it bubble — global handler catches it |

## Anti-patterns

- Never `catch (e) {}` — silent swallow
- Never `console.log(e)` without rethrowing
- Never string errors — always `AppError` subclass
```

## Why this works

- No steps — agent reads it when writing error handling code
- Table format for quick pattern lookup
- Anti-patterns prevent common mistakes
- Code examples are copy-paste ready
