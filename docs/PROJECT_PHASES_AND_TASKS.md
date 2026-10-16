# MindForge — Project Phases & Atomic Tasks

**Single source of truth** for implementation scope and completion.

Status: `[ ]` Not Started · `[-]` In Progress · `[x]` Completed

## Global Definition of Done

Every task must satisfy:

1. Requested implementation exists.
2. Relevant validation/tests pass.
3. Gameplay-critical adaptive/scoring/validation decisions remain deterministic.
4. AI-generated content never bypasses the solver/validation/quarantine pipeline.
5. Core gameplay still works offline.
6. Accessibility settings do not silently penalize inferred skill.
7. No unlicensed assets or committed secrets.
8. Documentation is synchronized.
9. `git diff --check` passes.
10. One task-scoped commit is created for the completed task unless a follow-up fix commit is genuinely required.
11. The task commit is pushed to GitHub and verified when `origin` is configured.
12. No unrelated refactors are included.

See `GIT_WORKFLOW.md` for the mandatory commit/push procedure.

---

## Phase 1 — Foundation, Repository Workflow & Playable 2D Skeleton

### Task 1.1: Godot 4 Project Scaffold & Repository Baseline

**Status:** `[x]` Completed

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create the Godot 4.x project, folder skeleton, base project settings, `.gitignore`, and a bootable empty main scene.
- Pin/document the Godot 4.x version used by the repository once implementation starts.
- Verify a headless project load exits without parser/runtime errors.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.1): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Godot pin: 4.5 stable, GL Compatibility renderer, 1280x720 canvas_items stretch, nearest-neighbour 2D filtering.
- Bootable empty main scene: `res://game/scenes/main/main.tscn` (prints `MindForge boot OK`).
- Folder skeleton from `PROJECT_STRUCTURE.md` created with `.gitkeep` placeholders (`backend/` deferred to Phase 6).
- `.gitignore` covers `.godot/`, `.env`, exports and export credentials; `.gitattributes` normalizes line endings.
- Headless boot check: `tools/check_boot.sh` passed on Godot v4.5.2.stable.official (prints `MindForge boot OK`, no errors).
- Godot 4.5 generates `*.gd.uid` files; they are committed alongside their scripts.
- Git repository initialized locally, then rebased onto the existing GitHub history and pushed in Task 1.2.

---

### Task 1.2: GitHub Remote & Per-Task Commit Workflow Baseline

**Status:** `[x]` Completed

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Verify Git repository state, active branch, and configured `origin`; never invent a remote URL.
- Add/verify the per-task commit workflow and pre-commit checks from `docs/GIT_WORKFLOW.md`.
- Perform a safe push verification when authentication and remote configuration already exist.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.2): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `origin` set to the user-provided `https://github.com/M-Mashreghi/MindForge.git`; branch `main`.
- GitHub already held the uploaded docs (`eaeb3af`, `b0297fc`). The local Task 1.1 commits were rebased onto that history instead of force-pushing; the only conflicts were identical docs and `.gitattributes` (local LF-normalizing version kept).
- Added `tools/precommit_check.sh` (staged whitespace check, `.env`/credential guard, secret pattern scan, optional headless boot) and documented it in `GIT_WORKFLOW.md`.
- Push verified by matching `git rev-parse HEAD` and `git rev-parse @{u}`.

---

### Task 1.3: Autoload Game State and Event Bus

**Status:** `[x]` Completed

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Add minimal `GameState` and centralized event-bus responsibilities without puzzle logic.
- Define events for run start/end, room transition, puzzle start/result, and profile changes.
- Cover initialization and reset behavior with headless validation.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.3): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `EventBus` autoload (`game/autoload/event_bus.gd`): signals only — `run_started`, `run_ended`, `room_entered`, `room_exited`, `puzzle_started`, `puzzle_resolved`, `profile_changed`, `run_state_changed`. No state, no puzzle/scoring logic.
- `GameState` autoload (`game/autoload/game_state.gd`): run seed + seeded RNG, room index/id, rooms cleared, run length, and placeholder score/XP/streak values that later scoring/progression systems write. `start_run(seed)` is deterministic; `reset()` returns to idle; `snapshot()` returns plain data.
- Headless test harness: `tests/run_tests.gd` (SceneTree runner over `tests/unit` and `tests/integration`), `tests/test_case.gd` base, `tools/run_tests.sh` wrapper.
- Validation: `tools/run_tests.sh` — 8 passed, 0 failed (`tests/unit/test_game_state.gd`); `tools/check_boot.sh` OK.

