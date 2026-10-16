#!/usr/bin/env bash
# Runs the headless GDScript test suite (tests/unit, tests/integration).
# Usage: tools/run_tests.sh            (uses $GODOT, else `godot` on PATH)
set -u
GODOT_BIN="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "run_tests: Godot executable '$GODOT_BIN' not found. Set GODOT=/path/to/godot." >&2
	exit 2
fi

# Refresh the import cache so new scripts/classes are known.
"$GODOT_BIN" --headless --path "$ROOT" --import >/dev/null 2>&1
OUTPUT="$("$GODOT_BIN" --headless --path "$ROOT" -s res://tests/run_tests.gd 2>&1)"
STATUS=$?
echo "$OUTPUT"

if [ $STATUS -ne 0 ]; then
	echo "run_tests: FAILED (exit code $STATUS)" >&2
	exit 1
fi
if echo "$OUTPUT" | grep -qE "SCRIPT ERROR|Parse Error|ERROR:"; then
	echo "run_tests: FAILED (errors in output)" >&2
	exit 1
fi
if ! echo "$OUTPUT" | grep -qE "^tests: [0-9]+ passed, 0 failed"; then
	echo "run_tests: FAILED (no test summary)" >&2
	exit 1
fi
echo "run_tests: OK"
