# Combined skill — scripts + examples + references

Full structure for complex skills that need all three folders.

```markdown
---
name: create-component
description: Generates UI components following project conventions. Use when creating new components, building UI elements, or scaffolding frontend modules.
---

## Step 1: Ask about the component

Ask: component name, purpose, and whether it needs state management or API calls.

## Step 2: Scaffold with script

```bash
bun scripts/scaffold.ts <component-name>
```

Creates the component directory with boilerplate files.

## Step 3: Implement the component

See `examples/` for component patterns matching the use case:
- Static display component → `examples/static.md`
- Interactive with state → `examples/stateful.md`
- Data-fetching → `examples/data-fetching.md`

## Step 4: Add tests

Create `<component-name>.test.tsx` co-located with the component.

## Step 5: Accessibility (if applicable)

See `references/a11y.md` for ARIA patterns and keyboard navigation.

## Acceptance checklist

- [ ] Component scaffolded via script
- [ ] Implementation matches use case pattern
- [ ] Tests cover primary interactions
- [ ] Accessibility addressed if interactive
```

## Directory structure

```
create-component/
├── SKILL.md
├── scripts/
│   └── scaffold.ts          # Creates component directory + boilerplate
├── examples/
│   ├── static.md            # Display-only component
│   ├── stateful.md          # Component with local state
│   └── data-fetching.md     # Component with API calls
└── references/
    └── a11y.md              # Accessibility patterns (conditional)
```

## Why this works

- scripts/ for deterministic scaffolding — same structure every time
- examples/ for open-ended implementation — each component is different
- references/ for conditional a11y flow — not every component needs it
- Each folder serves a distinct purpose, no overlap
