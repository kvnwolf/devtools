# Commit Config Setup

Runs when `.agents/commit.config.yml` does not exist.

## Discover

Launch a subagent (`subagent_type: Explore`) to find documentation files:

- Find all `*.md` files that could be documentation for humans or agents (excluding node_modules, .git, dist, skills)
- Read each file and analyze content
- For each file, determine what condition should trigger an update
- Return mapping of files to detected update conditions

## Confirm

Present inferred documentation files to user with `AskUserQuestion`. Allow the user to add, remove, or modify entries.

## Write Config

Create `.agents/commit.config.yml`:

```yaml
files:
  - path: <file>
    update_when:
      - <condition>
```

Example:

```yaml
files:
  - path: README.md
    update_when:
      - When API endpoints are added, changed, or removed
      - When environment variables change
  - path: docs/ARCHITECTURE.md
    update_when:
      - When new modules are introduced or existing ones are restructured
  - path: CHANGELOG.md
    update_when:
      - Every commit
```

Show generated config to user for final confirmation.
