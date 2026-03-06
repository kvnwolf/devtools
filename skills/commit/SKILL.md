---
name: commit
description: Wraps up work by syncing documentation, committing, pushing, and opening a pull request. Use when committing code, finishing a task, pushing changes, or creating a PR.
allowed-tools: Bash(git diff *), Bash(git log *), Bash(git add *), Bash(git branch)
---

# Commit

## Step 1: Require Commit Config

Check if `.agents/commit.config.yml` exists.

- If exists, continue to step 2
- If not, follow `references/config-setup.md` to create it, then continue

## Step 2: Gather Context

Run each command separately:

1. `git diff --staged`
2. Only if step 1 had NO output: `git diff`
3. `git log --oneline`

## Step 3: Determine Staging

- If `git diff --staged` has output -> use as-is (user curated manually)
- If empty -> run `git add -A` to stage everything

## Step 4: Sync Documentation

1. Read `files` from `.agents/commit.config.yml`
2. Find staged `*.md` files not in the config that could be documentation (excluding `skills/`), detect their update condition, register them
3. For each tracked file, evaluate whether `update_when` is met by staged changes
4. Read and update every file whose condition is met
5. If new files were registered in step 2, persist the updated config

## Step 5: Stage Documentation

```bash
git add <updated-doc-files>
```

## Step 6: Generate and Execute Commit

**Subject:** semantic commit format (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`, `ci:`, `perf:`, `style:`, `build:`). Lowercase imperative, no period, max 70 chars. Use scope when it adds clarity.

**Body:** explain **why** — motivation, trade-offs, decisions. State breaking changes explicitly.

**References:** issue/ticket refs on their own line (e.g., `Closes #142`).

Execute with HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
feat: subject line describing what changed

Body explaining why this change was made.

Closes #issue (if applicable)
EOF
)"
```

## Step 7: Push

```bash
git push -u origin HEAD
```

## Step 8: Pull Request

Only if branch was pushed in step 7.

1. Run `git branch` — if on `main`, stop
2. Generate PR title and body:
   ```bash
   git log <base-branch>..HEAD --oneline
   git diff <base-branch>...HEAD
   ```
3. Create PR:
   ```bash
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   <bullet points from commit analysis>

   ## Test plan
   <checklist>
   EOF
   )"
   ```

## Acceptance checklist

- [ ] Commit config exists at `.agents/commit.config.yml`
- [ ] Documentation synced with staged changes
- [ ] Commit message follows semantic format with body
- [ ] Changes pushed to remote
- [ ] PR created (if not on main)
