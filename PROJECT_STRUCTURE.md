# MindForge — Project Structure

```text
MindForge/
├── CLAUDE.md
├── README.md
├── PROJECT_STRUCTURE.md
├── project.godot
├── .env.example
├── .gitignore
│
├── .claude/
│   └── rules/
│       ├── architecture.md
│       ├── adaptive-difficulty.md
│       ├── puzzle-integrity.md
│       ├── ai-content.md
│       ├── game-design.md
│       ├── testing.md
│       ├── documentation.md
│       └── git-workflow.md
│
├── docs/
│   ├── GAME_DESIGN.md
│   ├── ARCHITECTURE.md
│   ├── ADAPTIVE_DIFFICULTY.md
│   ├── PUZZLE_SPEC.md
│   ├── AI_CONTENT_POLICY.md
│   ├── SAVE_AND_TELEMETRY.md
│   ├── ROADMAP.md
│   ├── PHASES.md
│   ├── PROJECT_PHASES_AND_TASKS.md
│   ├── TASKS.md
│   ├── DIAGRAMS.md
│   ├── DEPLOYMENT.md
│   ├── GIT_WORKFLOW.md
│   ├── ADAPTIVE_EVALUATION.md
│   ├── REVIEW_NOTES_v2.md
│   └── RUNBOOK.md
│
├── game/
│   ├── autoload/
│   │   ├── game_state.gd
│   │   ├── player_profile.gd
│   │   ├── event_bus.gd
│   │   └── save_manager.gd
│   ├── scenes/
│   │   ├── main/
│   │   ├── dungeon/
│   │   ├── rooms/
│   │   ├── puzzles/
│   │   └── ui/
│   ├── scripts/
│   │   ├── adaptive/
│   │   ├── puzzles/
│   │   ├── scoring/
│   │   ├── dungeon/
│   │   ├── telemetry/
│   │   └── ai/
│   ├── resources/
│   │   ├── puzzle_defs/
│   │   ├── difficulty_profiles/
│   │   ├── calibration_profiles/
│   │   └── room_defs/
│   └── assets/
│       ├── art/
│       ├── audio/
│       └── fonts/
│
├── backend/                  # optional AI proxy, introduced later
│   ├── app/
│   └── tests/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
│
└── tools/
    ├── validate_puzzles.gd
    ├── simulate_players.gd
    └── export_telemetry.py
```

The game must not depend on the optional backend for its core playable loop.
