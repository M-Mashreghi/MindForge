#!/usr/bin/env bash
# Pre-commit checks from docs/GIT_WORKFLOW.md. Run after staging task files:
#   tools/precommit_check.sh            (set GODOT=/path/to/godot to include the boot check and tests)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
FAIL=0

echo "== branch / remote"
git branch --show-current
git remote -v

echo "== staged files"
STAGED="$(git diff --cached --name-only)"
if [ -z "$STAGED" ]; then
	echo "precommit: nothing staged" >&2
	exit 1
fi
echo "$STAGED"
git diff --cached --stat

echo "== whitespace (git diff --cached --check)"
if ! git diff --cached --check; then
	FAIL=1
fi

echo "== secrets"
if echo "$STAGED" | grep -qE '(^|/)\.env$|export_credentials\.cfg$'; then
	echo "precommit: .env or export credentials staged" >&2
	FAIL=1
fi
# Added lines that look like a filled-in secret: a key/secret/token/password
# name assigned a value of 12+ chars (`=` as in .env files, or `:` followed by
# a quoted literal), or a known provider key prefix. Typed code such as
# `tokens: PackedStringArray` is not flagged; empty template values are fine.
if git diff --cached -U0 | grep -E '^\+' | grep -v '^+++' \
	| grep -qiE '(api[_-]?key|secret|token|password)[a-z_]*[[:space:]]*(=[[:space:]]*["'\'']?|:[[:space:]]*["'\''])[A-Za-z0-9_/+\-]{12,}|sk-[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{20,}'; then
	echo "precommit: staged change looks like it contains a secret" >&2
	FAIL=1
fi

echo "== unstaged / untracked (not part of this commit)"
git status --short | grep -vE '^[MADRC] ' || echo "(none)"

if [ -n "${GODOT:-}" ]; then
	echo "== headless boot"
	bash "$ROOT/tools/check_boot.sh" || FAIL=1
	echo "== headless tests"
	bash "$ROOT/tools/run_tests.sh" || FAIL=1
	echo "== puzzle bank"
	bash "$ROOT/tools/validate_puzzles.sh" || FAIL=1
fi

PY="$(command -v python || command -v python3 || true)"
if [ -n "$PY" ] && [ -d "$ROOT/backend/tests" ]; then
	echo "== AI proxy tests"
	PY_OUT="$(cd "$ROOT" && "$PY" -m unittest discover -s backend/tests -t . 2>&1)" || FAIL=1
	echo "$PY_OUT" | tail -3
fi

if [ $FAIL -ne 0 ]; then
	echo "precommit: FAILED" >&2
	exit 1
fi
echo "precommit: OK"
