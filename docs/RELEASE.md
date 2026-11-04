# MindForge Release Runbook and Portfolio Demo

How to set up a clean clone, verify it, build it, run the optional AI path,
cut a release, and give a 15 to 25 minute demo.

## 1. Clean-clone setup

Requirements:
- **Godot 4.5.2-stable**, standard build (not .NET). The project is pinned to
  4.5 (`project.godot`) and every check runs on 4.5.2.
- **Python 3.10+** (standard library only) for the AI proxy tests and the
  repository audits. Optional: `pip install -r backend/requirements.txt` for
  the Claude provider of the AI proxy.
- Git and a bash shell (Git Bash on Windows).

```bash
git clone https://github.com/M-Mashreghi/MindForge.git
cd MindForge
export GODOT=/path/to/Godot_v4.5.2-stable     # the console build on Windows
"$GODOT" --headless --path . --import          # first import (creates .godot/)
```

Windows: `winget install GodotEngine.GodotEngine --version 4.5.2` puts the
executables under `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*\`.

## 2. Run and test

| What | Command |
|---|---|
| Play | `"$GODOT" --path .` |
| Editor | `"$GODOT" --path . -e` (then F5) |
| Everything CI checks, one command | `bash tools/validate.sh` |
| One test suite | `bash tools/run_tests.sh --suite=adaptive` (see `tests/suites.gd`) |
| One-room smoke run from source | `"$GODOT" --headless --path . -- --smoke-run` |
| Performance baseline | `"$GODOT" --headless --path . -s res://tools/profile_performance.gd` |
| Release audit (secrets, licenses, dependencies) | `python tools/audit_release.py --history` |
| Release history check | `python tools/check_release.py --tag vX.Y.Z` |

`tools/validate.sh` must print `validate: OK`: headless boot, puzzle bank,
all test suites with the required-suite guard, AI proxy tests, task ledger
and release audit. CI (`.github/workflows/ci.yml`) runs the same on Linux
for every push to `main` and every pull request.

## 3. Offline mode and optional AI

The game is complete offline. AI is **off** by default
(`mindforge/ai/enabled=false`) and nothing in a normal run touches the
network. To show the AI path:

```bash
cp .env.example .env            # optional: set LLM_API_KEY; empty = offline mock provider
python -m backend.app.server    # local proxy on 127.0.0.1:8787
"$GODOT" --headless --path . -s res://tools/ai_smoke_test.gd   # proposal -> solver -> pipeline
```

Then enable `mindforge/ai/enabled` in Project Settings (or for one session in
the editor) and start a run: validated AI puzzles join the pool in the
background, and rooms never wait for them. Keys stay in the proxy's
environment and are never exported (`backend/` and `.env*` are excluded by
the export presets). Stop the proxy mid-run to show the fallback: play
continues with local and procedural puzzles.

## 4. Build

```bash
bash tools/export_release.sh                    # Windows Desktop + Linux into exports/
```

Needs the Godot 4.5.2 export templates (Editor -> Manage Export Templates).
The script exports both presets and smoke-tests the build for the current
OS (`MindForge --headless -- --smoke-run` must print `MindForge smoke OK`).
See [DEPLOYMENT.md](DEPLOYMENT.md) for what the presets include and exclude.

## 5. Cut a release

1. `git status` is clean and `main` is up to date with `origin/main`.
2. `bash tools/validate.sh` prints `validate: OK`, and CI is green on the
   same commit.
3. `python tools/audit_release.py --history` reports 0 problems.
4. Bump `application/config/version` in `project.godot` and the file and
   product versions in `export_presets.cfg` if this release changes them.
5. Optional: `bash tools/export_release.sh` with templates installed.
6. Tag and push: `git tag -a vX.Y.Z -m "MindForge vX.Y.Z"` then
   `git push origin vX.Y.Z`.
7. `python tools/check_release.py --tag vX.Y.Z` reports 0 problems: every
   completed task has its `task(<id>)` commit, HEAD is on `origin/main`,
   and the tag points at HEAD locally and on origin.

## 6. Portfolio demo (about 20 minutes)

Goal: show that two very different players get visibly different dungeons
from the same seed, and that the system stays trustworthy (deterministic,
offline, solver-checked, accessible).

Preparation (5 minutes before):
- Back up the real profile, then remove it so the demo starts fresh:
  Windows `%APPDATA%\Godot\app_userdata\MindForge\profile.save`, Linux
  `~/.local/share/godot/app_userdata/MindForge/profile.save`
  (also `.bak`). Restore it afterwards.
- Run from the editor (F5) so the debug overlay is available (**F9**).
- Have a terminal open in the repository.

| Time | Step | What to point out |
|---:|---|---|
| 0:00 | Main menu, open **Settings** | Untimed play, memory speed, interface size, reduced motion. Accommodations never lower rating or score. Keyboard and controller only. |
| 2:00 | **New Run** with warm-up on; walk to the pedestal, press E | The three warm-up rooms (one per family) calibrate a new profile. |
| 4:00 | **Strong profile**: solve every room quickly, no hints. Press **F9** | Overlay: skill estimate and confidence rising, predicted success held near the 70 to 80% band, target difficulty climbing in small, capped steps. |
| 8:00 | Guardian trial (boss room) and run summary | Two-stage trial, score, XP and streak; the summary describes the run, not the person. |
| 10:00 | Quit, delete the profile again, **New Run** | Fresh profile, same flow. |
| 11:00 | **Struggling profile**: answer wrong, take hints, leave a puzzle | The estimate drops gradually (no cliff after one miss); recovery mode turns on after repeated failures (overlay) and offers familiar mechanics at an easier band; it turns off only after sustained success (hysteresis). |
| 15:00 | Terminal: `"$GODOT" --headless --path . -s res://tools/demo_adaptation.gd` | Same seed, strong vs struggling side by side: difficulties diverge (about 490 vs 230 by room 15), predicted success stays near the band for both, `R` marks recovery rooms. |
| 17:00 | `docs/reports/adaptive_vs_static.md` | Adaptive vs a fixed ramp over six simulated player types: more rooms in the challenge range, far fewer too-hard rooms, fewer hints. Be honest about the weak spots (strong players under-challenged; struggling players still face too many hard rooms). |
| 19:00 | `bash tools/validate.sh` (or show the green CI run) | Deterministic tests, puzzle validators, save migration, AI fallback, balance fixtures, audits. Optional: stop/start the AI proxy to show the offline fallback. |
| 21:00 | Questions | |

If time is short, skip the boss room and the AI proxy; the strong vs
struggling contrast and the side-by-side tool are the core of the demo.
