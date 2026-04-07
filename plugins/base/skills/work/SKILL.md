---
name: work
description: Plans and executes development tasks through codebase exploration, user interviews, and coordinated teammates. Use when tackling a feature, bug fix, refactor, or any task that benefits from upfront planning and parallel execution.
disable-model-invocation: true
argument-hint: "[task description]"
---

## Step 1: Gather task description

If `$ARGUMENTS` is empty, ask in plain text what the user wants to do. Do NOT use AskUserQuestion — output the question as regular text and wait.

## Step 2: Explore the project

Launch one Explore agent (medium thoroughness). Instruct it to use Glob, Grep, and Read exclusively — never Bash.

Look for:
- Existing patterns, conventions, and architecture in the affected areas
- Related modules, types, and interfaces
- How similar functionality is structured elsewhere
- Test patterns, helpers, co-location conventions

Present a concise summary to the user covering relevant code areas, patterns, and how the task fits into the existing codebase. This checkpoint lets the user correct misunderstandings before the interview.

## Step 3: Interview the user

Read `references/interview-guidelines.md` and follow its methodology until you reach a complete, shared understanding of the task.

## Step 4: Targeted re-exploration

The interview likely revealed areas not covered in the initial exploration — specific modules, patterns, edge cases, or integration points.

Launch another Explore agent (medium thoroughness) targeting ONLY the new areas. Instruct it to use Glob, Grep, and Read exclusively — never Bash.

Briefly share significant new findings with the user before proceeding.

## Step 5: Check for missing skills

MANDATORY — never skip. Must happen BEFORE entering plan mode.

1. List every technology, library, framework, and domain involved in the task
2. For each one, check if there is an installed skill that covers it (scan skills in the system prompt)
3. For any technology/domain NOT covered, invoke `/find-skills` to search for a matching skill
4. Present results to the user and ask which (if any) to install — project scope only, never global
5. Only after all technologies are covered (or user declines), proceed

## Step 6: Enter plan mode

Enter plan mode. Build the plan from your exploration and interview findings. The plan must include:

**Overview** — problem description and proposed solution (2-4 sentences)

**User flow** — ordered steps the user goes through (omit for backend-only or refactoring tasks)

**Goals** — what the plan achieves

**Non-goals** — what is explicitly out of scope

**Constraints** — technical or business constraints

**Decisions** — key technical decisions from the interview

**Edge cases** — edge case + how to handle it

**Tasks** — read `references/task-decomposition.md` and follow it to build the task table. Each task must include affected areas (modules/directories it will touch) for parallelism decisions.

All plan content must be in English regardless of the user's language.

The plan must be detailed enough to be executed with zero prior context.

## Step 7: Ask about branch

Ask with AskUserQuestion:
- header: "Branch"
- question: "Do you want to create a new branch for this work?"
- options:
  1. label: "Create branch", description: "Create a new branch (e.g., feat/feature-name) and switch to it"
  2. label: "Current branch", description: "Work directly on the current branch"

If "Create branch": derive branch name from the plan (e.g., `feat/user-notifications`), create and switch to it.

## Step 8: Create team and dispatch

You are strictly a coordinator. You NEVER write code, edit files, or execute commands — no matter how small the task. Your only job is to orchestrate.

1. Create the team via `TeamCreate`
2. Create one task per plan task via `TaskCreate` — use the task title as subject and a brief description
3. Identify dispatchable tasks — tasks with no unmet dependencies that touch different areas of the codebase (parallelism by areas). Tasks that share affected areas run sequentially.
4. For each dispatchable task: read `references/teammate-prompt.md`, build the prompt by injecting the task's full context (description, decisions, constraints, steps, affected areas, and the plan overview), then spawn via `Agent` tool:
   - Do NOT set `subagent_type` — must be general-purpose
   - Do NOT set `isolation` — no worktrees
   - The prompt must be the FULL content from the template with all placeholders replaced
5. Assign tasks via `TaskUpdate` with `owner` set to the teammate's name

## Step 9: Monitor and dispatch

Messages from teammates are delivered automatically — do NOT poll.

**When a teammate completes:** present an updated status table to the user.

**Unblocking:** as tasks complete, check if their completion unblocks new tasks. For each newly unblocked task, read `references/teammate-prompt.md`, build the prompt, and spawn a new teammate. Respect area-based parallelism — only dispatch if no running teammate shares the same affected areas.

**Context limit recovery:** if a teammate hits its context limit and stops, spawn a replacement teammate. Include in its prompt what the previous teammate accomplished (from the Agent return message) so it can continue from where it left off.

## Step 10: QA review

After ALL tasks complete, read `references/qa-review.md` and follow its flow. Fix teammates use the same scheme — team membership, no worktrees, no commits.

## Step 11: Cleanup and summary

1. Shut down teammates via `SendMessage` with `type: "shutdown_request"`. Skip unresponsive agents.
2. Clean up the team via `TeamDelete`. If it fails because an agent is still active, inform the user which agent is stuck and ask them to terminate it manually, then retry.
3. Present a final summary of what was accomplished.

## Acceptance checklist

- [ ] Task description gathered
- [ ] Initial exploration completed with checkpoint
- [ ] Interview exhausted all ambiguity
- [ ] Targeted re-exploration completed after interview
- [ ] Missing skills identified and offered via /find-skills
- [ ] Plan approved in plan mode (overview, goals, decisions, edge cases, tasks with affected areas)
- [ ] Branch question asked and handled
- [ ] Team created via TeamCreate
- [ ] Tasks created via TaskCreate
- [ ] Every teammate spawned without `isolation` and without `subagent_type`
- [ ] Area-based parallelism respected — no two concurrent teammates share affected areas
- [ ] Status tables shown after each task completion
- [ ] Context limit recoveries handled by spawning replacements with prior progress
- [ ] QA review completed — gaps identified and fixed
- [ ] Team shut down and cleaned up
- [ ] Final summary presented
- [ ] No commits made by coordinator or teammates
