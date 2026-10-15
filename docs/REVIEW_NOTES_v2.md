# MindForge — Review Notes v2

## Why this revision was needed

The first package had a sound high-level architecture, but several areas were too implicit for reliable autonomous implementation by Claude Code.

### 1. Generic task contracts
The task names were specific, but most tasks shared the same generic Implementation Contract.

**v2:** every task now has task-specific implementation requirements and verification criteria.

### 2. No mandatory task-by-task GitHub workflow
The user requires every completed task to be committed and published.

**v2:** `GIT_WORKFLOW.md` and `.claude/rules/git-workflow.md` make this mandatory:

```text
test → docs → diff review → commit → push → verify
```

### 3. Skill estimate had no uncertainty
**v2:** skill state includes confidence and observation count.

### 4. Difficulty targeting was mostly skill + offset
**v2:** standard rooms target a configurable predicted-success band, initially around 70–80%, with different bands for recovery/challenge/boss rooms.

### 5. Puzzle difficulty was treated as a fixed label
**v2:** target/authored difficulty is separate from empirically calibrated difficulty and calibration confidence.

### 6. Timing could unfairly affect accessibility
**v2:** timing is bounded and accessibility-aware; correctness dominates.

### 7. AI answer generation needed a stronger trust boundary
**v2:** pattern/logic AI content is solver-first; deterministic code derives and validates the canonical solution.

### 8. Generated content repetition
**v2:** content fingerprinting, duplicate rejection, recent-repeat penalties, and scheduler variety are explicit.

### 9. Adaptive quality lacked formal evaluation
**v2:** `ADAPTIVE_EVALUATION.md` defines convergence, oscillation, target-band occupancy, recovery, accessibility regressions, and adaptive-vs-static tests.

## Scope

v2 contains **72 atomic tasks across 8 phases**.

The revision intentionally does not add multiplayer, 3D, live-service infrastructure, mandatory online AI, or complex cloud telemetry.
