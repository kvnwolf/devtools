# Plan Config File Contract

The plan config file (`.agents/plan.config.yml`) stores project-wide resources organized by phase. It is created during the first `/plan` execution and grows incrementally as skills are discovered and agents find useful patterns.

## Schema

Resources follow the contract defined in `resource-type-contract.md`.

```yaml
setup:
  - type: skill | command | file | prompt
    value: "<identifier>"
    purpose: "<why this resource is relevant>"

testing:
  - type: skill | command | file | prompt
    value: "<identifier>"
    purpose: "<why this resource is relevant>"

implementation:
  - type: skill | command | file | prompt
    value: "<identifier>"
    purpose: "<why this resource is relevant>"

verification:
  - type: skill | command | file | prompt
    value: "<identifier>"
    purpose: "<why this resource is relevant>"

refactoring:
  - type: skill | command | file | prompt
    value: "<identifier>"
    purpose: "<why this resource is relevant>"
```

## Phases

### setup

Commands to prepare a worktree before work begins — dependency installation, dev server, and any other initialization steps.

### testing

Resources for writing tests — skills that define test patterns, files that serve as test examples.

### implementation

Resources for writing code — skills that define implementation patterns, files that demonstrate conventions to follow.

### verification

Resources for verifying work — dev server, commands to run (typecheck, lint, test, build), and skills for visual or manual verification.

### refactoring

Resources for improving code after tests pass — skills or prompts that guide refactoring decisions.

## Initial population

When creating the plan config for the first time:

1. **setup** — populate with commands needed to prepare a worktree (e.g., dependency installation).
2. **testing** — ask the user which of their available skills handle test writing (unit, component, e2e). Add one resource per skill.
3. **verification** — add commands for typecheck, lint, test, and build (inferred from `package.json` scripts). Ask the user if they have skills for visual/browser verification.
4. **refactoring** — ask the user if they have a refactoring skill; if not, add a `type: prompt` with general refactoring guidelines.
5. **implementation** — leave empty. Domain-specific skills are discovered later during task file generation and added here incrementally (see `task-file-contract.md` → "Skill discovery").

## Completion preferences

Optional section that controls what happens after all tasks complete. If not present, `/execute` asks the user.

```yaml
completion:
  mode: pr | squash    # pr = push + open PR, squash = squash merge to main
```

- `pr` — push the plan branch and create a pull request
- `squash` — switch to the default branch, squash merge the plan branch, and delete it

When creating the plan config for the first time, do NOT include this section. `/execute` will ask the user on first run and persist their choice here.

## Example

```yaml
setup:
  - type: command
    value: bun install
    purpose: Install dependencies

testing:
  - type: skill
    value: component-testing
    purpose: Unit/component test patterns and execution
  - type: skill
    value: e2e-testing
    purpose: Playwright e2e test patterns and execution

implementation:
  - type: skill
    value: tanstack-form
    purpose: Form patterns with TanStack Form
  - type: file
    value: src/lib/logger.ts
    purpose: Application logger — follow this pattern for structured logging

verification:
  - type: command
    value: bun run typecheck
    purpose: Type checking
  - type: command
    value: bun run lint
    purpose: Linting
  - type: command
    value: bun test
    purpose: Run unit tests
  - type: command
    value: bun run build
    purpose: Production build
  - type: command
    value: bun run dev
    purpose: Start dev server
  - type: skill
    value: agent-browser
    purpose: Visual verification in the browser

refactoring:
  - type: skill
    value: simplify
    purpose: Review changed code for reuse, quality, and efficiency

completion:
  mode: pr
```
