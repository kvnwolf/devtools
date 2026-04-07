# Plan File Format (plan.yml)

The plan file is the PRD — it captures the problem, decisions, and task tree for a feature or change. It lives at `.agents/plans/<id>-<plan-name>/plan.yml`.

## Naming and numbering

Plans use zero-padded 3-digit IDs: `001-user-notifications`, `002-fix-auth-redirect`. To determine the next number, count existing directories in `.agents/plans/` (excluding `state.yml`) and add 1.

Task files within a plan use zero-padded 2-digit IDs: `01-create-notifications.yml`, `02-mark-as-read.yml`.

The ID of a plan is its directory name (e.g., `001-user-notifications`). The ID of a task is its file name without the `.yml` extension (e.g., `01-create-read-notifications`). IDs are used consistently everywhere — directory names, file names, YAML content, `dependsOn` references, and `state.yml`.

## Schema

```yaml
id: 001-<plan-name>                # matches the directory name
status: pending                    # pending | in_progress | completed

branch: <type>/<short-description>  # e.g., feat/user-notifications, fix/auth-redirect
commit: "<semantic commit message for the PR title>"

overview: |
  <Problem description and proposed solution — distilled from the user's
  description and your codebase exploration. 2-4 sentences.>

userFlow:  # omit this field entirely if not applicable (e.g., pure backend or refactoring tasks)
  - <step 1>
  - <step 2>
  - ...

goals:
  - <what this plan achieves>
  - ...

nonGoals:
  - <what is explicitly out of scope>
  - ...

constraints:
  - <technical or business constraints>
  - ...

successCriteria:
  - <verifiable condition>
  - ...

decisions:
  - <key technical decision from interview>
  - ...

edgeCases:
  - "<edge case: how to handle it>"
  - ...

tasks:
  - id: 01-<kebab-case-title>
    title: "<task title from approved proposal>"
    status: pending
    dependsOn: []
  - id: 02-<kebab-case-title>
    title: "<task title>"
    status: pending
    dependsOn: [01-<kebab-case-title>]
  # ... one entry per approved task
```

## Generation

1. Derive a kebab-case plan name from the task description. Count existing directories in `.agents/plans/` (excluding `state.yml`) and add 1 for the zero-padded 3-digit ID.
2. Create the plan directory: `mkdir -p .agents/plans/<plan-id>`
3. Write `plan.yml` using the Write tool. All fields must be populated from the exploration and interview phases.
4. Initialize `state.yml` following the state file schema below.

## Guidelines

- All content must be in English regardless of the user's language.
- All content comes from the exploration and interview — do not invent information.
- `status` starts as `pending`. It is updated to `in_progress` when execution begins and `completed` when all tasks finish.
- `branch` follows the pattern `<type>/<short-description>` where type matches the commit convention (feat, fix, refactor, etc.).
- `commit` is the PR title — a single semantic commit message summarizing the entire plan.
- `userFlow` should only be included when the plan involves user-facing changes. Omit it entirely for backend-only or refactoring tasks.
- `tasks` entries reference file names but do NOT create the task files — they are generated in the next phase.
- Task IDs are the file name without `.yml` (e.g., `01-create-notifications`). The file name is derived from the ID by appending `.yml`.
- All tasks start with `status: pending`.

## State file (.agents/plans/state.yml)

A global file that tracks which plan is being executed. Located at `.agents/plans/state.yml`.

```yaml
currentPlan: null                    # set by /execute when execution begins
activeTasks: []                      # task IDs currently running (supports parallel execution)
lastCompletedPlan: null              # most recently completed plan ID
```

When `/plan` creates a new plan, initialize `state.yml` with `currentPlan: null`, `activeTasks: []`, and `lastCompletedPlan` preserved from any previous value (or `null` if the file is new).

## Example

```yaml
id: 001-user-notifications
status: pending

branch: feat/user-notifications
commit: "feat(notifications): add real-time user notification system"

overview: |
  Users have no way to know when they receive mentions, replies, or status
  changes without manually refreshing. Add a real-time notification system
  with badge count in nav, notification list page, and mark-as-read.

userFlow:
  - User sees badge with unread count in nav
  - Clicks badge, navigates to notification list
  - Sees notifications sorted newest first
  - Clicks notification, marks as read, navigates to source
  - Can mark all as read via button

goals:
  - Show unread notification count in nav
  - List notifications with mark-as-read
  - Real-time updates without refresh

nonGoals:
  - Email notifications (future plan)
  - Push notifications (future plan)
  - Notification preferences/settings

constraints:
  - Max 100 notifications stored per user
  - 30-day retention, auto-delete older
  - Must work with existing auth system

successCriteria:
  - Unread count visible in nav
  - Notification list renders with timestamps
  - Mark as read works (single + all)
  - Updates arrive within 2s via polling

decisions:
  - Store in DB, not local storage (persist across devices)
  - Polling every 30s, not websockets (simpler, sufficient)
  - Badge shows "99+" for counts over 99
  - Optimistic UI for mark-as-read actions

edgeCases:
  - "No notifications: show empty state with illustration"
  - "Network error: show cached, indicate stale"
  - "Concurrent tabs: sync via storage event"

tasks:
  - id: 01-create-read-notifications
    title: "create and read notifications (schema + endpoint + UI)"
    status: pending
    dependsOn: []
  - id: 02-mark-as-read
    title: "mark notifications as read (single + all)"
    status: pending
    dependsOn: [01-create-read-notifications]
  - id: 03-notification-badge
    title: "notification badge with live polling"
    status: pending
    dependsOn: [01-create-read-notifications]
```
