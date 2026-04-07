---
name: create-plan
description: Plans development tasks through codebase exploration, exhaustive user interviews, and structured file-based plans. Use when tackling a feature, bug fix, refactor, or any task that benefits from upfront planning. Generates plan files in .agents/plans/ for later execution with /execute-plan.
disable-model-invocation: true
argument-hint: "[task description]"
---

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

## 3. Bootstrap plan.config.yml (if needed)

Check whether `.agents/plan.config.yml` exists:

- If it exists, read it and skip to the next step.
- If it does not exist, read `references/plan-config-file-contract.md` and follow its "Initial population" section to create the file. This involves asking the user about their testing, verification, and refactoring skills/commands.

## 4. Interview the user

Read `references/interview-guidelines.md` and follow its methodology to interview the user until you reach a complete, shared understanding of the task.

## 5. Targeted re-exploration

The interview likely revealed areas of the codebase not covered in the initial exploration — specific modules, patterns, edge cases, or integration points that came up in the user's answers.

Launch another Explore agent (medium thoroughness) targeting ONLY the new areas uncovered by the interview. Instruct it to use Glob, Grep, and Read exclusively — never Bash.

After the agent returns, briefly share any significant new findings with the user before proceeding.

## 6. Check for missing skills

This step is MANDATORY — never skip it. Must happen BEFORE generating plan files (new skills affect task file resources).

1. List every technology, library, framework, and domain involved in the task
2. For each one, check if there is an installed skill that covers it (scan skills listed in the system prompt)
3. For any technology/domain NOT covered by an installed skill, invoke `/find-skills` to search for a matching skill
4. Present results to the user and ask which (if any) to install. Install at project scope only — never global
5. Only after confirming all technologies are covered (or the user explicitly declines installing), proceed to the next step

## 7. Propose tasks

Read `references/task-decomposition-guidelines.md` and follow it to propose, present, and iterate on an ordered list of atomic tasks with the user until approved.

## 8. Generate plan files

Read the following references and generate the plan artifacts:

1. Read `references/plan-file-contract.md` — generate `plan.yml` and `state.yml`
2. Read `references/task-file-contract.md` — generate a task YAML file for each task in plan.yml, one at a time, in order

The generated plan must be detailed enough to be executed in a fresh session with zero prior context.

## 9. Commit the plan

Stage all generated files (`.agents/plans/<plan-id>/` and `.agents/plan.config.yml` if created) and commit with message: `chore(plan): <plan-name>` (e.g., `chore(plan): user-notifications`). Check if a commit-related skill is available and follow its conventions.

## 10. Final instructions

After the commit, instruct the user:

1. Run `/clear` to free context
2. Run `/execute-plan` (or `/execute-plan <plan-id>`) to begin execution

## Acceptance checklist

- [ ] User's task fully understood through exploration and interview
- [ ] Targeted re-exploration completed after interview
- [ ] `plan.config.yml` exists (created or pre-existing)
- [ ] Missing skills identified and offered via /find-skills
- [ ] Task breakdown proposed, iterated, and approved by user
- [ ] `plan.yml` generated with all fields populated from exploration and interview
- [ ] `state.yml` initialized
- [ ] Task files generated for every task in plan.yml
- [ ] All YAML content written in English
- [ ] Plan detailed enough to execute in a fresh session with zero context
- [ ] Plan files committed with `chore(plan): <plan-name>`
- [ ] User instructed to /clear and /execute-plan
