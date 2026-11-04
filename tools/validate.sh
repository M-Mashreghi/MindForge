#!/usr/bin/env bash
# One-command headless validation for local use and CI:
#   tools/validate.sh            (uses $GODOT, else `godot` on PATH)
# Runs the boot check, the puzzle bank validator, every test suite in
# tests/suites.gd (puzzle, adaptive, save, procedural, ai_fallback, other)
# with the required-suite guard, and, when Python is available, the AI proxy
# unit tests, the task-ledger consistency check and the release audit
# (secrets, media register, dependency list). Prints a summary and exits non-zero on any blocking failure.
set -u
GODOT_BIN="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export GODOT="$GODOT_BIN"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "validate: Godot executable '$GODOT_BIN' not found. Set GODOT=/path/to/godot." >&2
	exit 2
fi

RESULTS=()
FAIL=0

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

step() {
	local name="$1"
	shift
	echo "== $name"
	"$@" 2>&1 | tee "$LOG"
	if [ "${PIPESTATUS[0]}" -eq 0 ]; then
		RESULTS+=("ok    $name")
	else
		RESULTS+=("FAIL  $name")
		FAIL=1
		# On GitHub Actions, surface the failing lines as annotations (they
		# are readable without opening the job log).
		if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
			grep -E "FAIL|ERROR|SCRIPT ERROR|Parse Error|leaked" "$LOG" | head -10 				| while IFS= read -r line; do echo "::error title=$name::$line"; done
		fi
	fi
}

step "headless boot" bash "$ROOT/tools/check_boot.sh"
step "puzzle bank" bash "$ROOT/tools/validate_puzzles.sh"
step "test suites" bash "$ROOT/tools/run_tests.sh" --require-suites

# Pick the first interpreter that actually runs (Windows ships a python3 stub).
PY=""
for candidate in python python3; do
	if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c "" >/dev/null 2>&1; then
		PY="$candidate"
		break
	fi
done
if [ -n "$PY" ] && [ -d "$ROOT/backend/tests" ]; then
	step "AI proxy tests" bash -c "cd '$ROOT' && '$PY' -m unittest discover -s backend/tests -t . 2>&1 | tail -3; exit \${PIPESTATUS[0]}"
	step "task ledger" "$PY" "$ROOT/tools/check_task_ledger.py"
	step "release audit" "$PY" "$ROOT/tools/audit_release.py"
else
	RESULTS+=("skip  AI proxy tests and task ledger (python not found)")
fi

echo "== summary"
printf '%s\n' "${RESULTS[@]}"
if [ $FAIL -ne 0 ]; then
	echo "validate: FAILED" >&2
	exit 1
fi
echo "validate: OK"
