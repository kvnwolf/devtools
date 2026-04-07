# Task Decomposition

Build the task list yourself — do NOT delegate to a Plan agent or subagent.

## Principles

- **Vertical slices** — each task delivers end-to-end functionality across all layers (schema + backend + frontend). Never a task that only touches one layer unless it genuinely has no cross-layer implications.
- **Incremental expansion** — task 1 = minimal working version, each subsequent task adds a capability on top.
- **Atomic** — small enough for a single agent to complete within 50% of its context window. 3-4 files better than 8-10. Prefer many small tasks over few large ones.
- **Affected areas** — each task declares which modules/directories it touches. Used to decide parallelism — tasks with overlapping areas run sequentially, non-overlapping run in parallel.
- **Dependencies** — express which tasks depend on which. Tasks without dependencies (or already resolved) and non-overlapping areas can run in parallel.
- **What, not how** — describe what to deliver and why. Never mention specific files, commands, libraries, or implementation details.
- **Semantic commits** — each task maps to one semantic commit message.

## Anti-patterns

- **Never create setup-only tasks** — installing deps, adding config, or scaffolding is NOT standalone. Setup belongs inside the first task that needs it.
- **Never split by component or layer** — "create sidebar header" + "create sidebar footer" are horizontal slices. Task 1 = working sidebar with basic nav, task 2 = expand with user menu.
- **Never organize by domain** — "backend agent" + "frontend agent" is wrong. One agent owns one task top to bottom.

## Splitting example

Instead of one "Notification system" task: "Create notification + list endpoint + empty state page", "Mark single as read with optimistic UI", "Mark all as read", "Unread badge with polling", "Cross-tab sync", "E2E tests for notification flow".

## Final e2e task

If the plan involves user-facing changes, add a final task that writes e2e tests covering the complete user flow. Depends on ALL other tasks. Skip for purely backend, library, or refactoring work.

## How to present

Markdown table in the user's language:

| # | Task | Description | Depends on | Affected areas |
|---|------|-------------|------------|----------------|
| 1 | \<title\> | \<1-2 sentences: what this delivers end-to-end\> | — | \<modules/dirs\> |
| 2 | \<title\> | \<1-2 sentences\> | 1 | \<modules/dirs\> |

## Iterate until approved

After presenting, ask with AskUserQuestion:
- question: "Does this task breakdown look right?"
- header: "Tasks"
- options:
  1. label: "Approve", description: "Tasks, order, and dependencies are correct — proceed"
  2. label: "Modify", description: "I want to change, add, remove, or reorder some tasks"
  3. label: "Start over", description: "The breakdown misses the point — let's rethink"

**Modify** → ask what to change, apply feedback, re-present, ask again.
**Start over** → go back to the interview.
**Approve** → proceed.
