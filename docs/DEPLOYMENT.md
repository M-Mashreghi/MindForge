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

GitHub Actions is not a substitute for local task verification; both should pass once CI exists.

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

## Export Safety

Exports must exclude:
- `.env`,
- provider credentials,
- development-only telemetry/debug artifacts,
- unlicensed assets.
