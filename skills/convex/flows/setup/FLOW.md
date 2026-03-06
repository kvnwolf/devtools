## Prerequisites

**IMPORTANT:** Complete these before Step 1. Later steps depend on `convex/_generated/` and `.env.local`. Do NOT proceed with step 1 until finishing setting up the prerequisites. The below instructions MUST be run IN ORDER.

1. Install dependencies — `convex` must be in `package.json` before `make setup` can run `convex env list`:

```bash
bun add convex zodvex convex-helpers @convex-dev/react-query
bun add -d convex-test @edge-runtime/vm
```

2. Update `.env.example` — add `SITE_URL=http://localhost:3000`
3. Copy `.env.example` to `.env.local`: `cp .env.example .env.local`
4. Update `scripts/setup.ts` — add the functions below **and** their top-level calls in a single edit to avoid hoisting issues. Do NOT make different edits, both the function calls AND the definitions MUST be added in the SAME edit:

```ts
async function startConvex() {
  spawn(["convex", "dev", "--local"], {
    env: { ...process.env, CONVEX_AGENT_MODE: "anonymous" },
  });

  for (let i = 0; i < 30; i++) {
    const result = spawn(["bun", "convex", "env", "list"]);
    if ((await result.exited) === 0) {
      console.log("Convex local backend started");
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  throw new Error("Convex local backend did not start in time");
}

async function setupConvexEnvVars() {
  const envVars = ["SITE_URL"];
  const configured: string[] = [];

  for (const name of envVars) {
    const value = process.env[name];
    if (!value) continue;
    await spawn(["bun", "convex", "env", "set", name, value]).exited;
    configured.push(`${name}=${value}`);
  }

  console.log(`Convex configured: ${configured.join(", ")}`);
}

async function stopConvex() {
  const result = spawn(["lsof", "-ti", ":3210"], { stdout: "pipe" });
  const output = await new Response(result.stdout).text();
  for (const pid of output.trim().split("\n").filter(Boolean)) {
    try {
      process.kill(Number(pid));
    } catch {
      // noop
    }
  }
}
```

New env vars go in both `.env.example` and the `envVars` array in `scripts/setup.ts`.

5. Add tests for the new functions to `scripts/setup.test.ts`:

Import the new functions alongside the existing ones:

```ts
const { installDependencies, installGitHooks, setupRemoteCache, startConvex, setupConvexEnvVars, stopConvex } = await import("./setup");
```

Add these test blocks:

```ts
describe("startConvex", () => {
  test("resolves when convex env list succeeds", async () => {
    mockSpawn.mockClear();
    await startConvex();
    expect(mockSpawn).toHaveBeenCalledWith(["convex", "dev", "--local"], {
      env: expect.objectContaining({ CONVEX_AGENT_MODE: "anonymous" }),
    });
  });
});

describe("setupConvexEnvVars", () => {
  test("sets env vars via convex env set", async () => {
    process.env.SITE_URL = "http://localhost:3000";
    mockSpawn.mockClear();
    await setupConvexEnvVars();
    expect(mockSpawn).toHaveBeenCalledWith(
      ["bun", "convex", "env", "set", "SITE_URL", "http://localhost:3000"],
    );
  });
});

describe("stopConvex", () => {
  test("kills processes on port 3210", async () => {
    mockSpawn.mockReturnValueOnce({
      exited: Promise.resolve(0),
      stdout: new Blob(["1234\n"]),
    });
    const killSpy = vi.spyOn(process, "kill").mockImplementation(() => true);
    await stopConvex();
    expect(killSpy).toHaveBeenCalledWith(1234);
    killSpy.mockRestore();
  });
});
```

6. Run `make setup` — do NOT continue until this completes.

```bash
make setup
```

## Step 1: Update package.json scripts

1. Add `dev:convex`: `convex dev --local`
2. Add `vercel-build`: `convex deploy --cmd 'bun turbo run build'`

Vercel env vars required: `CONVEX_DEPLOY_KEY` (Production key for Production, Preview key for Preview).

## Step 4: Update turbo.json

1. Add `dev:convex` with `"cache": false` and `"persistent": true`
2. Add `dev:convex` to the `dev` task's `"with"` array

## Step 5: Update tsconfig.json

