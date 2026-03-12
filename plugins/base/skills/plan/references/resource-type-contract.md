# Resource Type Contract

A resource is a pointer to something an agent needs during a specific phase of work — a skill to follow, a command to run, a file to use as reference, or an inline instruction to apply.

## Schema

```yaml
type: skill | command | file | prompt
value: "<identifier>"
purpose: "<why this resource is relevant>"
```

## Types

### skill

A reference to an installed skill that provides domain knowledge or patterns for a specific capability.

- `value`: the skill name as it appears in the system prompt (e.g., `unit-testing`, `agent-browser`)
- Use when the step requires following specific patterns, conventions, or workflows that a skill encapsulates

```yaml
- type: skill
  value: unit-testing
  purpose: Unit test patterns and execution
```

### command

A CLI command to execute directly. Primarily used for verification steps.

- `value`: the full command (e.g., `bun run typecheck`, `bun test`)
- Use for build, lint, typecheck, test, and other deterministic verification steps

```yaml
- type: command
  value: bun run typecheck
  purpose: Type checking
```

### file

A project file that serves as a pattern reference. Points the agent to an existing file to follow its conventions, structure, or approach.

- `value`: path relative to the project root (e.g., `src/lib/logger.ts`)
- Use when an existing file demonstrates the pattern the agent should follow — not to tell it what file to edit, but what to learn from

```yaml
- type: file
  value: src/lib/logger.ts
  purpose: Application logger — follow this pattern for structured logging
```

### prompt

An inline instruction or guideline to apply during a specific phase of work.

- `value`: a concise, actionable instruction
- Use as a fallback when no skill covers the capability — the prompt provides the guidance directly instead of delegating to a skill

```yaml
- type: prompt
  value: Extract duplicated logic into shared utilities, simplify complex conditionals, and ensure consistent naming
  purpose: Refactoring guidelines when no dedicated refactoring skill is available
```
