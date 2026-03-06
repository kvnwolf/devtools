# Multi-workflow Skills

## Directory Structure

```
skill-name/
├── SKILL.md                       # Router — flows table only
└── flows/
    ├── setup/
    │   ├── FLOW.md                # Procedural steps — <200 lines
    │   ├── references/            # Large code blocks, configs
    │   │   ├── configs.md
    │   │   └── components.md
    │   └── examples/              # Sample outputs if open-ended
    │       └── basic.md
    └── create-route/
        ├── FLOW.md
        └── references/
            └── patterns.md
```

## SKILL.md Format

The orchestrator SKILL.md contains only:
- Frontmatter with `name` and `description`
- A `## Flows` section with a table routing to each flow

```yaml
---
name: my-framework
description: Provides instructions for working with MyFramework projects. Use when setting up or creating routes in a MyFramework application.
---

## Flows

| Flow | When to use |
|------|-------------|
| `flows/setup/FLOW.md` | Bootstrap a new project from scratch |
| `flows/create-route/FLOW.md` | Add a new route to the application |
```

No title, no intro paragraph — the description already covers that.

## FLOW.md Format

Each flow follows the same rules as a single-workflow SKILL.md:
- <200 lines
- Procedural flows use `## Step N: [Action]`
- Reference flows use `## Quick Start` → `## Patterns` → `## Advanced`
- Ends with `## Acceptance Checklist`
- Can have its own `references/`, `examples/`, `scripts/` subdirectories

## Description Maintenance

The SKILL.md description **must** reflect all available flows. The description is the only thing loaded at startup — if a flow's capability isn't mentioned, the agent won't know to load the skill.

When flows change, update the description immediately:

| Action | Update description |
|--------|-------------------|
| Flow added | Add the new capability to triggers |
| Flow removed | Remove the capability from triggers |
| Flow renamed | Update the trigger wording |

Example evolution:

```yaml
# After setup flow only
description: Provides instructions for working with MyFramework projects. Use when setting up a MyFramework application.

# After adding create-route flow
description: Provides instructions for working with MyFramework projects. Use when setting up or creating routes in a MyFramework application.

# After adding data-fetching flow
description: Provides instructions for working with MyFramework projects. Use when setting up, creating routes, or adding data fetching to a MyFramework application.
```

This is non-negotiable — a stale description means the agent will never activate the skill for new flows, making them invisible.

## When NOT to Use

- Single procedure that just needs references → use single-workflow with `references/`
- Two procedures that always run together → use one flow with multiple steps
- Unrelated procedures → use separate skills, not one orchestrator
