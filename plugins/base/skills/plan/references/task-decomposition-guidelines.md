# Task Decomposition Guidelines

Using everything gathered from the exploration and interview, propose an ordered list of atomic, vertical-slice tasks that together deliver the full plan. Do this yourself directly — do NOT delegate this to a Plan agent or any other subagent. You already have all the context needed.

## Principles

- **Vertical slices** — each task delivers end-to-end usable functionality across all layers (e.g., schema + backend + frontend), not isolated layers. Never propose a task that only touches one layer unless it genuinely has no cross-layer implications (e.g., a pure config change).
- **Incremental expansion** — each task builds on the previous one, expanding the feature's functionality. Task 1 delivers the minimal working version; each subsequent task adds a new capability on top of what already works.
- **Atomic** — each task must be small enough for a single agent to complete well within 50% of its context window — agent performance degrades severely past that point. A task that would touch 3-4 files is better than one that touches 8-10. Prefer many small tasks over few large ones. If a task feels too broad, split it further.
- **Dependencies** — express which tasks depend on which. Tasks without dependencies (or whose dependencies are already resolved) can run in parallel.
- **What, not how** — describe what each task should deliver and why, not how to implement it. Never mention specific files to create or modify, commands to run, libraries to install, or implementation details. The "how" is figured out during task file generation by exploring the codebase.
- **Semantic commits** — each task maps to exactly one semantic commit message (e.g., `feat(auth): add login endpoint`).

## Anti-patterns

- **Never create setup-only tasks** — installing dependencies, adding config files, or creating scaffolding is NOT a standalone task. Setup belongs inside the first task that needs it.
- **Never split by component or layer** — "create sidebar header", "create sidebar footer", "create sidebar menu" are horizontal slices of the same component. Instead, task 1 should deliver a working sidebar with basic navigation, and task 2 should expand it with user menu functionality.
- **Never organize agents by domain** — "backend agent" + "frontend agent" is wrong. One agent owns one task from top to bottom.

## Splitting example

Instead of one big "Notification system" task, split into: "Create notification + list endpoint + empty state page", "Mark single notification as read with optimistic UI", "Mark all as read with optimistic UI", "Unread badge with polling", "Cross-tab sync for badge", "E2E tests for notification flow". Each is small, vertical, and independently verifiable.

## Final e2e task

If the plan involves user-facing changes, always add a final task that writes end-to-end tests covering the complete user flow. This task depends on ALL other tasks and verifies the entire feature works together. Its commit message follows the pattern `test(<scope>): add e2e tests for <feature>`.

Skip this task only for plans that are purely backend, library, or refactoring work with no user-facing flow to test.

## How to propose

Present the tasks to the user as a markdown table with the following columns:

| # | Task | Description | Depends on |
|---|------|-------------|------------|
| 1 | <title> | <1-2 sentences: what this task delivers end-to-end> | — |
| 2 | <title> | <1-2 sentences> | 1 |

Present the table in the user's language. However, the plan.yml and task YAML files generated in later steps must always be written in English regardless of the user's language.

## Iterate until approved

After presenting the proposal, ask the user with AskUserQuestion:

- question: "Does this task breakdown look right?"
- header: "Tasks"
- options:
  1. label: "Approve", description: "The tasks, order, and dependencies are correct — proceed to plan generation"
  2. label: "Modify", description: "I want to change, add, remove, or reorder some tasks"
  3. label: "Start over", description: "The breakdown misses the point — let's rethink the approach"

If the user selects **Modify**, ask them what they want to change (free-form), apply their feedback, present the updated proposal, and ask again. Repeat until approved.

If the user selects **Start over**, go back to the interview phase and ask what was missed.

If the user selects **Approve**, proceed to the next step.