---

### Task 1.4: Main Menu, New Run and Exit Flow

**Status:** `[x]` Completed

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a graphical main menu with New Run, Settings placeholder, and Exit.
- Starting a run must initialize deterministic run state and enter the dungeon scene.
- Keyboard/controller focus behavior must be valid from the first frame.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.4): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Main menu `game/scenes/ui/main_menu.tscn`: title, New Run, Settings (placeholder panel with Back) and Exit. New Run has focus in `_ready`, so keyboard/controller navigation works from the first frame; Esc closes the settings panel.
- New Run calls `GameState.begin_new_run(seed)`: run state is a pure function of the seed (seed picked by `make_run_seed()`), then the dungeon scene loads. Repeated presses start only one run.
- Boot scene now opens the main menu after printing the boot message. Dungeon shell `game/scenes/dungeon/dungeon.tscn`: Esc abandons the run and returns to the menu (`GameState.return_to_main_menu()`).
- Validation: `tools/run_tests.sh` — 13 passed, 0 failed (adds `tests/integration/test_main_menu.gd`); `tools/check_boot.sh` OK.

---

### Task 1.5: Top-Down Player Controller

**Status:** `[x]` Completed

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement responsive 2D movement with configurable input actions and collision-aware movement.
- Keep movement logic separate from dungeon progression and puzzle logic.
- Support keyboard controls without requiring mouse-only interaction.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.5): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Input actions in `project.godot`: `move_left/right/up/down` (WASD, arrow keys, d-pad, left stick) and `interact` (E, Space, Enter, joypad A). Rebindable in Project Settings > Input Map.
- Movement math is a pure `RefCounted` (`game/scripts/dungeon/top_down_motion.gd`): acceleration, friction, max speed, diagonal input clamped to length 1.
- Player scene `game/scenes/dungeon/player.tscn`: `CharacterBody2D` (layer `player`, collides with `world`) using `move_and_slide()`. Emits `interact_requested`; `input_enabled` freezes it for transitions. No room/door/puzzle knowledge.
- Placeholder art drawn in code (circle + facing marker). Player added to the dungeon shell so it is playable.
- Validation: `tools/run_tests.sh` — 20 passed, 0 failed (adds `tests/unit/test_player_motion.gd`: acceleration, diagonal cap, friction, determinism, keyboard bindings, wall collision, disabled input); `tools/check_boot.sh` OK.

---

### Task 1.6: Reusable Dungeon Room Scene

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a reusable graphical room scene with spawn point, exits/doors, puzzle anchor, and room metadata.
- Room scene must not contain family-specific answer validation.
- Instantiate at least one fixture room in a deterministic demo flow.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(1.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 1.7: Room Transition and Door State Flow

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement room-enter/exit transitions and locked/unlocked/solved door states.
- Prevent transition before room success unless the room explicitly allows retreat.
- Ensure transition events cannot double-fire from repeated input.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(1.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 1.8: HUD Shell: Score, XP, Streak and Room

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 1 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a reusable HUD that reads state rather than owning score/progression logic.
- Display score, XP/progress, streak, and room/run progress with placeholder-safe values.
- Ensure layout remains readable at the minimum supported window size.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(1.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Phase 2 — Puzzle Framework & Three Puzzle Families

### Task 2.1: Common Puzzle Resource Schema and Interface

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement the shared puzzle resource/data contract from `PUZZLE_SPEC.md`.
- Include provenance, target/calibrated difficulty, confidence, fingerprint, schema/content version, hints, and canonical solution fields.
- Reject malformed puzzle resources before presentation.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.1): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.2: Puzzle Host Scene and Result Contract

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a family-agnostic host scene that loads puzzle data and emits a standardized result event.
- Result must include correctness, attempts, hints, response time, puzzle identity/version, and source.
- Host must not know family-specific solution logic.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.2): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.3: Pattern Puzzle Renderer and Input Flow

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Render pattern puzzle state graphically using structured puzzle data.
- Support clear selectable/enterable answers and accessible focus behavior.
- Keep visual presentation independent from canonical validation.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.3): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.4: Pattern Puzzle Deterministic Solver and Validator

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement solver/validator logic from structured pattern parameters rather than stored LLM prose.
- Reject zero-solution, inconsistent, or unsupported-rule instances.
- Provide fixtures covering easy, medium, hard, and invalid cases.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.4): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.5: Logic Puzzle Renderer and Input Flow

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a reusable graphical logic-puzzle presentation for supported constraint mechanics.
- Represent user choices independently from the constraint solver.
- Provide explicit submit/reset interaction and clear state feedback.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.5): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.6: Logic Puzzle Deterministic Solver and Uniqueness Validator

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement constraint solving sufficient for v1 logic templates.
- Verify exactly one intended solution for single-answer puzzles.
- Reject unsatisfiable and ambiguous/multi-solution instances.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.7: Memory Puzzle Renderer and Timing Flow

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement rune/tile/sequence presentation with separate show, conceal, answer, and feedback states.
- Keep canonical memory sequence independent from display timing.
- Support adjustable timing without changing puzzle identity.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.8: Memory Puzzle Deterministic Validator

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Validate sequence/position recall against canonical stored state.
- Support deterministic partial/complete response rules defined by the puzzle contract.
- Test accessibility-adjusted timing produces identical correctness results.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.9: Tiered Hint Ladder

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement ordered hint levels with explicit cost metadata and no first-hint answer leakage.
- Track hint usage in the standardized performance event.
- Prevent repeated requests from granting duplicate scoring penalties.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.9): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 2.10: Local Puzzle Bank, Schema Validation and Fingerprints

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 2 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a local content bank containing valid fixtures for all three puzzle families.
- Validate all bundled content via a repository tool/headless check.
- Generate stable fingerprints to identify exact duplicates and support anti-repetition.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(2.10): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Phase 3 — Player Modeling & Adaptive Difficulty

