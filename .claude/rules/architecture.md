# Architecture Rules

Core dependency direction:

```text
UI / Scenes
   ↓
Game Services
   ↓
Domain Systems
   ↓
Data / Resources
```

The adaptive system receives performance events and emits predicted success / target difficulty. It must not manipulate UI directly.

Puzzle scenes implement a common puzzle interface. Dungeon scenes must not contain puzzle-family-specific answer logic.

Solvers/validators own canonical correctness.

The scheduler owns content selection and variety; it does not update skill directly.

Difficulty calibration consumes telemetry and updates empirical puzzle metadata through a versioned calibration path.

The optional AI adapter returns structured puzzle proposals, never arbitrary executable code.

The core game must remain playable with networking disabled.
