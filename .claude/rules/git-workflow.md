# Git / GitHub Workflow Rules

Every completed task requires one task-scoped commit and a successful GitHub push before the next task starts.

Required order:

```text
Implement
→ Test
→ Update Docs
→ git diff --check
→ Stage only task files
→ Commit
→ Push
→ Verify upstream
```

Commit format:

```text
task(<task-id>): <short imperative summary>
```

Never force-push, invent/change `origin`, commit `.env` or credentials, absorb unrelated working-tree changes, or claim a push succeeded without verification.

If push authentication or remote configuration fails, report the blocker and do not start the next task.
