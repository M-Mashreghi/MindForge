#!/usr/bin/env bash
# Exports the release desktop builds from export_presets.cfg and smoke-tests
# the build for this OS: boots it headless and plays one room with
# `-- --smoke-run` (game/scripts/release/smoke_run.gd).
# Usage: tools/export_release.sh [preset ...]   (default: "Windows Desktop" "Linux")
# Needs Godot's export templates for the exact engine version (Editor ->
# Manage Export Templates, or the official .tpz). Uses $GODOT, else `godot`.
set -u
GODOT_BIN="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRESETS=("$@")
[ ${#PRESETS[@]} -eq 0 ] && PRESETS=("Windows Desktop" "Linux")

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "export_release: Godot executable '$GODOT_BIN' not found. Set GODOT=/path/to/godot." >&2
	exit 2
fi

"$GODOT_BIN" --headless --path "$ROOT" --import >/dev/null 2>&1
FAIL=0
for preset in "${PRESETS[@]}"; do
	case "$preset" in
		"Windows Desktop") out="$ROOT/exports/windows/MindForge.exe" ;;
		"Linux") out="$ROOT/exports/linux/MindForge.x86_64" ;;
		*) echo "export_release: unknown preset '$preset'" >&2; exit 2 ;;
	esac
	mkdir -p "$(dirname "$out")"
	echo "== export $preset"
	if ! "$GODOT_BIN" --headless --path "$ROOT" --export-release "$preset" "$out" 2>&1 | tail -5 || [ ! -f "$out" ]; then
		echo "export_release: export of '$preset' failed (are the export templates installed?)" >&2
		FAIL=1
		continue
	fi
	# Smoke-test only the build this machine can run.
	runnable=0
	case "$(uname -s)" in
		MINGW*|MSYS*|CYGWIN*) [ "$preset" = "Windows Desktop" ] && runnable=1 ;;
		Linux) [ "$preset" = "Linux" ] && runnable=1 ;;
	esac
	[ $runnable -eq 1 ] || continue
	echo "== smoke $preset"
	SMOKE="$("$out" --headless -- --smoke-run 2>&1)"
	STATUS=$?
	echo "$SMOKE" | tail -4
	if [ $STATUS -ne 0 ] || ! echo "$SMOKE" | grep -q "MindForge boot OK" || ! echo "$SMOKE" | grep -q "MindForge smoke OK" \
		|| echo "$SMOKE" | grep -qE "SCRIPT ERROR|Parse Error"; then
		echo "export_release: smoke run of '$preset' failed" >&2
		FAIL=1
	fi
done
[ $FAIL -eq 0 ] && echo "export_release: OK" || { echo "export_release: FAILED" >&2; exit 1; }
