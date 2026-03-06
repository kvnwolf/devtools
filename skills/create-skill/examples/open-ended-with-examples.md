# Open-ended skill — output varies by use case

Output depends on context. examples/ folder shows concrete cases the agent references.

```markdown
---
name: write-pr-description
description: Writes pull request descriptions from branch changes. Use when creating a PR, writing PR descriptions, or preparing code for review.
---

## Step 1: Analyze changes

Read the diff between the current branch and main. Identify scope, motivation, and impact.

## Step 2: Write the description

Follow the structure in the examples. Adapt tone and detail based on change scope:
- Small fix → brief, one section
- Feature → full structure with context and testing notes
- Breaking change → emphasize migration steps

See `examples/` for sample PR descriptions by change type.

## Acceptance checklist

- [ ] Description matches the scope of changes
- [ ] Motivation is clear — reviewer understands WHY
- [ ] Testing notes included if applicable
```

## Directory structure

```
write-pr-description/
├── SKILL.md
└── examples/
    ├── bug-fix.md        # Small fix, brief description
    ├── feature.md        # New feature, full structure
    └── breaking-change.md # Migration-heavy, detailed
```

## Why this works

- Output can't be templated — each PR is different
- examples/ shows the agent what "good" looks like per case
- Agent adapts based on which example best matches the current diff
