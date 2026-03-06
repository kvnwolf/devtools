# Skill with scripts — deterministic operations

Scripts handle repeatable, fragile operations the agent shouldn't reinvent.

```markdown
---
name: validate-schema
description: Validates JSON schemas against data files. Use when checking schema compliance, validating API contracts, or testing data shapes.
---

## Step 1: Validate the schema

Run the validation script against the target file:

```bash
bun scripts/validate.ts <schema-path> <data-path>
```

The script outputs errors with line numbers and expected types. Fix each error before proceeding.

## Step 2: Generate types (optional)

If the user wants TypeScript types from the schema:

```bash
bun scripts/generate-types.ts <schema-path> --output <output-path>
```

## Acceptance checklist

- [ ] Schema validates without errors
- [ ] Types generated if requested
- [ ] No manual validation — always use scripts
```

## Directory structure

```
validate-schema/
├── SKILL.md
└── scripts/
    ├── validate.ts        # Validates data against schema
    └── generate-types.ts  # Generates TS types from schema
```

## Why this works

- Validation is deterministic — same input, same output
- Scripts handle error formatting consistently
- Agent never writes validation logic inline
- Scripts executed with `bun`, code never enters context
