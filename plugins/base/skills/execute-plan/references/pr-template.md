# PR Template

After all tasks complete, the coordinator creates a PR from the plan branch. All content is extracted from `plan.yml` and the completed task files.

## Title

Use the `commit` field from `plan.yml` (e.g., `feat(notifications): add real-time user notification system`).

## Body structure

All content must be in English.

```markdown
## Overview

<plan.yml overview field — 2-4 sentences describing the problem and solution>

## User flow

<!-- Omit this section entirely if plan.yml has no userFlow field -->

<plan.yml userFlow field as numbered list>

## Goals

<plan.yml goals field as bulleted list>

## Decisions

<plan.yml decisions field as bulleted list>

## Edge cases

<plan.yml edgeCases field as bulleted list>

## Learnings

<Consolidated list of all learnings from completed task files. Deduplicate and merge similar entries. Do not group by task or reference task IDs.>
```

## Creation

1. Detect the default branch: `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
2. Push the plan branch: `git push -u origin <branch>`
3. Create the PR:

```bash
gh pr create --base <default-branch> --title "<commit from plan.yml>" --body "$(cat <<'EOF'
<generated body>
EOF
)"
```

## Example

```markdown
## Overview

Users have no way to know when they receive mentions, replies, or status
changes without manually refreshing. Add a real-time notification system
with badge count in nav, notification list page, and mark-as-read.

## User flow

1. User sees badge with unread count in nav
2. Clicks badge, navigates to notification list
3. Sees notifications sorted newest first
4. Clicks notification, marks as read, navigates to source
5. Can mark all as read via button

## Goals

- Show unread notification count in nav
- List notifications with mark-as-read
- Real-time updates without refresh

## Decisions

- Store in DB, not local storage (persist across devices)
- Polling every 30s, not websockets (simpler, sufficient)
- Badge shows "99+" for counts over 99
- Optimistic UI for mark-as-read actions

## Edge cases

- No notifications: show empty state with illustration
- Network error: show cached, indicate stale
- Concurrent tabs: sync via storage event

## Learnings

- Pagination helper was duplicated between messages and notifications — extracted to shared util
- Existing page test patterns use renderWithProviders helper from test-utils
- Storage event listener needs to filter by key to avoid reacting to unrelated storage changes
```
