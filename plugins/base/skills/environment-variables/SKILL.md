---
name: environment-variables
description: Manages and validates environment variables. Use when adding, modifying, or referencing env vars, working with .env files, or separating client vs. server variables.
---

## Setup

If `src/lib/env.ts` does not exist, install dependencies and create the files before proceeding:

```bash
bun add @t3-oss/env-core zod
```

```ts
import { createEnv } from "@t3-oss/env-core";

export const env = createEnv({
  emptyStringAsUndefined: true,
  runtimeEnv: process.env,
  server: {},
});
```

```ts
// src/lib/env.test.ts
import { describe, expect, test } from "vitest";
import { env } from "./env";

describe("env", () => {
  test("initializes without error", () => {
    expect(env).toBeDefined();
  });
});
```

## Variable Types

| Type | Prefix | Exposed to client | Example |
|------|--------|-------------------|---------|
| Client | `VITE_` | Yes | `VITE_API_URL` |
| Server | None | No | `DATABASE_URL` |
| Shared | None | Both (build-time) | `NODE_ENV`, `DEV` |

Client = public endpoints, publishable keys, UI feature flags.
Server = secrets, DB strings, internal URLs.

## Environment Files

| File | Purpose | Git |
|------|---------|-----|
| `.env` | Development defaults (local URLs, non-sensitive) | Committed |
| `.env.local` | Secrets, API keys, overrides | Ignored |

Load order: `.env.local` overrides `.env`.

## Adding a Variable

1. Add Zod schema to `src/lib/env.ts` in `client`, `server`, or `shared`
2. Development default → `.env`; secret → `.env.local`
3. Configure in deployment environment
4. Add validation test to `src/lib/env.test.ts`

## Usage

```ts
import { env } from "@/lib/env";
```

## Quick Reference

| Task | Action |
|------|--------|
| Access var | `import { env } from "@/lib/env"` |
| Client var | `client` section, `VITE_` prefix |
| Server var | `server` section, no prefix |
| Shared var | `shared` section, build-time values |
| Validation | Zod schemas: `z.string()`, `z.boolean()`, etc. |

## Acceptance checklist

- [ ] `src/lib/env.ts` exists with t3-env + Zod config
- [ ] `src/lib/env.test.ts` exists with validation tests
- [ ] New variables added to correct section (`client`, `server`, `shared`)
- [ ] Defaults in `.env`, secrets in `.env.local`
- [ ] Deployment environment configured
