---
name: base
description: Scaffolds a new TypeScript project from scratch. Use when starting a new project, bootstrapping a codebase, or setting up a project from zero.
---

## Step 1: Ask about the project

Ask the user to describe what the project is about. Use their response to populate `<project-name>` and `<project-description>` in later steps.

## Step 2: Create package.json

```json
{
  "name": "<project-name>",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "lint": "biome check",
    "setup": "bun run scripts/setup.ts",
    "types": "tsgo --build",
    "test": "vitest run",
    "unused": "knip",
    "update": "taze --interactive"
  },
  "dependencies": {},
  "devDependencies": {},
  "simple-git-hooks": {
    "pre-commit": "bun run turbo validate"
  },
  "knip": {
    "ignoreDependencies": [
      "turbo"
    ]
  },
  "packageManager": "bun@<current-bun-version>"
}
```

Replace `<current-bun-version>` with the output of `bun --version`.

## Step 3: Install dependencies

```bash
bun add -d @biomejs/biome @types/bun @typescript/native-preview knip simple-git-hooks taze turbo ultracite vitest
```

## Step 4: Create scripts/setup.ts

```ts
import { file, spawn } from "bun";

await installDependencies();
await installGitHooks();
await setupRemoteCache();

export async function installDependencies() {
  await spawn(["bun", "install"]).exited;
  console.log("Dependencies installed");
}

export async function installGitHooks() {
  await spawn(["bunx", "simple-git-hooks"]).exited;
  console.log("Git hooks installed");
}

export async function setupRemoteCache(isRetry?: boolean) {
  const config = file(".turbo/config.json");

  if (!((await config.exists()) && (await config.json()).teamId)) {
    const stdio = isRetry ? "inherit" : "pipe";
    const link = spawn(["turbo", "link"], { stdio: [stdio, stdio, stdio] });

    if ((await link.exited) !== 0) {
      const error = await new Response(link.stderr).text();
      if (error.includes("User not found")) {
        await spawn(["turbo", "login"]).exited;
        await setupRemoteCache();
        return;
      }
      if (error.includes("IO error")) {
        await setupRemoteCache(true);
        return;
      }
    }
  }

  console.log("Turbo remote cache configured");
}
```

## Step 5: Create scripts/setup.test.ts

```ts
import { beforeEach, describe, expect, test, vi } from "vitest";

const mockSpawn = vi.fn().mockReturnValue({
  exited: Promise.resolve(0),
  stderr: new Blob([""]),
});

const mockFile = vi.fn().mockReturnValue({
  exists: () => Promise.resolve(false),
  json: () => Promise.resolve({}),
});

vi.mock("bun", () => ({
  spawn: (...args: unknown[]) => mockSpawn(...args),
  file: (...args: unknown[]) => mockFile(...args),
}));

const { installDependencies, installGitHooks, setupRemoteCache } = await import("./setup");

function spawnReturns(exitCode: number, stderr = "") {
  return mockSpawn.mockReturnValue({
    exited: Promise.resolve(exitCode),
    stderr: new Blob([stderr]),
  });
}

function configReturns(exists: boolean, json: Record<string, unknown> = {}) {
  mockFile.mockReturnValue({
    exists: () => Promise.resolve(exists),
    json: () => Promise.resolve(json),
  });
}

beforeEach(() => {
  mockSpawn.mockClear();
  mockFile.mockClear();
  spawnReturns(0);
  configReturns(false);
});

describe("installDependencies", () => {
  test("runs bun install", async () => {
    await installDependencies();
    expect(mockSpawn).toHaveBeenCalledWith(["bun", "install"]);
  });
});

describe("installGitHooks", () => {
  test("runs bunx simple-git-hooks", async () => {
    await installGitHooks();
    expect(mockSpawn).toHaveBeenCalledWith(["bunx", "simple-git-hooks"]);
  });
});

describe("setupRemoteCache", () => {
  test("skips linking when config already has teamId", async () => {
    configReturns(true, { teamId: "team_123" });
    mockSpawn.mockClear();

    await setupRemoteCache();

    expect(mockSpawn).not.toHaveBeenCalledWith(["turbo", "link"], expect.anything());
  });

  test("runs turbo link with piped stdio on first attempt", async () => {
    await setupRemoteCache();

    expect(mockSpawn).toHaveBeenCalledWith(["turbo", "link"], {
      stdio: ["pipe", "pipe", "pipe"],
    });
  });

  test("runs turbo login then retries on 'User not found' error", async () => {
    mockSpawn
      .mockReturnValueOnce({
        exited: Promise.resolve(1),
        stderr: new Blob(["User not found"]),
      })
      .mockReturnValueOnce({ exited: Promise.resolve(0) })
      .mockReturnValueOnce({ exited: Promise.resolve(0) });
    configReturns(false);

    await setupRemoteCache();

    expect(mockSpawn).toHaveBeenCalledWith(["turbo", "login"]);
  });

  test("retries with inherited stdio on 'IO error'", async () => {
    mockSpawn
      .mockReturnValueOnce({
        exited: Promise.resolve(1),
        stderr: new Blob(["IO error"]),
      })
      .mockReturnValueOnce({ exited: Promise.resolve(0) });

    await setupRemoteCache();

    expect(mockSpawn).toHaveBeenCalledWith(["turbo", "link"], {
      stdio: ["inherit", "inherit", "inherit"],
    });
  });
});
```

