#!/usr/bin/env bash
# Headless boot check: loads the project, runs the main scene for one frame
# and fails on any parser/runtime error or a missing boot message.
# Usage: tools/check_boot.sh            (uses $GODOT, else `godot` on PATH)
set -u
GODOT_BIN="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "check_boot: Godot executable '$GODOT_BIN' not found. Set GODOT=/path/to/godot." >&2
	exit 2
fi

# First pass imports the project so the cache exists, second pass runs it.
"$GODOT_BIN" --headless --path "$ROOT" --import >/dev/null 2>&1
OUTPUT="$("$GODOT_BIN" --headless --path "$ROOT" --quit-after 2 2>&1)"
STATUS=$?
echo "$OUTPUT"

if [ $STATUS -ne 0 ]; then
	echo "check_boot: FAILED (exit code $STATUS)" >&2
	exit 1
fi
if echo "$OUTPUT" | grep -qE "SCRIPT ERROR|Parse Error|ERROR:"; then
	echo "check_boot: FAILED (errors in output)" >&2
	exit 1
fi
if ! echo "$OUTPUT" | grep -q "MindForge boot OK"; then
	echo "check_boot: FAILED (boot message missing)" >&2
	exit 1
fi
echo "check_boot: OK"
