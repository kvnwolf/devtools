---
name: create-skill
description: Creates or modifies agent skills. Use when the user wants to create, write, author, scaffold, edit, update, fix, or refactor a skill.
---

## Step 1: Gather context

Ask the user what the skill should do, when it should activate, and any conventions it should follow.

## Step 2: Write the frontmatter

Only `name` and `description` loaded at startup — agent decides whether to load the skill based on description alone.

```yaml
---
name: kebab-case-name
description: [What it does, third person]. Use when [activation triggers].
---
```

### Description rules

- Third person always — "Generates X", never "I help" or "You can use"
- First sentence = capability, second = "Use when [triggers]"
- Include synonyms and colloquial phrasing to maximize activation surface
- Optionally add "Do not use for [X]" to reduce false positives
- <200 chars ideal, 1024 max

```yaml
# Good
description: Generates conventional commit messages from staged changes. Use when committing code, writing commit messages, or preparing a release.

# Bad — vague
description: Helps with git stuff.

# Bad — first person
description: I can help you write commit messages.
```

## Step 3: Write the body

Sacrifice grammar for concision and scannability. Every line must justify its token cost — only include what the agent doesn't already know.

### Principles

- **Freedom matching** — prescriptive for fragile ops, flexible for open-ended tasks
- **Examples over rules** — concrete input/output pairs teach better than abstract descriptions
- **No over-explaining** — the agent knows what PDFs are, how imports work, etc.

### Format

- `##` headings for steps or sections
- Procedural skills: `## Step N: [Action]`
- Reference skills: `## Quick Start` → `## Patterns` → `## Advanced`
- Before/after examples for transformations
- Tables for quick-reference lookups
- Checklists for complex multi-step workflows
- Always end with `## Acceptance checklist` — agent verifies all steps completed before finishing
- Consistent terminology — one term per concept
- No time-sensitive info
- Reference paths as inline code: `references/foo.md`, never markdown links

See `examples/` for complete skill examples by type:

| Example | When to use |
|---------|-------------|
| `examples/minimal.md` | Simple single-file skill, no folders |
| `examples/procedural.md` | Defined steps, defined outputs |
| `examples/open-ended-with-examples.md` | Output varies by use case |
| `examples/with-scripts.md` | Deterministic operations |
| `examples/with-references.md` | Conditional/alternate flows |
| `examples/reference-style.md` | Knowledge base, no steps |
| `examples/combined.md` | Scripts + examples + references |

## Step 4: Organize the directory

```
skill-name/
├── SKILL.md           # Required — <200 lines
├── scripts/           # Optional — deterministic executable code
│   └── setup.ts
├── examples/          # Optional — sample output per use case
│   ├── bug-fix.md
│   └── refactor.md
└── references/        # Optional — conditional flows, on-demand
    └── advanced.md
```

### scripts/

Deterministic, repeatable operations (validation, scaffolding, setup). Executed, not read — code never enters context, only output.

- Run with `bun`: `bun scripts/setup.ts`
- Name by function: `validate_form.ts`, `scaffold.ts`
- Handle errors explicitly — never delegate to agent

### examples/

Sample files for open-ended output not fully defined in SKILL.md. One file per use case.

- NOT needed for closed procedures where output is specified in steps
- Reference: "See `examples/` for sample outputs"

### references/

Conditional flows, alternate paths, domain knowledge not always needed. Loaded on-demand — zero tokens until needed.

- One level deep — never reference a reference
- TOC for files >100 lines

## Acceptance checklist

- [ ] Description: third person, specific, activation triggers
- [ ] Only info the agent doesn't already know
- [ ] Concise, scannable, no unnecessary prose
- [ ] Concrete examples, consistent terminology
- [ ] No time-sensitive info
- [ ] <200 lines or split into references/examples
- [ ] scripts/ run with `bun`, handle errors
- [ ] examples/ only for open-ended output
- [ ] references/ only for conditional flows
- [ ] Paths as inline code, no markdown links
- [ ] Ends with `## Acceptance checklist`