### Task 3.1: Player Skill Profile with Confidence and Observation Counts

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Store overall and per-family skill, confidence, and observation count with bounded values.
- Cold-start state must be deterministic and migration-friendly.
- Do not infer missing family skill from another family without an explicit rule.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.1): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.2: Performance Event Normalization with Accessibility-Safe Timing

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Normalize correctness, hints, attempts, and bounded timing into a deterministic performance representation.
- Correctness must dominate response speed.
- Timing accommodations must not silently penalize inferred cognitive skill.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.2): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.3: Elo-Like Base Skill Update Engine

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement a transparent deterministic base update using expected vs observed performance.
- Expose configurable scale/K parameters with bounded per-event changes.
- Provide monotonic unit tests across player-skill and puzzle-difficulty differences.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.3): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.4: Family-Specific and Overall Skill Updates

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Update the active family skill primarily and overall skill conservatively.
- Keep unrelated family ratings unchanged unless a documented cross-family rule exists.
- Record before/after values for telemetry/debugging.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.4): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.5: Predicted-Success Model

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement a deterministic probability-of-success function using skill and difficulty.
- Guarantee monotonicity with respect to player skill and puzzle difficulty.
- Expose the value to the selector, telemetry, and debug overlay.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.5): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.6: Target-Success Band and Difficulty Selector

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Select a difficulty band from a configurable predicted-success target rather than a fixed raw offset alone.
- Support distinct standard, recovery, challenge, and boss target bands.
- Respect available-content bounds and return a documented fallback when no exact fit exists.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.7: Confidence-Aware Updates and Anti-Oscillation

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Scale update responsiveness using observation count/confidence.
- Cap per-puzzle skill changes and smooth consecutive selected difficulty.
- Add regression fixtures for lucky-answer spikes and one-off failures.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.8: Failure Recovery Mode with Hysteresis

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Enter recovery from defined repeated-failure/hint-exhaustion signals.
- Use an easier target-success band and familiar mechanics rather than abrupt trivialization.
- Require stable recovery evidence before exiting to prevent mode flapping.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.9: Cold-Start Calibration Session

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Design a short multi-family onboarding sequence that gathers evidence without feeling like an exam.
- Initialize confidence/skill from deterministic outcomes while keeping changes bounded.
- Allow skipping calibration and falling back to neutral priors.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.9): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 3.10: Adaptive Scheduler Policy: Fit, Variety and Weakness Guardrails

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 3 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Combine difficulty fit with novelty, recent-history, family coverage, and recovery state.
- Do not endlessly drill the weakest family or repeatedly choose the numerically closest puzzle.
- Expose scheduler reasons in developer/debug mode.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(3.10): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Phase 4 — Scoring, Progression, Save & Player Feedback

