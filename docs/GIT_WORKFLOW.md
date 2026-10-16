# MindForge Git & GitHub Workflow

This workflow is mandatory for Claude Code.

## Goal

Every completed task must have an auditable one-task commit that is pushed to GitHub before the next task begins.

## Repository Safety

Claude must first inspect:

```bash
git status --short
git branch --show-current
git remote -v
```

Rules:

- Never invent a repository URL.
- Never replace an existing `origin` without explicit user approval.
- Never force-push.
- Never commit credentials or `.env`.
- Do not delete unrelated user changes.
- Do not reset or discard work that was not created by the current task.

## Task Start

Before editing:

```bash
git status --short
```

If unrelated uncommitted changes exist, Claude must identify them and avoid silently absorbing them into the task commit.

## Task Verification

Before committing:

1. run the task-specific tests,
2. run required validation scripts,
3. synchronize task documentation,
4. inspect:

```bash
git diff --check
git status --short
git diff --stat
```

5. inspect the staged diff before committing.

## Pre-Commit Script

After staging, run:

```bash
tools/precommit_check.sh
```

It prints the branch, remote and staged diff stat, and fails on staged whitespace errors, a staged `.env` / export credentials file, or added lines that look like a real secret. Set `GODOT=/path/to/godot` to also run the headless boot check (`tools/check_boot.sh`).

## Staging

Stage only files that belong to the current task.

Do not blindly use `git add .` when unrelated files are present.

## Commit Convention

Use:

```text
task(<task-id>): <short imperative summary>
```

Examples:

```text
task(1.3): add autoload game state and event bus
task(2.4): implement deterministic pattern solver
task(3.7): smooth confidence-aware skill updates
task(6.8): quarantine invalid AI puzzle content
```

The task commit should include implementation, tests, and task documentation updates.

## Push Rule

After committing:

```bash
git push
```

If the current branch has no upstream:

```bash
git push -u origin HEAD
```

Only do this when `origin` is already correctly configured.

## Push Verification

Verify the commit is reachable on the upstream branch:

```bash
git status -sb
git log -1 --oneline
```

When practical:

```bash
git rev-parse HEAD
git rev-parse @{u}
```

The hashes should match after a successful push.

## Failure Policy

If tests fail:
- do not commit,
- fix the task.

If commit fails:
- do not start the next task.

If push/authentication fails:
- keep the verified local commit,
- report the blocker,
- do not claim GitHub publication succeeded,
- do not start the next task unless the user explicitly allows it.

## Fixes After a Pushed Task

Do not rewrite public history.

If a pushed task requires a follow-up fix, use a new commit such as:

```text
fix(3.7): correct recovery-mode smoothing edge case
```

## Branch Policy

Use the branch the user/repository workflow provides.

Do not automatically merge into `main`.

If a feature-branch workflow is used, push the current branch and let the user decide when to merge.

## Definition of Done Extension

A task is complete only after:

```text
implementation
→ tests
→ docs
→ diff review
→ commit
→ GitHub push
→ push verification
```
