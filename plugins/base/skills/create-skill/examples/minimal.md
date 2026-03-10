# Minimal skill — single file, no folders

Simplest possible skill. Everything fits in SKILL.md.

```markdown
---
name: conventional-commits
description: Generates conventional commit messages from staged changes. Use when committing code, writing commit messages, or running git commit.
---

## Format

```
<type>(<scope>): <subject>

<body>
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

## Examples

```
feat(auth): add JWT token refresh

Automatically refresh expired tokens before API calls.
Tokens refreshed 5 minutes before expiry.
```

```
fix(api): handle null response from payment provider

Payment provider returns null on timeout.
Added fallback to retry with exponential backoff.
```

## Acceptance checklist

- [ ] Type matches the change
- [ ] Scope identifies the affected module
- [ ] Subject is imperative, lowercase, no period
- [ ] Body explains WHY, not WHAT
```

## Why this works

- Entire skill fits in ~30 lines
- No folders needed — inline examples are sufficient
- Examples teach format better than rules alone
- Concise, scannable, zero waste