### Task 4.1: Deterministic Scoring Formula

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement base score multiplied by bounded deterministic multipliers.
- Keep scoring independent from skill-estimation updates.
- Document caps/floors and verify identical inputs produce identical scores.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.1): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 4.2: Speed, Hint, Attempt and Streak Multipliers

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement individually testable multipliers with explicit caps.
- Ensure speed is not dominant and accommodations can neutralize timing effects.
- Prevent negative or unbounded scores.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.2): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 4.3: XP and Profile Progression

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement lifetime XP and profile progression separate from adaptive skill.
- Do not equate XP level with cognitive skill.
- Persist progression through the versioned save model.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.3): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 4.4: Puzzle Success / Failure Feedback

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Add clear graphical/audio hook points for success, failure, hint use, and room completion.
- Feedback must not reveal future answers.
- Allow reduced-motion settings to suppress nonessential motion.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.4): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 4.5: Run Summary and Skill-Change Screen

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Summarize score, family performance, hints, progression, and high-level skill movement.
- Use player-friendly wording and never label the player weak/strong.
- Keep detailed internal math behind developer/debug mode.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.5): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 4.6: Versioned Atomic Save / Load, Migration and Recovery

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement schema-versioned save/load with atomic replacement where practical.
- Add migration hooks and a backup/recovery path for corrupted saves.
- Test round-trip, old-version migration, corrupted-save handling, and unsupported-future-version behavior.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 4.7: Pause, Restart and Safe Return-to-Menu Flow

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement pause/resume and safe run-abandon confirmation.
- Prevent partial state corruption during scene changes or save operations.
- Ensure restart semantics are deterministic for seeded runs.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 4.8: Basic Audio / Animation Feedback Hooks

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 4 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create centralized hook points for SFX, transitions, puzzle feedback, and XP/score animation.
- Use placeholders or clearly licensed assets only.
- Respect master volume and reduced-motion/accessibility settings.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(4.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Phase 5 — Procedural Dungeon & Content Scheduling

### Task 5.1: Seeded Dungeon Run Generator

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Generate a deterministic room plan from a run seed.
- Same compatible content/version + seed must reproduce the same structural run plan.
- Keep room generation separate from puzzle solution generation.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.1): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 5.2: Difficulty-Aware Room Planner

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Map adaptive target bands to room challenge profiles and candidate content.
- Gracefully degrade when ideal-difficulty content is unavailable.
- Record the selection reason for telemetry/debugging.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.2): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 5.3: Puzzle-Family Rotation and Anti-Repetition

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Track recent puzzle families, mechanics, and fingerprints.
- Apply cooldown/penalty to immediate repeats while respecting recovery needs.
- Test that variety rules do not make content selection impossible.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.3): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 5.4: Local Procedural Pattern Generator

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Generate structured pattern parameters from a seed and requested difficulty features.
- Use the deterministic pattern solver to derive solutions.
- Reject unsupported/ambiguous output before adding it to the candidate pool.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.4): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 5.5: Local Procedural Logic Generator

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Generate bounded constraint sets using deterministic seeds.
- Verify satisfiability and uniqueness with the logic solver.
- Scale difficulty through rule depth/constraint structure rather than text obscurity.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.5): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 5.6: Local Procedural Memory Generator

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Generate deterministic sequences/layouts using difficulty-controlled length/interference features.
- Keep presentation timing separately configurable.
- Ensure accessibility timing changes do not alter content identity.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 5.7: Puzzle Solvability, Ambiguity and Content Quality Pipeline

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create one common validation pipeline used by local, procedural, and AI content.
- Include schema, solver, uniqueness/ambiguity, bounds, fingerprint, and safety checks.
- Return structured rejection reasons suitable for telemetry/debugging.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 5.8: Boss-Room Template and Multi-Skill Challenge

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 5 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement deterministic boss templates combining at least two puzzle skills without mixing validators unsafely.
- Use an intentionally harder but bounded target-success profile.
- Boss failure must support recovery/retry without corrupting the adaptive profile.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(5.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Phase 6 — AI Puzzle Generation & Safe Content Pipeline

### Task 6.1: AI Puzzle JSON Contract and Prompt Versioning

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Define strict structured output schemas for supported AI puzzle families.
- Version prompt, schema, validator, and solver metadata.
- Reject unknown fields or oversized content according to parser policy.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.1): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.2: Optional Secret-Safe AI Proxy Skeleton

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a minimal optional proxy boundary so provider keys never ship in Godot.
- Support timeouts, bounded request size, and provider abstraction.
- Core gameplay must run with the proxy absent.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.2): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.3: Godot AI Content Adapter

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Implement structured requests/responses without provider-specific logic in gameplay systems.
- Return typed success/error states instead of unhandled gameplay errors.
- Never let the adapter update score, skill, or save data.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.3): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.4: Solver-First AI Pattern Puzzle Generation

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Ask AI for supported structured pattern parameters/rule data, not an authoritative final answer.
- Derive canonical solution with the deterministic solver.
- Reject content whose declared answer conflicts with deterministic solving.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.4): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.5: Solver-First AI Logic Puzzle Generation

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Ask AI for bounded constraints/mechanics supported by the deterministic solver.
- Compute and verify the canonical solution/uniqueness locally.
- Reject unsupported mechanics rather than executing generated code.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.5): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.6: Grounded AI Hint and Explanation Generation

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Generate hints/explanations only from validated puzzle structure and canonical solution.
- Enforce ordered hint strength and answer-leakage checks where practical.
- Fallback to deterministic/local hint text on invalid AI output.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.7: AI Text Sanitization and Content Safety Gate

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Sanitize markup/control characters and enforce display-length limits.
- Reject content outside the game's allowed tone/safety policy.
- Never render raw unvalidated provider output directly in the UI.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.8: AI Puzzle Validation, Difficulty Plausibility and Quarantine

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Run AI proposals through the full common validation pipeline before activation.
- Treat AI difficulty as provisional and compare against deterministic complexity features.
- Quarantine failures with structured reasons; never silently activate them.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.9: Generated-Content Fingerprint, Deduplication and Variety Gate

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Fingerprint validated generated content before caching/scheduling.
- Reject exact duplicates and penalize recent near-repeat mechanics.
- Preserve provenance so generated puzzles can be traced and invalidated.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.9): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.10: Validated AI Puzzle Cache and Version Invalidation

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Cache only fully validated content with model/prompt/schema/solver/validator versions.
- Invalidate or revalidate entries after incompatible schema/validation changes.
- Never cache provider secrets or unnecessary personal telemetry.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.10): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 6.11: Async Pre-Generation, Timeout and Offline Fallback

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 6 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Pre-generate opportunistically so network latency does not block room transitions.
- Use bounded timeouts/retries and cancel stale requests.
- Fallback to local/procedural content while preserving target difficulty as closely as possible.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(6.11): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Phase 7 — Telemetry, Simulation & Difficulty Calibration

