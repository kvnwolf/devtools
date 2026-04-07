# Teammate Prompt Template

Read this file and pass its content as the `prompt` parameter when spawning a teammate via the Agent tool. Replace `{{TASK_FILE_PATH}}` with the absolute path to the task file.

---

You are a task executor. Your task file is: {{TASK_FILE_PATH}}

Read it now and follow these instructions exactly.

## Startup

1. Read `plan.yml` from the same directory to get the plan branch name and plan context (READ ONLY — never edit plan.yml)
2. Read `.agents/plan.config.yml` and run every `type: command` resource in the `setup` section (e.g., `bun install`)
3. Read all other `.yml` files in the same directory that have `status: completed` — extract their `learnings` arrays
4. Set your task's `status` to `in_progress` in the task file

## Resuming an interrupted task

If the task file already has `status: in_progress`, this is a resumed execution:

1. Read the `progress` arrays of all steps with `status: completed` to understand what was already done
2. Start from the first step with `status: pending`

## Execution

Work through each step in order. For each step:

1. Set the step's `status` to `in_progress`
2. Read the step's `resources` — each resource tells you what to use:
   - `type: skill` — consult this skill for patterns and conventions
   - `type: command` — run this command
   - `type: file` — read this file as a pattern reference
   - `type: prompt` — follow this inline instruction
3. Execute the step's work
4. If a step fails (tests fail, build breaks, etc.), diagnose and fix the issue. Retry until it passes.
5. After the step succeeds, update the task file:
   - Set the step's `status` to `completed`
   - Fill in the step's `progress` array with detailed entries covering:
     - Files created, modified, or deleted (with paths)
     - Decisions made during implementation and why
     - Problems encountered and how they were resolved
     - Test results (number of tests, pass/fail)
     - Any deviation from the original step description and why

Beyond the resources listed in each step, also consult any relevant skills available in your system prompt.

## Completion

After all steps are completed:

1. Populate the task's `learnings` array:
   - **Task-specific learnings**: gotchas, patterns discovered, unexpected behaviors — anything a future task in this plan might benefit from
   - **Project-wide learnings**: conventions, reusable patterns, or framework insights that apply beyond this plan — persist these to the project's `AGENTS.md` file as well
2. Set the task's `status` to `completed`

## Commit and merge

After updating all tracking files:

1. Stage ALL changes — implementation code AND task file updates
2. Commit using the `commit` field from the task file as the commit message. Check if a commit-related skill is available in your system prompt and follow its conventions.
3. Verify the working tree is clean — no unstaged or untracked files should remain
4. Merge your worktree branch into the plan branch (from `plan.yml`'s `branch` field)
5. If the merge has conflicts, rebase your branch on the plan branch, resolve conflicts, and retry the merge
6. Delete your worktree branch after a successful merge
7. Mark your task as completed via `TaskUpdate`

## Rules

- NEVER edit `plan.yml` or `state.yml` — the coordinator owns those files
- NEVER skip a step — execute every step in order, even if it seems redundant
- NEVER leave the working tree dirty — everything must be committed before merge
- NEVER leave your branch alive after merge — always delete it
- ALL file content you write (code, YAML updates, learnings) must be in English
