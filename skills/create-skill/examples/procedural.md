# Procedural skill — defined steps, defined outputs

Closed procedure where every output file is specified. No examples/ needed.

```markdown
---
name: setup-api
description: Scaffolds a REST API with Hono and Drizzle. Use when starting a new API project, creating a backend service, or bootstrapping an HTTP server.
---

## Step 1: Ask about the project

Ask the user what the API will serve and what database they plan to use.

## Step 2: Create package.json

```json
{
  "name": "<project-name>",
  "type": "module",
  "scripts": {
    "dev": "bun run --hot src/index.ts",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate"
  }
}
```

## Step 3: Install dependencies

```bash
bun add hono drizzle-orm
bun add -d drizzle-kit
```

## Step 4: Create src/index.ts

```ts
import { Hono } from "hono";

const app = new Hono();

app.get("/health", (c) => c.json({ status: "ok" }));

export default app;
```

## Acceptance checklist

- [ ] package.json created with project name
- [ ] Dependencies installed
- [ ] Entry point serves /health endpoint
```

## Why this works

- Every file is fully specified — no ambiguity
- Steps are sequential and prescriptive (low freedom)
- No examples/ needed — output is defined
- No references/ needed — single linear flow
