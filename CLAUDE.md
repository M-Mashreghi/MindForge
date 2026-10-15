# MindForge — Claude Code Instructions

MindForge is a Godot 4.x adaptive 2D puzzle-dungeon game.

The player explores a graphical dungeon whose challenge adapts to observed performance. Core gameplay must remain fully playable without any external AI service.

## Source of Truth

Before implementing any task, read:

1. `docs/PROJECT_PHASES_AND_TASKS.md`
2. `docs/GAME_DESIGN.md`
3. `docs/ARCHITECTURE.md`
4. `docs/ADAPTIVE_DIFFICULTY.md`
5. `docs/PUZZLE_SPEC.md`
6. `docs/GIT_WORKFLOW.md`
7. `docs/TASKS.md`
8. applicable `.claude/rules/*.md`

Do not invent requirements that conflict with these documents.

## Task Workflow

For every task:

1. Read the exact task scope, dependencies, and Definition of Done.
2. Inspect the working tree before editing.
3. Implement only the requested task.
4. Add or update automated validation where applicable.
5. Run the required Godot headless tests / validation scripts.
6. Fix failures before completion.
7. Update `docs/TASKS.md` and `docs/PROJECT_PHASES_AND_TASKS.md`.
8. Run the pre-commit checks in `docs/GIT_WORKFLOW.md`.
9. Create one task-scoped Git commit.
10. Push that commit to GitHub.
11. Verify the push succeeded.
12. Do not start the next task unless explicitly asked.

A task is not complete if the implementation exists only locally and GitHub publication is required.

## Git / GitHub Rule

Every completed task must end with a dedicated commit and GitHub push.

Preferred commit format:

```text
task(<task-id>): <short imperative summary>
```

Example:

```text
task(3.5): add predicted-success difficulty targeting
```

Never:
- commit secrets,
- commit `.env`,
- force-push,
- rewrite public history,
- silently create or replace a GitHub remote,
- combine unrelated tasks into one commit.

If `origin` is not configured or authentication fails, stop after the verified local implementation, report the Git/GitHub blocker clearly, and do not invent a remote URL or credentials.

## Game Architecture

Keep these responsibilities separate:

- game/run state,
- dungeon progression,
- puzzle data,
- puzzle rendering,
- puzzle validation/solving,
- player skill estimation,
- skill confidence,
- difficulty selection,
- scoring,
- telemetry,
- save/load,
- UI/presentation,
- AI content generation.

Do not place adaptive-difficulty logic inside UI scenes.

## Adaptive Difficulty Integrity

Player skill, confidence, predicted success, target difficulty, score, and XP are deterministic.

The LLM never directly changes:
- skill ratings,
- confidence,
- score,
- XP,
- streak,
- correctness,
- unlocked progression.

Difficulty adaptation must be gradual and confidence-aware. A single lucky answer or single failure must not cause a large jump.

## Player Experience Target

Standard rooms should normally target a configurable predicted-success band rather than simply using `difficulty = skill + constant`.

The initial design target is approximately a 70–80% predicted success zone for standard rooms. This is a game-design hypothesis to calibrate, not a permanent scientific truth.

Recovery, challenge, and boss rooms may use different target bands.

## Accessibility Integrity

Do not interpret slower response time as lower cognitive skill without context.

Accessibility settings that alter timers, motion, input method, or presentation must not silently penalize skill estimates or score. Correctness remains the dominant skill signal.

## Puzzle Integrity

Every puzzle instance must contain:

- stable id,
- family,
- schema/content version,
- authored/target difficulty,
- calibrated difficulty when available,
- difficulty confidence,
- prompt/state,
- deterministic canonical solution,
- family validator/solver,
- hint ladder,
- source/provenance,
- generation seed when applicable,
- content fingerprint.

AI-generated puzzles are untrusted until they pass all validation gates.

Whenever practical, AI generation should be solver-first:

```text
AI proposes structured puzzle parameters
→ deterministic solver derives the canonical solution
→ validator verifies uniqueness / solvability
→ puzzle may enter gameplay
```

Do not trust an LLM-provided answer as the authoritative solution.

## AI / Secrets

Never hardcode API keys in the Godot client.

If external AI is enabled, use a local/server-side adapter. The game must remain playable when AI is unavailable, invalid, slow, rate-limited, or disabled.

AI-generated text must be sanitized before display.

## Telemetry & Privacy

Telemetry is local-first. Do not collect unnecessary personal information.

Every performance event used for balancing should record enough provenance to reproduce the adaptive decision, including algorithm version and puzzle version.

## Testing

Critical checks include:

- skill update determinism,
- confidence updates,
- predicted-success monotonicity,
- target difficulty bounds,
- anti-oscillation behavior,
- recovery behavior,
- accessibility-safe timing behavior,
- puzzle validator correctness,
- uniqueness / solvability,
- score determinism,
- save/load round trips and migrations,
- seeded generation reproducibility,
- AI schema validation,
- AI fallback,
- content deduplication,
- adaptive convergence simulations.

## Assets

Do not add copyrighted third-party art, music, fonts, or sound effects without clear licensing information.

Use placeholders or clearly licensed assets until final polish.

## Scope Discipline

Prefer a polished 2D game over premature 3D, multiplayer, networking, complex backend infrastructure, or live-service systems.

## Completion Rule

A task is complete only when:

1. implementation exists,
2. required checks pass,
3. its Definition of Done is satisfied,
4. docs are synchronized,
5. one task-scoped Git commit exists,
6. that commit has been pushed successfully to GitHub when a remote is available.
