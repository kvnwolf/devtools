# Skill with references — conditional flows

References hold alternate paths not always needed. Loaded on-demand.

```markdown
---
name: setup-auth
description: Adds authentication to an existing project. Use when adding login, auth, sessions, OAuth, or JWT to a project.
---

## Step 1: Ask about auth strategy

Ask the user which auth method they need:
- **Session-based** → follow steps below
- **JWT** → see `references/jwt.md`
- **OAuth provider** → see `references/oauth.md`

## Step 2: Install dependencies

```bash
bun add lucia arctic
```

## Step 3: Create auth adapter

Create `src/lib/auth.ts` with the Lucia adapter matching the project's database.

## Step 4: Create login route

Create `src/routes/login.ts` with email/password validation.

## Acceptance checklist

- [ ] Auth strategy matches user's choice
- [ ] Dependencies installed
- [ ] Adapter connects to existing database
- [ ] Login route created and tested
```

## Directory structure

```
setup-auth/
├── SKILL.md
└── references/
    ├── jwt.md     # JWT flow — alternative to session-based
    └── oauth.md   # OAuth flow — Google, GitHub, etc.
```

## Why this works

- Main flow (session-based) is in SKILL.md — zero extra tokens for the common case
- JWT and OAuth are conditional — only loaded when the user asks for them
- References are one level deep
- Agent doesn't load unnecessary context
