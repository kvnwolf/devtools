# Actions

Write Zod-validated Convex actions for external API calls. Actions run in Node.js and cannot directly access the database.

## Imports

```ts
import { z } from "zod";
import { zx } from "zodvex/core";
import { za, zia } from "./utils";    // za = public, zia = internal
```

## Public Action

```ts
export const fetchGitHubRepo = za({
  args: { owner: z.string(), repo: z.string() },
  returns: z.object({
    name: z.string(),
    description: z.string().nullable(),
    stargazers_count: z.number(),
  }),
  handler: async (ctx, { owner, repo }) => {
    const response = await fetch(`https://api.github.com/repos/${owner}/${repo}`);
    if (!response.ok) throw new Error(`GitHub API error: ${response.status}`);
    return await response.json();
  },
});
```

## Internal Action

```ts
export const sendWebhook = zia({
  args: { url: z.string().url(), payload: z.record(z.unknown()) },
  handler: async (ctx, { url, payload }) => {
    await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
  },
});
```

## Database Access

Actions cannot access `ctx.db`. Use `ctx.runQuery` and `ctx.runMutation`:

```ts
import { internal } from "./_generated/api";

export const syncFromGitHub = zia({
  args: { projectId: zx.id("projects") },
  handler: async (ctx, { projectId }) => {
    const project = await ctx.runQuery(internal.projects.getById, { id: projectId });
    if (!project) throw new Error("Project not found");

    const response = await fetch(`https://api.github.com/repos/${project.fullName}/releases`);
    const releases = await response.json();

    for (const release of releases) {
      await ctx.runMutation(internal.releases.upsertFromGitHub, {
        projectId,
        tagName: release.tag_name,
        body: release.body,
      });
    }
  },
});
```

## Scheduling Follow-up Functions

```ts
export const processWithRetry = zia({
  args: { taskId: zx.id("tasks"), attempt: z.number().default(1) },
  handler: async (ctx, { taskId, attempt }) => {
    try {
      // ... external API call
    } catch (error) {
      if (attempt < 3) {
        await ctx.scheduler.runAfter(5000, internal.tasks.processWithRetry, {
          taskId,
          attempt: attempt + 1,
        });
      }
    }
  },
});
```

## Context API

- `ctx.auth` — Authentication info
- `ctx.runQuery(internal.module.fn, args)` — Call a query
- `ctx.runMutation(internal.module.fn, args)` — Call a mutation
- `ctx.runAction(internal.module.fn, args)` — Call another action
- `ctx.scheduler.runAfter(delay, internal.module.fn, args)` — Schedule a function

## Client Side — Service Layer

```ts
// src/services/github.ts
import { api } from "@convex";
import { useAction } from "convex/react";

export function useFetchGitHubRepo() {
  return useAction(api.github.fetchGitHubRepo);
}
```

```tsx
function ImportRepo() {
  const fetchRepo = useFetchGitHubRepo();

  async function handleImport(owner: string, repo: string) {
    const data = await fetchRepo({ owner, repo });
    console.log(data.name, data.stargazers_count);
  }

  return <button onClick={() => handleImport("vercel", "next.js")}>Import</button>;
}
```

## Acceptance checklist

- [ ] Action uses `za` (public) or `zia` (internal)
- [ ] Args validated with Zod, returns typed where applicable
- [ ] Database access uses `ctx.runQuery` / `ctx.runMutation`, not `ctx.db`
- [ ] Client hook uses `useAction` in `src/services/`
