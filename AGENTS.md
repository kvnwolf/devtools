# Devtools

Plugin marketplace for Claude Code — opinionated developer tools used across multiple projects.

## Tech Stack

- **Package manager:** Bun
- **Testing:** Vitest

## Structure

- Plugins live in `plugins/` — each plugin is self-contained with `.claude-plugin/plugin.json`, `hooks/`, and `skills/`
- Marketplace manifest lives in `.claude-plugin/marketplace.json`
- Three plugins: `base` (any project), `web` (web development), `backend` (Convex backend)

## Conventions

- Minimal dependencies by design — only add devDependencies that serve the tooling purpose
- Commit scope for plugins uses the plugin name: `feat(plugins:plugin-name): ...`
- Commit scope for skills uses the skill name: `feat(skills:skill-name): ...`
