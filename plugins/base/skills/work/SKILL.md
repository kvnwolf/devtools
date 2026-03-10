---
name: work
description: Plans and executes development tasks through codebase exploration, exhaustive user interviews, and structured plan mode. Use when tackling a feature, bug fix, refactor, or any task that benefits from upfront planning.
disable-model-invocation: true
argument-hint: "[task description]"
---

Do NOT enter plan mode yet — steps 1 through 4 run in normal mode so that Bash and tools remain available.

## 1. Gather task description

If `$ARGUMENTS` is empty, ask the user in plain text what they want to do. Do NOT use `AskUserQuestion` here — just output the question as regular text and wait for their free-form response.

## 2. Explore the project

Launch one Explore agent (medium thoroughness). Instruct it to use Glob, Grep, and Read exclusively — never Bash.

Explore the areas of the codebase relevant to the user's task description. Look for:
- Existing patterns, conventions, and architecture in the affected areas
- Related modules, types, and interfaces
- How similar functionality is structured elsewhere in the codebase
- How existing tests are written in the affected areas — test patterns, helpers, co-location conventions, naming conventions
- How similar features are tested (unit, e2e) to replicate the same approach

After the agent returns, present a concise summary to the user covering relevant code areas, patterns, architecture, and how the task fits into the existing codebase. This checkpoint lets the user correct misunderstandings before the interview.

## 3. Interview the user

Interview relentlessly about every aspect of the task until you reach a complete, shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. The goal is ZERO remaining questions or assumptions by the end.

**How to interview:**
- Use `AskUserQuestion` for every question. Reserve free-form text only when answers are too open-ended to anticipate as options.
- Ask one focused question at a time. Do not bundle unrelated topics.
- Let answers guide the next question. Follow up on anything ambiguous before moving to a new topic.
- Use codebase exploration findings to ask informed, specific questions — not generic ones.
- Challenge assumptions — ask about things the user might not have considered (reserved words colliding with slugs, what happens when an entity is inactive, auth bypass for admins, rollback on partial failure, etc.).
- Cover all dimensions: behavior, edge cases, error states, interactions with existing code, constraints, tradeoffs, routing, auth/permissions, loading/empty/error states, validation rules, data shape, and how new features connect to existing UI.
- When an answer opens up 2-3 follow-up topics, pursue them ALL before moving on. Answers frequently reveal entire new areas (e.g., "redirect by role" opens questions about what happens per role, what if not authenticated, what if not a member, what about public routes).
- When the user's answer changes a previous decision (e.g., switching from drawer to detail page), immediately explore all implications of the change.

**When to stop — ALL must be true:**
- Every ambiguity resolved
- All edge cases and possible states identified and addressed
- All technical decisions made
- Enough information to implement without guessing
- You have mentally walked through the entire user flow step by step and questioned every transition
- You have considered every entity state (created, active, inactive, deleted) and what the UI shows for each
- You have considered every user role and what they can/can't do
- You have considered every route and what happens for authenticated, unauthenticated, authorized, and unauthorized users

Only then ask one final confirmation: whether there is anything else to add. This final question comes AFTER genuinely exhausting all questions — not as a shortcut to stop early.

**Anti-patterns:**
- Batching questions — if 5 remain, ask them across 5 turns
- Stopping because the user seems impatient — thoroughness prevents rework
- Skipping follow-ups — if an answer raises new questions, pursue them immediately
- Presenting a recap and asking "shall I proceed?" as a way to end the interview early — if you can think of even ONE more question, you are not done. Recaps are not a stopping signal.
- Asking "anything else to add?" before you have genuinely run out of questions — this is the LAST question, not an escape hatch

## 4. Check for missing skills

This step is MANDATORY — never skip it. Must happen BEFORE entering plan mode (Bash is unavailable in plan mode).

1. List every technology, library, framework, and domain involved in the task
2. For each one, check if there is an installed skill that covers it (scan skills listed in the system prompt)
3. For any technology/domain NOT covered by an installed skill, invoke `/find-skills` to search for a skill that covers it
4. Present results to the user and ask which (if any) to install. Install at project scope only — never global
5. Only after confirming all technologies are covered (or the user explicitly declines installing), proceed to the next step

## 5. Enter plan mode and build the plan

