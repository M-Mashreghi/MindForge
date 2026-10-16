#!/usr/bin/env bash
# Validates the bundled puzzle bank (schema, family validators, duplicates,
# fingerprint snapshot). Pass --write-fingerprints after intentional changes.
# Usage: tools/validate_puzzles.sh [--write-fingerprints]   (uses $GODOT, else `godot`)
set -u
GODOT_BIN="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "validate_puzzles: Godot executable '$GODOT_BIN' not found. Set GODOT=/path/to/godot." >&2
	exit 2
fi

"$GODOT_BIN" --headless --path "$ROOT" --import >/dev/null 2>&1
OUTPUT="$("$GODOT_BIN" --headless --path "$ROOT" -s res://tools/validate_puzzles.gd -- "$@" 2>&1)"
STATUS=$?
echo "$OUTPUT"
if [ $STATUS -ne 0 ] || echo "$OUTPUT" | grep -qE "SCRIPT ERROR|Parse Error"; then
	echo "validate_puzzles: FAILED" >&2
	exit 1
fi
echo "validate_puzzles: OK"