### Task 7.1: Local Telemetry Event Schema with Adaptive Provenance

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Record puzzle/content versions, source, target/calibrated difficulty, confidence, predicted success, skill before/after, and algorithm version.
- Use local session identifiers without unnecessary personal information.
- Version the event schema.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.1): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.2: Puzzle Performance Recorder

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Persist local performance events safely and append-only where practical.
- Handle failed writes without breaking gameplay.
- Provide deterministic export/readback for analysis tools.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.2): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.3: Developer Skill / Difficulty Debug Overlay

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Display skill/confidence, predicted success, target band, selected difficulty, scheduler reason, and recovery state.
- Keep it disabled in normal player-facing mode.
- Do not let debug controls silently mutate production save data.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.3): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.4: Batch Simulated-Player Harness

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Simulate strong, average, struggling, improving, inconsistent, and family-specialist latent profiles.
- Use deterministic seeds and export comparable run summaries.
- Keep simulator behavior independent from the adaptive algorithm under test.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.4): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.5: Adaptive Convergence, Oscillation and Recovery Metrics

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Measure target-band occupancy, convergence, oscillation, overshoot, and recovery time.
- Add regression thresholds/fixtures for obvious adaptation failures.
- Evaluate each puzzle family independently as well as overall.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.5): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.6: Empirical Puzzle Difficulty Calibration with Confidence

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Estimate calibrated difficulty only after a configurable minimum sample threshold.
- Track calibration confidence/sample count and algorithm version.
- Do not overwrite authored/target difficulty or learn from malformed telemetry.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.7: Puzzle Completion, Hint and Abandonment Analytics

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Summarize success, hints, attempts, completion time, abandonment proxies, and family-specific outcomes.
- Separate accessible-timing cohorts when timing affects interpretation.
- Avoid treating engagement proxies as direct cognitive ability.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.8: Adaptive-vs-Static Difficulty Comparison Experiment

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Compare adaptive and static schedules using identical simulated latent players/seeds.
- Evaluate challenge fit, progression, oscillation, hint usage, and frustration proxies—not score alone.
- Export a reproducible comparison report.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 7.9: Balance Regression Fixtures

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 7 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Freeze representative seeds/player profiles as balance regression fixtures.
- Detect unintended large shifts after adaptive algorithm/config changes.
- Require deliberate fixture/version updates when balance changes are intentional.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(7.9): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Phase 8 — Polish, Accessibility, CI/CD & Release