Call `EnterPlanMode`. Build a detailed implementation plan incorporating everything gathered from exploration, interview, and installed skills. The plan should be detailed enough to be executed in a fresh session with zero prior context.

The generated plan MUST include:

**Relevant skills section:** list the skills identified in step 4 that are relevant to the task. Format as a note at the top of the plan instructing the executing agent to consult these skills during development.

**Tasks with dependencies (non-negotiable: small vertical slices, one agent per task):** break the work into the SMALLEST possible vertical slices. Each task must be small enough that a team member can complete it well within 50% of its context window — agent performance degrades severely past that point. A task that would touch 3-4 files is better than one that touches 8-10. Prefer many small tasks over few large ones.

Rules:
- Every task is a vertical slice — never split by layer (e.g., "schema task" + "endpoint task" + "UI task"). Instead, one task covers the full stack for ONE narrow piece of functionality.
- Never organize agents by domain (e.g., "backend agent" + "frontend agent") — one agent owns one task from top to bottom.
- Each task includes its own tests (unit, and e2e if applicable).
- Each task is assigned to ONE dedicated agent.
- Tasks with no dependencies between them can be executed in parallel.
- Format each task with a clear dependency declaration so the execution order and parallelism opportunities are obvious.

Example of splitting: instead of one big "Notification system" task, split into: "Create notification + list endpoint + empty state page", "Mark single notification as read with optimistic UI", "Mark all as read with optimistic UI", "Unread badge with polling", "Cross-tab sync for badge", "E2E tests for notification flow". Each is small, vertical, and independently verifiable.

**Team execution instructions (CRITICAL — this is non-negotiable):** the plan must include a prominent, unmissable section at the top instructing:

> **MANDATORY: All work MUST be executed via an agents team. NEVER use the Agent tool — team members created with that tool do NOT have access to project skills. You MUST use TeamCreate, SendMessage, TaskCreate, TaskGet, TaskList, and TaskUpdate exclusively.**
>
> You are strictly a coordinator. You NEVER write code, edit files, or execute commands yourself — no matter how small the task. Your only job is to:
> 1. Create a dedicated branch for this plan (e.g., feat/plan-description) and switch to it
> 2. Call TeamCreate to create an agents team
> 3. Use TaskCreate to create a task for each piece of work, then SendMessage to dispatch unblocked tasks to team members in parallel. Each team member MUST work in its own worktree for isolation.
> 4. Each team member must commit its work when done. Once a team member completes its task, merge its worktree branch into the plan branch immediately — this unblocks dependent tasks that need those changes.
> 5. Use TaskGet/TaskList/TaskUpdate to track progress, update task status, and monitor which tasks are complete
> 6. As tasks complete, merge their branch into the plan branch, then dispatch newly unblocked tasks via SendMessage
> 7. Relay user feedback or corrections to the appropriate team member via SendMessage
> 8. When all tasks are complete, inform the user and suggest running /commit to commit, push, and open a PR

**TDD red-green-refactor workflow:** the plan must instruct that every task follows TDD:
1. Red — write tests first that fail (the feature doesn't exist yet)
2. Green — implement the minimum code to make tests pass
3. Refactor — use /simplify on changed files to clean up, then verify tests still pass

**E2e tests:** for tasks where end-to-end testing applies (user-facing flows, multi-step interactions), the plan must include writing e2e tests after implementation to verify the complete flow works.

**UI verification:** for tasks that involve UI work, the plan must instruct the agent to verify the work visually using /agent-browser while developing — not just at the end, but as part of the implementation loop.

After writing the plan, call `ExitPlanMode` to present it to the user.

## Acceptance checklist

- [ ] User's task fully understood through exploration and interview
- [ ] Missing skills identified and offered via /find-skills (before plan mode)
- [ ] Plan created in plan mode and presented to user
- [ ] Plan includes relevant skills to consult during development
- [ ] Plan has tasks with explicit dependencies for parallel execution
- [ ] Plan instructs using an agents team for ALL work (executor never writes code directly)
- [ ] Plan instructs TDD red-green-refactor with /simplify for refactor phase
- [ ] Plan includes e2e tests for applicable tasks
- [ ] Plan instructs using /agent-browser for UI verification during development
- [ ] Plan is detailed enough to execute in a fresh session with zero context
- [ ] User reviewed and approved the plan