1. Add `"@convex": ["./convex/_generated/api"]` and `"@convex/*": ["./convex/*"]` to `compilerOptions.paths`
2. Add `"convex"` to the `exclude` array

## Step 6: Update src/lib/env.ts

Add to `client`:

```ts
VITE_CONVEX_URL: z.string().url(),
VITE_CONVEX_SITE_URL: z.string().url(),
```

## Step 7: Create convex/utils.ts

```ts
import { zActionBuilder, zMutationBuilder, zQueryBuilder } from "zodvex/server";
import {
  action,
  internalAction,
  internalMutation,
  internalQuery,
  mutation,
  query,
} from "./_generated/server";

export const zq = zQueryBuilder(query);
export const zm = zMutationBuilder(mutation);
export const za = zActionBuilder(action);

export const ziq = zQueryBuilder(internalQuery);
export const zim = zMutationBuilder(internalMutation);
export const zia = zActionBuilder(internalAction);
```

## Step 8: Create convex/schema.ts

```ts
import { defineSchema } from "convex/server";

export default defineSchema({});
```

## Step 9: Update src/router.tsx

1. Add imports:

```ts
import { ConvexQueryClient } from "@convex-dev/react-query";
import { ConvexProvider } from "convex/react";
```

2. Replace `QueryClient` instantiation in `getRouter()`:

```ts
const convexQueryClient = new ConvexQueryClient(env.VITE_CONVEX_URL);

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryKeyHashFn: convexQueryClient.hashFn(),
      queryFn: convexQueryClient.queryFn(),
    },
  },
});

convexQueryClient.connect(queryClient);
```

3. Add `Wrap` to `createRouter` options:

```ts
Wrap: ({ children }) => (
  <ConvexProvider client={convexQueryClient.convexClient}>{children}</ConvexProvider>
),
```

## Step 10: Update vitest.config.ts

Add a `convex` project to `test.projects`:

```ts
{
  test: {
    name: "convex",
    include: ["convex/**/*.test.ts"],
    environment: "edge-runtime",
    server: { deps: { inline: ["convex-test"] } },
  },
}
```

## Step 11: Update playwright.config.ts

Replace single `webServer` with array:

```ts
webServer: [
  {
    command: "bun run dev:convex",
    port: 3210,
    reuseExistingServer: true,
  },
  {
    command: "node .output/server/index.mjs",
    port: 3000,
    reuseExistingServer: true,
  },
],
```

## Step 12: Update CI workflow

1. Add env vars to the job:

```yaml
env:
  SITE_URL: http://localhost:3000
  CONVEX_AGENT_MODE: anonymous
```

2. Replace `bun install` with `make setup`

## Step 13: Update knip config

1. Add `"convex/**"` to `ignore` (Convex files are not imported from `src/`)
2. Add `"convex-test"`, `"convex-helpers"`, and `"zodvex"` to `ignoreDependencies` (used in `convex/`, which knip doesn't scan)

## Step 14: Update AGENTS.md

Add `- **Backend:** Convex` to the Tech Stack section.

## Acceptance checklist

- [ ] Dependencies installed (convex, zodvex, convex-helpers, @convex-dev/react-query, convex-test, @edge-runtime/vm)
- [ ] .env.example updated with SITE_URL
- [ ] .env.local created from .env.example
- [ ] scripts/setup.ts updated with Convex functions and their top-level calls
- [ ] scripts/setup.test.ts updated with tests for startConvex, setupConvexEnvVars, stopConvex
- [ ] step #1 didn't ran until the prerequisites finished
- [ ] `make setup` ran successfully
- [ ] package.json has dev:convex and vercel-build scripts
- [ ] turbo.json has dev:convex task wired to dev
- [ ] tsconfig.json paths and exclude updated
- [ ] src/lib/env.ts includes Convex env vars
- [ ] convex/utils.ts created
- [ ] convex/schema.ts created
- [ ] src/router.tsx updated with ConvexQueryClient and ConvexProvider
- [ ] vitest.config.ts has convex project
- [ ] playwright.config.ts has Convex webServer
- [ ] CI workflow updated
- [ ] knip config updated
- [ ] AGENTS.md updated with Convex in Tech Stack
- [ ] `make validate` passes
