# MindForge Deployment

## Development

Use Godot 4.x and keep the project launchable from the editor and command line.

Example headless validation:

```bash
godot --headless --path . --quit
```

Exact automated-test commands should be documented when the chosen Godot test harness is introduced.

## GitHub Development Gate

Every completed task follows:

```text
implementation → tests → docs → commit → push → verification
```

See `GIT_WORKFLOW.md`.

GitHub Actions is not a substitute for local task verification; both must pass.

## Continuous Integration

`.github/workflows/ci.yml` runs on every push to `main`, every pull request
and on demand. On Ubuntu 24.04 it checks whitespace, runs the release
audit over the tree and full history (`tools/audit_release.py --history`:
tracked `.env` / credentials, key-shaped strings, unregistered media,
dependency list), downloads the
official Godot 4.5.2 Linux binary (cached by exact version), then runs
`tools/validate.sh` (boot, puzzle bank, all test suites with the
required-suite guard, AI proxy tests, task-ledger consistency) and the
`--smoke-run` from source. Any failure fails the run. No dependency other
than the pinned Godot binary is cached; the AI proxy tests use only the
Python standard library.

## Optional AI Backend

The AI backend is introduced only in Phase 6 and remains optional.

Example server/proxy environment variables:

```env
LLM_API_KEY=
LLM_MODEL=
```

Never package provider secrets in the Godot export.

## Release Targets

Initial release targets:
- Windows desktop,
- Linux desktop,
- optional macOS once tested.

## Release Builds

`.github/workflows/release.yml` builds the downloadable releases in the
cloud, so no one needs export templates installed locally. On Ubuntu it
downloads the pinned Godot 4.5.2 binary and only the desktop templates the
presets use (Windows x86_64, Linux x86_64; cached by exact version), runs
`tools/export_release.sh` (both exports plus the Linux smoke run), and
packages `MindForge-<tag>-windows-x86_64.zip` and
`MindForge-<tag>-linux-x86_64.zip` (the executable with the PCK embedded, a
short README and Godot's MIT license and copyright notices) with
`SHA256SUMS.txt`. A Windows runner then unzips the Windows build and runs
`MindForge.exe --headless -- --smoke-run`. Only when both smoke runs pass is
the GitHub Release created (or its assets replaced) with the workflow's own
`GITHUB_TOKEN`; no other secret is used.

Triggers: pushing a `v*` tag builds and publishes that tag; running the
workflow by hand with a `tag` input (Actions -> Release -> Run workflow)
builds and publishes an existing tag from its tagged code; a pull request
that touches the workflow, `export_presets.cfg` or `tools/export_release.sh`
builds and smoke-tests without publishing. Builds are not code-signed.

Web export is post-MVP if AI/network behavior and save semantics are validated.

## CI Gates

- Godot project parses headlessly,
- validation scripts pass,
- puzzle fixtures validate,
- adaptive simulations pass,
- save migration/recovery checks pass,
- accessibility regression checks pass,
- no secrets detected,
- docs/task ledger consistency check passes.

## Desktop Export

`export_presets.cfg` defines two release presets with fixed output paths
under the git-ignored `exports/` folder:

| Preset | Output |
|---|---|
| Windows Desktop | `exports/windows/MindForge.exe` (x86_64, PCK embedded) |
| Linux | `exports/linux/MindForge.x86_64` (x86_64, PCK embedded) |

Both exclude `tests/`, `tools/`, `docs/`, `backend/`, `exports/`, Markdown
files and `.env` / `.env.*`; debug-only settings (adaptive log, internal
math, overlay) and AI are off by default (`tests/unit/test_export_presets.gd`).

```bash
GODOT=/path/to/godot tools/export_release.sh                    # both presets
GODOT=/path/to/godot tools/export_release.sh "Windows Desktop"  # one preset
```

The script exports each preset and smoke-tests the build for the current OS:
`MindForge --headless -- --smoke-run` boots, starts a seeded run, solves the
first room through the normal puzzle host and exits 0 with
`MindForge smoke OK` (`game/scripts/release/smoke_run.gd`; save and
telemetry are off during it). Exporting needs the export templates for the
exact engine version (4.5.2); without them the script fails with a clear
message. The same smoke run works from source:
`godot --headless --path . -- --smoke-run`.

## Export Safety

Exports must exclude:
- `.env`,
- provider credentials,
- development-only telemetry/debug artifacts,
- unlicensed assets.
