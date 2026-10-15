# MindForge — Adaptive Puzzle Dungeon

MindForge is a **2D graphical puzzle-dungeon game** built with **Godot 4.x**. The game continuously estimates player skill and adapts the next challenge so that strong players receive harder puzzles while struggling players receive easier challenges and more support.

The project combines:

- graphical game development,
- adaptive difficulty,
- player modeling,
- procedural puzzle generation,
- optional LLM-generated puzzle content,
- deterministic scoring,
- progression and rewards,
- game telemetry and analytics.

## Core Game Loop

```text
Enter Room
   ↓
Inspect Puzzle
   ↓
Answer / Interact
   ↓
Measure Performance
   ↓
Update Player Skill
   ↓
Select Target Difficulty
   ↓
Generate / Choose Next Puzzle
   ↓
Reward XP / Score / Loot
   ↓
Open Next Room
```

## v1 Puzzle Families

1. **Pattern puzzles** — sequences, symbol rules, missing element.
2. **Logic puzzles** — constraints, switches, ordering, deduction.
3. **Memory puzzles** — rune sequences, object positions, timed recall.

Later families can include spatial puzzles, word puzzles, math puzzles, and multi-room meta-puzzles.

## Adaptive Difficulty

The adaptive engine is deterministic. It considers:

- correctness,
- response time,
- hints used,
- attempts,
- recent streak,
- puzzle difficulty,
- puzzle family,
- repeated failure patterns.

The player has both an overall skill rating and family-specific skills:

```text
Overall Skill: 642
Pattern: 710
Logic:   665
Memory:  501
```

The next puzzle should normally be close to the player's estimated skill, with controlled exploration above and below the current level.

## AI Responsibility

The LLM may:
- generate a puzzle specification for a requested family/difficulty,
- generate hints,
- generate explanations,
- generate room flavor text.

The LLM must **not**:
- set player skill,
- award points,
- decide whether an answer is correct without deterministic validation,
- invent telemetry,
- bypass puzzle validators.

AI-generated puzzles must pass deterministic validation before reaching the player.

## Graphics / Engine

- **Godot 4.x**
- GDScript
- 2D top-down dungeon rooms
- reusable room/puzzle scenes
- keyboard + mouse support
- local save profile
- optional local AI backend for secret-safe LLM calls

## MVP

The first portfolio-ready release should contain:

- 2D dungeon map,
- 12–20 playable rooms,
- 3 puzzle families,
- deterministic skill model,
- adaptive target difficulty,
- scoring / XP / streak system,
- hint system,
- save/load,
- results screen,
- telemetry summary,
- procedural puzzle bank,
- optional AI-generated content behind a safe fallback.

## Start in Claude Code

```text
Read CLAUDE.md and all project governance documents.

Inspect Task 1.1 in:
docs/PROJECT_PHASES_AND_TASKS.md

Implement only Task 1.1.

Follow its Definition of Done.
Run all required tests and validation scripts.
Update TASKS.md and PROJECT_PHASES_AND_TASKS.md only after verification succeeds.
Follow docs/GIT_WORKFLOW.md: create a task-scoped commit, push it to GitHub, and verify the push.

Do not start Task 1.2.
```

## Development Discipline

Claude Code must complete the project task-by-task.

After every successful task:

```text
Implement
→ Test / Validate
→ Update Docs
→ Review Diff
→ Commit with Task ID
→ Push to GitHub
→ Verify Push
```

Commit example:

```text
task(3.5): add predicted-success difficulty targeting
```

See `docs/GIT_WORKFLOW.md`.

## Adaptive Design v2

MindForge does not simply make a puzzle harder after a correct answer.

The v2 design tracks:
- family-specific player skill,
- skill confidence,
- puzzle difficulty confidence,
- predicted success,
- target-success bands,
- recovery state,
- variety/repetition history.

This makes adaptation smoother and easier to evaluate.

## AI Design v2

AI content uses a solver-first pipeline:

```text
AI proposes structured puzzle parameters
→ deterministic solver derives the canonical solution
→ validator verifies the puzzle
→ duplicate/safety checks
→ accepted content enters cache
```

The LLM is never the authoritative answer key.