## Step 6: Create turbo.json

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "lint": {},
    "types": {},
    "test": {},
    "unused": {},
    "validate": {
      "dependsOn": ["lint", "types", "test", "unused"]
    }
  }
}
```

## Step 7: Create tsconfig.json

```json
{
  "compilerOptions": {
    "allowImportingTsExtensions": true,
    "allowJs": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "incremental": true,
    "isolatedModules": true,
    "lib": ["esnext"],
    "module": "esnext",
    "moduleDetection": "force",
    "moduleResolution": "bundler",
    "noEmit": true,
    "noUncheckedIndexedAccess": true,
    "noUncheckedSideEffectImports": true,
    "skipLibCheck": true,
    "strict": true,
    "target": "esnext",
    "verbatimModuleSyntax": false
  },
  "exclude": ["node_modules"],
  "include": ["**/*.ts"]
}
```

## Step 8: Create biome.jsonc

```jsonc
{
  "$schema": "node_modules/@biomejs/biome/configuration_schema.json",
  "extends": ["ultracite/core"],
  "formatter": {
    "lineWidth": 100
  },
  "linter": {
    "rules": {
      "correctness": {
        "noUnusedImports": "warn"
      }
    }
  }
}
```

## Step 9: Create .gitignore

```
# base
*.local*
*.tsbuildinfo
.DS_Store
.turbo
node_modules
```

## Step 10: Create .github/workflows/ci.yml

```yaml
name: CI

on:
  push:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
      - name: Cache Bun dependencies
        uses: actions/cache@v4
        with:
          path: ~/.bun/install/cache
          key: ${{ runner.os }}-bun-${{ hashFiles('**/bun.lock') }}
          restore-keys: |
            ${{ runner.os }}-bun-
      - name: Install dependencies
        run: bun install
      - name: Validate
        run: bun run turbo validate
        env:
          TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
          TURBO_TEAM: ${{ vars.TURBO_TEAM }}
```

## Step 11: Create vitest.config.ts

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    projects: [
      {
        extends: true,
        test: {
          name: "unit",
          include: ["**/*.test.ts"],
          environment: "node",
        },
      },
    ],
  },
});
```

## Step 12: Create AGENTS.md

```markdown
# <project-name>

<project-description>

## Tech Stack

- **Package manager:** Bun
- **Testing:** Vitest

## Conventions

<!-- Add project-specific conventions here as the codebase evolves -->
```

Then create a symlink so tools that look for `CLAUDE.md` find the same file:

```bash
ln -s AGENTS.md CLAUDE.md
```

## Step 13: Create README.md

```markdown
# <project-name>

<project-description>

## Development

1. Clone this repo
2. Run `bun run setup`

## License

[MIT](LICENSE)
```

## Step 14: Create .agents/commit.config.yml

```yaml
files:
  - path: AGENTS.md
    update_when:
      - When changes in package.json alter the tech stack (not minor version bumps)
      - When new learnings from a task would benefit future agents (conventions, corrections to avoid repeating mistakes)
```

## Acceptance checklist

- [ ] Asked user for project name and description
- [ ] Created `package.json` with correct name, scripts, simple-git-hooks, and knip config
- [ ] Installed devDependencies (`@biomejs/biome`, `@types/bun`, `@typescript/native-preview`, `knip`, `simple-git-hooks`, `taze`, `turbo`, `ultracite`, `vitest`)
- [ ] Created `scripts/setup.ts` with install, git hooks, and remote cache setup
- [ ] Created `scripts/setup.test.ts` with tests for setup functions
- [ ] Created `turbo.json` with lint, types, test, unused, and validate tasks
- [ ] Created `tsconfig.json`
- [ ] Created `biome.jsonc` with ultracite preset
- [ ] Created `.gitignore`
- [ ] Created `.github/workflows/ci.yml`
- [ ] Created `vitest.config.ts`
- [ ] Created `AGENTS.md` with tech stack, commands, and conventions
- [ ] Created `CLAUDE.md` symlink to `AGENTS.md`
- [ ] Created `README.md`
- [ ] Created `.agents/commit.config.yml` with AGENTS.md tracked