### Task 8.1: Godot Headless Validation Test Suite

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Provide one repeatable command/script that runs core headless validations.
- Include puzzle, adaptive, save, procedural generation, and AI-fallback tests.
- Return non-zero exit status on blocking failures for CI.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.1): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 8.2: Accessibility: Timer, Motion, Readability and Input Options

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Add adjustable/disable-able timers where supported, reduced motion, readable UI scaling, and keyboard/controller navigation.
- Ensure accommodations do not automatically lower skill estimates or scoring fairness.
- Persist settings separately from cognitive skill.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.2): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 8.3: Visual Theme and Placeholder Asset Cleanup

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Create a coherent graphical dungeon/puzzle visual language using original or clearly licensed assets.
- Maintain readable contrast and non-color-only cues.
- Document asset licenses/provenance.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.3): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 8.4: Performance and Scene-Load Profiling

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Profile room transitions, puzzle scene creation, telemetry writes, and AI-prefetch boundaries.
- Remove avoidable frame stalls in the normal offline loop.
- Record a lightweight performance baseline for the demo target machine.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.4): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 8.5: Desktop Export Presets

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Configure reproducible desktop export presets for target platforms.
- Exclude secrets, debug-only telemetry, and development artifacts.
- Smoke-test exported build startup and a short playable run.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.5): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 8.6: GitHub Actions CI

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Run repository validation/headless checks on pushes and pull requests.
- Cache dependencies only when safe and reproducible.
- Fail CI on blocking validation errors or test regressions.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.6): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 8.7: Secrets, Licensing and Dependency Audit

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Verify no provider keys, `.env`, private tokens, or unlicensed assets are committed.
- Inventory third-party addons/libraries/assets and licenses.
- Remove unused dependencies before portfolio release.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.7): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

### Task 8.8: Release Runbook and Portfolio Demo Checklist

**Status:** `[ ]` Not Started

**Purpose**  
Advance Phase 8 while keeping the game playable, deterministic where required, and narrowly scoped to this task.

**Task-Specific Implementation Contract**
- Document clean-clone setup, Godot version, run/test/export steps, optional AI setup, and offline mode.
- Define a polished 15–25 minute demo path showing distinct adaptation for strong vs struggling profiles.
- Verify GitHub history contains task-scoped commits and the release commit/tag is pushed.

**Required Verification**
- Run the tests/validation directly relevant to this task.
- Run `git diff --check`.
- Confirm no unrelated files or secrets are staged.
- Confirm the core offline game loop still starts when this task touches runtime code.

**Definition of Done**
- [ ] Task-specific implementation exists.
- [ ] Relevant automated/headless validation passes.
- [ ] No new runtime errors in the affected playable flow.
- [ ] Documentation and task status are synchronized.
- [ ] A dedicated `task(8.8): ...` Git commit exists.
- [ ] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [ ] Scope does not spill into the next task.

---

## Progress Summary

| Phase | Tasks | Completed |
|---|---:|---:|
| 1 — Foundation, Repository Workflow & Playable 2D Skeleton | 8 | 0 |
| 2 — Puzzle Framework & Three Puzzle Families | 10 | 0 |
| 3 — Player Modeling & Adaptive Difficulty | 10 | 0 |
| 4 — Scoring, Progression, Save & Player Feedback | 8 | 0 |
| 5 — Procedural Dungeon & Content Scheduling | 8 | 0 |
| 6 — AI Puzzle Generation & Safe Content Pipeline | 11 | 0 |
| 7 — Telemetry, Simulation & Difficulty Calibration | 9 | 0 |
| 8 — Polish, Accessibility, CI/CD & Release | 8 | 0 |
| **Total** | **72** | **0** |
