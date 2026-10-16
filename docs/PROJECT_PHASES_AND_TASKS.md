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

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.6): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Room metadata resource `game/scripts/dungeon/room_def.gd`: id, display name, room type (standard/recovery/challenge/boss), size, spawn point and puzzle anchor (fractions of size), retreat flag, door flags, requested puzzle family. No answers.
- Reusable room `game/scenes/rooms/dungeon_room.tscn`: floor, collision walls with door gaps, `SpawnPoint`, `PuzzleAnchor` (placeholder pedestal), `EntryDoor` / `ExitDoor` (`door.tscn`, Area2D that reports `player_reached`). The room re-emits `door_reached` and contains no answer validation.
- Fixture rooms in `game/resources/room_defs/`: `fixture_entrance`, `fixture_gallery`, `fixture_vault`.
- Deterministic demo flow: `dungeon.tscn` loads the fixed fixture list, centers the room, places the player at the spawn point and calls `GameState.enter_room()`. Running the dungeon scene directly starts a run with `DEMO_SEED`.
- Validation: `tools/run_tests.sh` — 26 passed, 0 failed (adds `tests/integration/test_dungeon_room.gd`); `tools/check_boot.sh` OK.

---

### Task 1.7: Room Transition and Door State Flow

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.7): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Door states (`game/scenes/rooms/door.gd`): `LOCKED` (a blocker body closes the gap), `UNLOCKED` (open, used for retreat entries) and `SOLVED` (exit open after success). Each state has a distinct shape, not only a color.
- Room (`dungeon_room.gd`): exit stays `LOCKED` until `mark_solved()`; entry is `UNLOCKED` only when `RoomDef.allows_retreat`. Solved state is set from a puzzle result, never computed by the room.
- Dungeon (`dungeon.gd`): fade-out / swap / fade-in transitions; next room through a passable exit, previous room through an unlocked entry (progress kept), final exit ends the run (`completed`) and returns to the menu. `GameState.enter_room()` now takes the room's sequence index.
- Double-fire protection: `game/scripts/dungeon/transition_guard.gd` latch plus deferred transition start; player input is disabled while a transition runs.
- Placeholder until Task 2.2: pressing interact at the puzzle pedestal emits `puzzle_started` / `puzzle_resolved` with a placeholder correct result.
- Validation: `tools/run_tests.sh` — 37 passed, 0 failed (adds `tests/integration/test_room_transitions.gd`: door states, locked-door blocking, next/retreat/final transitions, wrong answer keeps exit locked, no double-fire); `tools/check_boot.sh` OK.

---

### Task 1.8: HUD Shell: Score, XP, Streak and Room

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(1.8): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- HUD `game/scenes/ui/hud.tscn` (CanvasLayer, top bar): room progress (`Room 2 / 3`, `Cleared 1`), score, XP with progress bar, streak. Labels plus captions, so no value relies on color alone.
- `hud.gd` only reads `GameState.snapshot()` on `EventBus.run_state_changed`; the pure `format_values()` turns missing, negative or out-of-range values into safe placeholders (`Room - / -`, `0`, `x0`). `GameState.xp_progress` added as a placeholder field for Task 4.3.
- Minimum window size 960x540 (set in the boot scene). The UI is laid out at 1280x720 with `canvas_items` stretch; the smallest HUD font is 15 px at the minimum size, and the bar fits within 960 px even unscaled.
- HUD added to the dungeon scene; dark default clear color; README lists the Phase 1 controls.
- Validation: `tools/run_tests.sh` — 43 passed, 0 failed (adds `tests/integration/test_hud.gd`); `tools/check_boot.sh` OK; windowed screenshots of the menu and rooms checked by eye.

---

## Phase 2 — Puzzle Framework & Three Puzzle Families

### Task 2.1: Common Puzzle Resource Schema and Interface

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.1): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Common schema `game/scripts/puzzles/puzzle_schema.gd` (schema v2): id, family, schema/content version, source (`local|procedural|ai`), seed (required for procedural), target/calibrated difficulty (0..1000), difficulty confidence (0..1), prompt, canonical solution, hints `{text, cost}` ordered by non-decreasing cost, time band, tags, provenance (author or generator), optional `max_attempts`, `presentation` and `fingerprint`.
- `PuzzleData.parse()` (`puzzle_data.gd`) normalizes JSON numbers, validates, then builds a read-only instance; malformed data returns errors and no instance. `identity()` gives the block used by results/telemetry; `effective_difficulty()` prefers calibrated difficulty.
- Family interface via `puzzle_registry.gd`: each family registers a deterministic validator (`validate`, `solve`, `check_response`, `mechanics`, `answer_tokens`) and a renderer scene. Generic code holds no family answer logic.
- Fingerprint: SHA-256 of canonical JSON (`canonical_json.gd`, sorted keys, int/float-normalized) over the family's mechanics, so wording/presentation does not change identity.
- Validation: `tools/run_tests.sh` — 51 passed, 0 failed (adds `tests/unit/test_puzzle_schema.gd` with a test-only `doubling` family in `tests/fixtures/`); `tools/check_boot.sh` OK.

---

### Task 2.2: Puzzle Host Scene and Result Contract

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.2): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `PuzzleHost` (`game/scenes/puzzles/puzzle_host.tscn`): overlay panel that takes a `PuzzleData`, instantiates the family renderer from the registry, checks each response with the family validator, counts attempts against `max_attempts`, and supports Leave (abandon).
- Standardized result (documented in `PUZZLE_SPEC.md`): correctness, abandoned, attempts, hints used/cost, response time (injectable clock), timing-accommodation flag, validator details, and the puzzle identity block (id, family, schema/content version, source, seed, fingerprint, difficulty). Emitted once via `finished` and `EventBus.puzzle_resolved`.
- Renderer base `puzzle_renderer.gd`: `setup()`, `response_submitted`, `show_feedback()`, `set_input_enabled()`, `initial_focus()`. Renderers never decide correctness.
- Validation: `tools/run_tests.sh` — 58 passed, 0 failed (adds `tests/integration/test_puzzle_host.gd`, run against the test-only `doubling` family to prove the host is family-agnostic; also checks the host source has no family names); `tools/check_boot.sh` OK.

---

### Task 2.3: Pattern Puzzle Renderer and Input Flow

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.3): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Pattern renderer `game/scenes/puzzles/pattern/pattern_renderer.tscn`: draws `prompt.sequence` as tiles plus a `?` slot, and `prompt.choices` as large focusable buttons. Numbers render as text; symbol values render as distinct shapes (`symbol_glyph.gd`: circle, triangle, square, diamond, star, hexagon, cross, ring) with a name tooltip.
- Response contract: `{"answer": <chosen value>}`. The renderer never judges; after the host's check it marks the choice with ✓ / ✗ (symbol and color), disables a wrong non-final choice and moves focus to the next enabled one.
- Keyboard/controller: first choice is the initial focus; arrow keys move between choices, Enter/Space/A selects.
- Validation: `tools/run_tests.sh` — 63 passed, 0 failed (adds `tests/integration/test_pattern_renderer.gd`); `tools/check_boot.sh` OK.

---

### Task 2.4: Pattern Puzzle Deterministic Solver and Validator

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.4): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Pattern family `game/scripts/puzzles/pattern_family.gd`, registered as a built-in family. Supported rules with structured parameters: `arithmetic` (start, step != 0), `geometric` (start != 0, |ratio| 2..5), `alternating` (start, two different steps), `recurrence` (a, b; sum of previous two), `symbol_cycle` (2..5 unique known symbols, offset).
- The solver derives the canonical next term from rule + parameters; the validator rejects unsupported rules, invalid parameters, visible sequences that do not follow the rule (inconsistent), choice lists with no correct option (zero solutions) or duplicates, too-short sequences (symbol cycles must show the full cycle plus one, so the answer is unambiguous), values beyond ±1,000,000, and stored solutions that differ from the solver.
- Fingerprint mechanics = rule + params + shown length (distractors/choice order excluded).
- Bundled fixtures `game/resources/puzzle_bank/pattern.json`: 2 easy, 2 medium, 2 hard. Invalid fixtures `tests/fixtures/pattern_invalid.json` (8 cases).
- `PuzzleCatalog` (`puzzle_catalog.gd`) loads the bank, keeps only valid puzzles and records rejections. The dungeon opens the room's puzzle in `PuzzleHost` at the pedestal (seed-deterministic choice, same puzzle on retry, Esc gives up); rooms without content for their family still use the placeholder.
- Validation: `tools/run_tests.sh` — 74 passed, 0 failed (adds `tests/unit/test_pattern_family.gd`, `tests/integration/test_dungeon_puzzles.gd`); `tools/check_boot.sh` OK.

---

### Task 2.5: Logic Puzzle Renderer and Input Flow

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.5): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Logic renderer `game/scenes/puzzles/logic/logic_renderer.tscn` for the v1 `ordering` template: clue list, numbered slot row, item palette (symbol shape + name), Reset and Submit.
- Clue text is generated from structured clues (`before`, `adjacent`, `not_adjacent`, `at`, `not_at`; 1-based slot numbers for players), so no stored prose is trusted.
- Player choices live in `game/scripts/puzzles/logic_board.gd`, a pure board model (place / move / clear / reset / complete) independent of the solver.
- Explicit interaction: item buttons fill the next empty slot, pressing a filled slot empties it, Submit is enabled only when every slot is filled and emits `{"order": [...]}`; a state line shows progress and ✓ / ✗ feedback text.
- Validation: `tools/run_tests.sh` — 79 passed, 0 failed (adds `tests/integration/test_logic_renderer.gd`); `tools/check_boot.sh` OK.

---

### Task 2.6: Logic Puzzle Deterministic Solver and Uniqueness Validator

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.6): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Logic family `game/scripts/puzzles/logic_family.gd`, registered as a built-in family (renderer from Task 2.5). v1 template `ordering` with 3..6 unique symbol items and 1..10 clues of types `before`, `adjacent`, `not_adjacent`, `at`, `not_at`.
- Solver: exhaustive deterministic search over all arrangements (at most 720), so solution counts are exact. `solve()` returns the order only when exactly one exists.
- Validator rejects unsupported templates/clue types, unknown or duplicate items, out-of-range positions, unsatisfiable clue sets (zero solutions), ambiguous ones (more than one solution) and stored solutions that differ from the solver.
- `check_response()` accepts an arrangement that uses every item once and satisfies every clue (= the unique solution), and reports how many clues were broken.
- Fingerprint mechanics = template + sorted items + sorted canonical clues (presentation order excluded).
- Bundled fixtures `game/resources/puzzle_bank/logic.json` (2 easy, 2 medium, 2 hard; uniqueness verified both by the generator and by the Godot solver in tests). Invalid fixtures `tests/fixtures/logic_invalid.json` (8 cases). The second fixture room now opens a real logic puzzle.
- Validation: `tools/run_tests.sh` — 86 passed, 0 failed (adds `tests/unit/test_logic_family.gd`); `tools/check_boot.sh` OK.

---

### Task 2.7: Memory Puzzle Renderer and Timing Flow

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.7): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Memory renderer `game/scenes/puzzles/memory/memory_renderer.tscn`: grid of cells with explicit phases SHOW (target cells light up with a star shape, one at a time in `sequence` mode, together in `positions` mode), CONCEAL (blank), ANSWER (pick cells; pick order shown as numbers, Undo, Submit when the right number is picked) and FEEDBACK (✓ / ✗; a non-final miss clears picks and returns to ANSWER).
- Timing schedule is a pure function (`game/scripts/puzzles/memory_timing.gd`) of `presentation` (`show_ms`, `gap_ms`, `conceal_ms`) and the host's accessibility `timing_scale` (0.5..4). The canonical target cells are never altered, so timing does not change puzzle identity.
- Response contract: `{"cells": [picked cell indices in pick order]}`. Input is disabled while showing/concealing.
- Validation: `tools/run_tests.sh` — 92 passed, 0 failed (adds `tests/integration/test_memory_renderer.gd`: schedule shape, scaled timing keeps cells, phase transitions, answer flow, positions toggling); `tools/check_boot.sh` OK.

---

### Task 2.8: Memory Puzzle Deterministic Validator

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.8): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Memory family `game/scripts/puzzles/memory_family.gd`, registered as a built-in family (renderer from Task 2.7). Prompt: `mode` (`sequence` / `positions`), `grid` (2..5 x 2..5), unique in-grid `target` cells (2..9), optional `scoring`; solution must equal the canonical target.
- Response rules defined by the contract: `sequence` counts a cell only at the same position; `positions` counts each target cell once in any order. `exact` (default) needs complete recall with no extra picks; `threshold` passes at `min_correct` matches. Result details: `correct`, `complete`, `matched`, `total`.
- Fingerprint mechanics = mode + grid + target (sorted for positions) + scoring; presentation timing excluded.
- Bundled fixtures `game/resources/puzzle_bank/memory.json` (2 easy, 2 medium, 2 hard, including threshold scoring). Invalid fixtures `tests/fixtures/memory_invalid.json` (7 cases). All three fixture rooms now open real puzzles.
- Accessibility: a test plays the renderer at 1x and 3x timing with the same picks and gets identical validator results.
- Validation: `tools/run_tests.sh` — 100 passed, 0 failed (adds `tests/unit/test_memory_family.gd`); `tools/check_boot.sh` OK.

---

### Task 2.9: Tiered Hint Ladder

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.9): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `HintLadder` (`game/scripts/puzzles/hint_ladder.gd`): ordered levels with explicit cost metadata (`{text, cost}`, cost non-decreasing). Each level is charged once; requests after the last level return nothing and add no cost; re-reading revealed hints is free.
- No first-hint leakage: the schema rejects a puzzle whose first hint contains an answer token from the family validator (`answer_tokens()`), matched as whole words/numbers and case-insensitively. A test checks every bundled puzzle.
- `PuzzleHost` gets a Hint button ("Hint (n left)", disabled when exhausted or finished) and a list of revealed hints; the standardized result reports `hints_used` and `hint_cost` from the ladder.
- Validation: `tools/run_tests.sh` — 106 passed, 0 failed (adds `tests/unit/test_hint_ladder.gd`); `tools/check_boot.sh` OK.

---

### Task 2.10: Local Puzzle Bank, Schema Validation and Fingerprints

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(2.10): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Local content bank `game/resources/puzzle_bank/` with valid fixtures for all three families (pattern, logic, memory: 6 each, easy/medium/hard).
- `PuzzleCatalog` now rejects duplicate ids and exact duplicates (same mechanics fingerprint, even with new id, wording or choice order), keeps a fingerprint index, and `pick_for_room()` skips fingerprints already used in the run when possible (anti-repetition). The dungeon passes the run's used fingerprints.
- Repository tool `tools/validate_puzzles.gd` / `tools/validate_puzzles.sh`: validates every bundled puzzle, requires every registered family to have content, rejects duplicates, and compares fingerprints with the committed snapshot `tests/fixtures/bank_fingerprints.json` (`--write-fingerprints` refreshes it after intentional changes). The pre-commit script runs it when `GODOT` is set.
- Validation: `tools/run_tests.sh` — 112 passed, 0 failed (adds `tests/unit/test_puzzle_bank.gd`: coverage, stable fingerprints, duplicate rejection, anti-repetition, deterministic picks); `tools/validate_puzzles.sh` — 18 valid, 0 rejected; `tools/check_boot.sh` OK.

---

## Phase 3 — Player Modeling & Adaptive Difficulty

### Task 3.1: Player Skill Profile with Confidence and Observation Counts

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.1): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `SkillProfile` (`game/scripts/adaptive/skill_profile.gd`): overall + `pattern` / `logic` / `memory` entries, each `{rating, confidence, observations}`. Ratings bounded to 0..1000, confidence to 0..0.95, observations >= 0 (`adaptive_config.gd`).
- Deterministic cold start: every entry at the neutral prior 500 with zero confidence and observations.
- Explicit no-inference rule: a family without evidence (including unknown families) reads as the prior; it is never derived from another family.
- Migration-friendly `to_dict()` / `load_dict()` with profile and algorithm versions: missing entries fall back to the prior, values are clamped, unknown extra families are kept.
- `PlayerProfile` autoload (`game/autoload/player_profile.gd`) holds the in-memory profile (saving is Task 4.6).
- Validation: `tools/run_tests.sh` — 119 passed, 0 failed (adds `tests/unit/test_skill_profile.gd`); `tools/check_boot.sh` OK.

---

### Task 3.2: Performance Event Normalization with Accessibility-Safe Timing

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.2): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `PerformanceEvent.normalize()` (`game/scripts/adaptive/performance_event.gd`) maps a PuzzleHost result to a deterministic `observed_score` in [0, 1] plus its components (attempt/hint/slow penalties, partial credit, timing used + reason, versions).
- Correctness dominates: a correct answer never scores below 0.6; an incorrect one never above 0.2 (partial credit from validator `matched/total`); abandoned scores 0. Secondary penalties are capped: attempts 0.1 each up to 0.2, hints 0.4 x hint cost up to 0.25, slowness up to 0.1.
- Accessibility-safe timing: ignored when a timing accommodation is active, when the puzzle has no time band, or when the response is outside sensible bounds (< 0.5 s or > 4x the band's upper bound). Inside the band speed is neutral, so fast play is never rewarded over correctness.
- Parameters live in `adaptive_config.gd`.
- Validation: `tools/run_tests.sh` — 128 passed, 0 failed (adds `tests/unit/test_performance_event.gd`); `tools/check_boot.sh` OK.

---

### Task 3.3: Elo-Like Base Skill Update Engine

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.3): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `Elo` (`game/scripts/adaptive/elo.gd`): pure functions. `expected = 1 / (1 + 10^((difficulty - skill) / scale))`, `delta = clamp(k * (observed - expected), -cap, cap)`, `update()` clamps the rating to 0..1000.
- Configurable in `adaptive_config.gd`: `logistic_scale` 250 (250 points of advantage = 10x odds on the 0..1000 scale), `k_factor` 40, `max_delta_per_event` 30.
- Validation: `tools/run_tests.sh` — 136 passed, 0 failed (adds `tests/unit/test_elo.gd`: even match = 0.5, monotonic in skill and difficulty, scale steepness, update direction, larger moves for surprises, gain shrinks as skill rises, per-event cap and bounds, determinism); `tools/check_boot.sh` OK.

---

### Task 3.4: Family-Specific and Overall Skill Updates

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.4): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `SkillModel.apply()` (`game/scripts/adaptive/skill_model.gd`): the puzzle's family rating moves with the full K; overall moves with `overall_k_weight` 0.35 of it; all other families stay unchanged (no cross-family rule in v1). Observation counts increase for the family and overall.
- Every update returns a record with algorithm version, family, difficulty, puzzle confidence, observed score and, for family and overall, expected success, K, rating / confidence / observations before and after.
- `PlayerProfile` applies every validated puzzle result from `EventBus.puzzle_resolved` (placeholder results ignored), using calibrated difficulty when present, and keeps the last 50 update records in `history`. The puzzle result identity now includes `time_band_seconds` so timing can be normalized.
- Validation: `tools/run_tests.sh` — 141 passed, 0 failed (adds `tests/unit/test_skill_model.gd`); `tools/check_boot.sh` OK.

---

### Task 3.5: Predicted-Success Model

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.5): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `SuccessPredictor` (`game/scripts/adaptive/success_predictor.gd`): deterministic logistic probability of success from family skill and the puzzle's effective difficulty (calibrated when available), clamped to [0.01, 0.99]; `difficulty_for(skill, p)` is its exact inverse for the selector; `predict_puzzle()` returns a versioned record (skill, confidence, difficulty, difficulty confidence, predicted success).
- Exposure: `PlayerProfile.predict()` keeps `last_prediction` for the debug overlay; the dungeon passes the prediction into `PuzzleHost` as `context`, which is copied into the puzzle result (telemetry) and into the skill update record.
- Validation: `tools/run_tests.sh` — 147 passed, 0 failed (adds `tests/unit/test_success_predictor.gd`: monotonic in skill and in difficulty across the whole scale, bounds, symmetry, inverse round trip, calibrated difficulty, end-to-end exposure); `tools/check_boot.sh` OK.

---

### Task 3.6: Target-Success Band and Difficulty Selector

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.6): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `DifficultySelector` (`game/scripts/adaptive/difficulty_selector.gd`): picks the target from a configurable predicted-success band per room type (`adaptive_config.gd`: recovery 0.85-0.93, standard 0.70-0.80, challenge 0.55-0.68, boss 0.45-0.60). Target difficulty = the inverse prediction at the band midpoint, with the band edges giving a difficulty range, so the gap to skill follows the success model rather than a fixed offset.
- Candidates are ranked deterministically: in-band first, then by distance from the target success, then by difficulty distance, then id.
- Documented fallbacks via `reason`: `in_band`, `nearest_outside_band` (no in-band content; closest first) and `no_content`. The target difficulty is clamped to the available content range (`content_clamped`). Room types map from `RoomDef.RoomType`.
- Integration into room selection happens with the scheduler in Task 3.10.
- Validation: `tools/run_tests.sh` — 155 passed, 0 failed (adds `tests/unit/test_difficulty_selector.gd`); `tools/check_boot.sh` OK.

---

### Task 3.7: Confidence-Aware Updates and Anti-Oscillation

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.7): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Confidence-aware K (`skill_model.gd`): K falls from `k_max` 56 at zero confidence to `k_min` 14 at full confidence, and is multiplied by `0.6 + 0.4 x puzzle difficulty confidence`, so uncalibrated puzzles influence ratings less. The per-puzzle cap (30) still applies.
- Confidence rule: grows toward the 0.95 cap with outcomes that match expectation, shrinks after surprises (|observed - expected|).
- Target smoothing (`difficulty_selector.gd`): each new family target moves 60% of the way toward the raw band target, at most 80 points per room; the decision reports `raw_target_difficulty`, `smoothed` and the success the smoothed target implies.
- Regression fixtures in `tests/unit/test_anti_oscillation.gd`: lucky-answer spike and one-off failure stay bounded for confident players, newcomers move faster than veterans, uncalibrated puzzles are discounted, confidence grows/drops/caps, alternating outcomes stay in a narrow rating band, sudden skill jumps and alternating skill do not swing targets.
- Validation: `tools/run_tests.sh` — 163 passed, 0 failed; `tools/check_boot.sh` OK.

---

### Task 3.8: Failure Recovery Mode with Hysteresis

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.8): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `RecoveryMode` (`game/scripts/adaptive/recovery_mode.gd`), thresholds in `adaptive_config.gd`. Enters on 3 failures within the last 4 results, 2 consecutive results that used every hint, or 2 consecutive abandons. One failure never triggers it, and noisy ~60% success does not either.
- Hysteresis: exits only after 3 consecutive successes and at least 3 results in recovery; evidence is cleared on every transition, so old failures cannot re-trigger it right after exit.
- While active, standard/challenge rooms use the easier recovery band and boss rooms soften to the challenge band (no abrupt trivialization); `prefers_familiar()` tells the scheduler to favour known mechanics (used in Task 3.10).
- `PlayerProfile` feeds every result into it (hint count passed in the puzzle context), records `recovery_transition` and a snapshot with each update, and resets it when a run starts.
- Validation: `tools/run_tests.sh` — 170 passed, 0 failed (adds `tests/unit/test_recovery_mode.gd`); `tools/check_boot.sh` OK.

---

### Task 3.9: Cold-Start Calibration Session

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.9): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `CalibrationSession` (`game/scripts/adaptive/calibration_session.gd`): for an uncalibrated profile the first rooms of a run are warm-ups, one per family (pattern, logic, memory), using the hardest bundled puzzle at or below difficulty 350 (below the neutral prior, so they feel like warm-ups rather than an exam). Out-of-order results are ignored.
- Evidence goes through the normal skill model: zero confidence gives the largest K, still capped at 30 per puzzle, so initial ratings move quickly but boundedly. Finishing the plan sets `SkillProfile.calibrated`; later runs skip it.
- Skipping: the main menu has a "Warm-up rooms" toggle (on by default, kept across runs). Off = no warm-up, every family stays at the neutral prior.
- The dungeon asks `PlayerProfile.calibration` for the warm-up family before normal selection; outcomes are deterministic for the same results.
- Validation: `tools/run_tests.sh` — 178 passed, 0 failed (adds `tests/unit/test_calibration.gd`); `tools/check_boot.sh` OK.

---

### Task 3.10: Adaptive Scheduler Policy: Fit, Variety and Weakness Guardrails

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(3.10): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AdaptiveScheduler` (`game/scripts/adaptive/adaptive_scheduler.gd`): for each family it runs the difficulty selector (with the room's band, recovery override and smoothed previous target) and scores every candidate: fit to the target success + novelty (puzzles seen in the last 6 rooms penalised) + variety (same mechanic / same family as the last room penalised) + coverage (family not seen in the last 3 rooms) + weakness guardrail (small bonus for the weakest family, a penalty once it was drilled twice in a row) + recovery familiarity (solved mechanics) + small seeded jitter. Deterministic for a seed.
- Families now provide `mechanic_label()` (e.g. `pattern:geometric`); `PuzzleData.mechanic` is in the result identity. Fixture rooms no longer force a family, so the scheduler (or the warm-up plan) decides.
- `PlayerProfile.schedule()` drives room selection after the warm-up, keeps run history, smoothed targets and solved mechanics, and exposes `last_schedule` with components and reasons; `AdaptiveScheduler.explain()` gives a one-line summary, printed when the `mindforge/debug/adaptive_log` project setting is on.
- `docs/ADAPTIVE_DIFFICULTY.md` gains an implementation summary of all Phase 3 modules and parameters.
- Validation: `tools/run_tests.sh` — 186 passed, 0 failed (adds `tests/unit/test_adaptive_scheduler.gd`: reasons/components, no back-to-back repeats, family rotation and coverage, weak family practised but not drilled, no single puzzle dominating, recovery familiarity, requested family, determinism, dungeon integration); `tools/check_boot.sh` OK.

---

## Phase 4 — Scoring, Progression, Save & Player Feedback

### Task 4.1: Deterministic Scoring Formula

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.1): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `ScoringEngine` (`game/scripts/scoring/scoring_engine.gd`, `scoring-v1`): `points = round(100 x clamp(product of multipliers, 0.25, 3.0))`; difficulty multiplier linear 0.5..1.5 over effective difficulty (calibrated when available); speed/hint/attempt/streak multipliers are 1.0 placeholders filled in Task 4.2. Incorrect or abandoned results score 0; points are never negative.
- Independent from skill estimation: scoring reads only the puzzle result and run context, and the skill model never reads scores (tested, including a source check).
- `GameState.apply_puzzle_result()` adds points to the run score and updates the streak from every validated `puzzle_resolved` result (placeholders ignored); the HUD shows it through `run_state_changed`.
- Caps/floors documented in the engine header and `docs/GAME_DESIGN.md`.
- Validation: `tools/run_tests.sh` — 194 passed, 0 failed (adds `tests/unit/test_scoring.gd`); `tools/check_boot.sh` OK.

---

### Task 4.2: Speed, Hint, Attempt and Streak Multipliers

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.2): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Individually testable multipliers in `scoring_engine.gd`, each with explicit caps: speed 0.9..1.1 (1.1 in the faster half of the time band, 1.0 inside it, down to 0.9 at twice the band), hint 0.5..1.0 (1 - 0.5 x hint cost), attempt 1.0 / 0.75 / 0.5, streak 1.0..1.5 (+0.1 per prior correct answer, max 5).
- Speed is never dominant: its range (±10%) is smaller than the difficulty range, and a slow hard puzzle outscores a fast easy one (tested). Timing accommodations, missing time bands and unreliable times make the speed multiplier exactly 1.0.
- With the 0.25..3.0 product clamp, scores are never negative and never above 300 per puzzle, even for out-of-range inputs.
- Documented in the engine header and `docs/GAME_DESIGN.md`.
- Validation: `tools/run_tests.sh` — 199 passed, 0 failed (extends `tests/unit/test_scoring.gd`); `tools/check_boot.sh` OK.

---

### Task 4.3: XP and Profile Progression

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.3): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `Progression` (`game/scripts/scoring/progression.gd`): lifetime XP, level, best score, completed runs, puzzles solved. XP per puzzle rewards effort and completion: solved 10 + points/10 (max 40), attempted-but-unsolved 3, abandoned 0. Level n needs 100 + 50 x (n - 1) XP to advance.
- Separate from adaptive skill: progression never reads or writes ratings (tested, including a source check); the docs and code state that a level is not a measure of cognitive skill.
- `GameState` adds run XP per scored result and shows level progress on the HUD bar (`xp_progress`); `PlayerProfile.progression` holds lifetime values and records best score / completed runs at run end.
- Versioned `to_dict()` / `load_dict()` (clamped); written to disk by the save model in Task 4.6.
- Validation: `tools/run_tests.sh` — 205 passed, 0 failed (adds `tests/unit/test_progression.gd`); `tools/check_boot.sh` OK.

---

### Task 4.4: Puzzle Success / Failure Feedback

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.4): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Hook point: `EventBus.feedback_requested(kind, data)` with kinds `puzzle_success`, `puzzle_retry`, `puzzle_failure`, `hint_used`, `room_completed`. `PuzzleHost` emits the puzzle/hint kinds, the dungeon emits room completion. Audio (Task 4.8) subscribes to the same signal.
- No answer leakage: feedback data carries only outcome information (points, XP, attempts left, hint level, abandoned/final flags); a test plays a puzzle through hint, wrong answer and correct answer and checks no event contains answer keys or the answer value.
- `FeedbackBanner` (`game/scenes/ui/feedback_banner.tscn`) in the dungeon shows short messages with a symbol (✓ ↻ ✗ ? ★), plus "+points / +XP" on success.
- Settings in `PlayerProfile.settings` (`reduced_motion`, `master_volume`). With reduced motion the banner's nonessential pop-in animation is skipped.
- Validation: `tools/run_tests.sh` — 210 passed, 0 failed (adds `tests/integration/test_feedback.gd`); `tools/check_boot.sh` OK.

---

### Task 4.5: Run Summary and Skill-Change Screen

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.5): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `RunSummary.build()` (`game/scripts/scoring/run_summary.gd`): score (and "new best"), rooms cleared, puzzles solved/attempted, hints used, XP gained, level and level progress, and per family solved/attempted/hints plus a trend phrase from the rating change during the run ("Getting sharper", "Holding steady", "Met some tough ones", "Not played this run") with a run headline. Wording describes the run, never the player (tested against a banned-word list).
- `GameState` keeps a per-puzzle `run_log`, captures the skill state at run start, and builds `last_summary` at run end; the final exit now calls `GameState.complete_run()`, which shows `game/scenes/ui/run_summary.tscn` (Continue returns to the menu).
- Internal math (ratings before/after, delta, confidence, seed) is in `summary.debug` and shown only when `mindforge/debug/show_internal_math` is on or F3 is pressed in a debug build.
- Validation: `tools/run_tests.sh` — 214 passed, 0 failed (adds `tests/integration/test_run_summary.gd`); `tools/check_boot.sh` OK.

---

### Task 4.6: Versioned Atomic Save / Load, Migration and Recovery

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.6): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `SaveManager` autoload (`game/autoload/save_manager.gd`), save schema 1 in `user://profile.save`: skills, progression (Task 4.3), settings and solved mechanics via `PlayerProfile.export_state()` / `import_state()` (settings type-checked on load).
- Atomic replacement: write `.tmp` -> read back and validate -> copy current to `.bak` -> replace.
- Migration hooks (`migrations` dictionary, v0 -> v1 example for the pre-release layout), validation of structure and game id, corrupted file kept as `.corrupt` with recovery from `.bak` (then immediately re-saved), fresh profile when nothing is usable.
- Unsupported future version: never applied and never overwritten; saving is refused for the session (`read_only`).
- Autosave at run end, on window close and on settings changes outside a run; headless tools and the test runner never touch the real save file.
- Documented in `docs/SAVE_AND_TELEMETRY.md`.
- Validation: `tools/run_tests.sh` — 224 passed, 0 failed (adds `tests/unit/test_save_manager.gd`: round trip, backup, migration, corrupted with/without backup, invalid structure, future version, new profile, setting types); `tools/check_boot.sh` OK.

---

### Task 4.7: Pause, Restart and Safe Return-to-Menu Flow

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.7): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Pause menu `game/scenes/ui/pause_menu.tscn` (runs while the tree is paused): Resume, Restart run, Abandon run. Esc in the dungeon opens it (or leaves an open puzzle); Esc inside it goes back a step.
- Safe abandon: a confirmation step ("This run's score is lost. XP you already earned is kept.") with "Keep playing" focused by default; only confirming ends the run as `abandoned` and returns to the menu.
- Restart: `GameState.restart_run()` ends the attempt as `restarted` and starts again from the same seed and length, so run state and the RNG stream are identical; puzzle choices also depend on the player profile, which keeps what was learned (documented in code).
- No partial state during scene changes: `GameState` collapses scene-change requests while one is pending and unpauses first; pausing is blocked during room transitions and pending scene changes; saves stay atomic (Task 4.6).
- Validation: `tools/run_tests.sh` — 229 passed, 0 failed (adds `tests/integration/test_pause_flow.gd`); `tools/check_boot.sh` OK.

---

### Task 4.8: Basic Audio / Animation Feedback Hooks

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(4.8): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `Feedback` autoload (`game/autoload/feedback.gd`): the central hook for SFX and motion. It plays a sound for every `EventBus.feedback_requested` kind and for explicit `play()` calls (room transition, door, UI click, score tick); `pulse()` and `count_up()` are the shared animation helpers (exit door pulse on solve, HUD streak pulse, HUD score count-up).
- Placeholder audio only: every sound is a short sine/noise tone synthesized in code at startup (16-bit mono WAV), routed through an `SFX` bus; no third-party assets (README "Assets and Licensing").
- Master volume: `PlayerProfile` setting `master_volume` drives the Master bus (0 mutes). Reduced motion: `pulse()` does nothing and `count_up()` shows the final value at once.
- Main menu Settings now has a Reduced motion toggle and a Volume slider (saved via the settings autosave from Task 4.6).
- Validation: `tools/run_tests.sh` — 234 passed, 0 failed (adds `tests/integration/test_feedback_hooks.gd`; HUD/menu tests updated); `tools/check_boot.sh` OK.

---

## Phase 5 — Procedural Dungeon & Content Scheduling

### Task 5.1: Seeded Dungeon Run Generator

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.1): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `DungeonGenerator.generate(seed, length)` (`game/scripts/dungeon/dungeon_generator.gd`, `dungeon-gen-v1`): a structural run plan of 3..12 rooms (default 7) with id, name, room type, size, spawn point, puzzle anchor, door/retreat rules and floor colour. The first three rooms are standard (they host the warm-ups), later rooms mix standard and challenge, and the last room is a boss room (for runs of 5+ rooms). No retreat from boss rooms.
- Deterministic: the generator uses its own RNG seeded from `hash([version, seed])`, so the same seed and generator version always give the same plan, and the run RNG used for puzzle choices is untouched.
- Separation: the plan contains no puzzle content; puzzles are chosen by the scheduler when a room is entered. `DungeonGenerator.room_def()` builds the RoomDef for each entry.
- New runs from the menu (and restarts) now play a generated plan; `GameState.run_plan` stores it and the snapshot records `plan_version`. Without a plan (direct scene runs, tests) the three fixture rooms are used.
- Validation: `tools/run_tests.sh` — 242 passed, 0 failed (adds `tests/unit/test_dungeon_generator.gd`); `tools/check_boot.sh` OK.

---

### Task 5.2: Difficulty-Aware Room Planner

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.2): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `RoomPlanner.plan()` (`game/scripts/adaptive/room_planner.gd`) maps each planned room to a challenge profile: standard / breather (recovery) / challenge / guardian (boss), each with its target band and a `stretch` flag (challenge and boss rooms lean toward mechanics the player has not solved yet; disabled during recovery). Recovery mode overrides the band.
- Graceful degradation with recorded reasons: requested family without content -> any family (`requested_family_unavailable`); no content at all -> placeholder room (`no_content`); no puzzle inside the band -> nearest fit (`ideal_difficulty_unavailable`).
- `PlayerProfile.schedule()` runs the planner before the scheduler and stores the planner record (room id, base type, band, reasons) in `last_schedule["planner"]` for telemetry/debugging, also printed with the adaptive debug log.
- Validation: `tools/run_tests.sh` — 247 passed, 0 failed (adds `tests/unit/test_room_planner.gd`); `tools/check_boot.sh` OK.

---

### Task 5.3: Puzzle-Family Rotation and Anti-Repetition

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.3): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `VarietyTracker` (`game/scripts/adaptive/variety_tracker.gd`) tracks recent families, mechanics and fingerprints from the run history and applies cooldown penalties: puzzle seen in the last 6 rooms (-1.0), mechanic seen in the last 2 rooms (-0.25 each), same family as the last room (-0.2, and again for two in a row). The scheduler now takes its novelty/variety components from it, with the reasons in each decision.
- Respects recovery: while recovering, the mechanic cooldown is waived (familiar mechanics are welcome) and the fingerprint cooldown shrinks to 2 rooms, so the just-failed puzzle is still not repeated immediately.
- Penalties are soft only, so variety rules can never make selection impossible; tests run a single-puzzle pool and a single-family pool for many rooms and always get a puzzle.
- Validation: `tools/run_tests.sh` — 252 passed, 0 failed (adds `tests/unit/test_variety.gd`); `tools/check_boot.sh` OK.

---

### Task 5.4: Local Procedural Pattern Generator

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.4): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `PatternGenerator` (`game/scripts/puzzles/generators/pattern_generator.gd`, `pattern-gen-v1`): picks structured rule parameters from a seed and a requested difficulty using feature tiers (easy: small arithmetic steps, 3-symbol cycles; medium: larger/negative steps, alternating steps, doubling, 3-4 symbol cycles; hard: x2/x3 geometric, mixed-sign alternating, recurrence, 4-symbol cycles; expert: recurrence with larger seeds, 5-symbol cycles, shorter sequences).
- Solver-first: the visible sequence and the answer are produced term by term by the deterministic pattern solver; the generator adds plausible distractors and rule-based hints (first hint generic), records `source: procedural`, seed and generator provenance, and validates the result with `PuzzleData.parse()`. Invalid output is rejected and another sub-seed is tried (up to 6).
- `ContentPool.extend()` (`game/scripts/puzzles/content_pool.gd`) generates 7 puzzles per family with a generator around the player's family rating (offsets -200..+200) into the run's catalog, through the normal catalog checks (schema, validator, duplicate fingerprints). Generated runs from the menu use it; fixture runs do not.
- Validation: `tools/run_tests.sh` — 258 passed, 0 failed (adds `tests/unit/test_pattern_generator.gd`: 160 seed/difficulty combinations all valid, solver-derived answers present exactly once, determinism, tier features, no first-hint leaks, pool near player level and deterministic); `tools/check_boot.sh` OK.

---

### Task 5.5: Local Procedural Logic Generator

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.5): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `LogicGenerator` (`game/scripts/puzzles/generators/logic_generator.gd`, `logic-gen-v1`): from a seed it picks items and a hidden arrangement, adds randomly chosen clues that are true for it until the deterministic solver reports exactly one solution, then prunes clues that are not needed (harder tiers down to a minimal set where every clue is required; easy puzzles keep extras, all fit the 10-clue limit).
- Difficulty through constraint structure, not wording: easy 3 items with direct slot clues, medium 4 items (max 2 slot clues), hard 5 items (max 1), expert 5-6 items with only relational and exclusion clues. Clue text is still generated from structure by the renderer.
- Satisfiability and uniqueness are verified by the solver before returning, then the puzzle is validated by `PuzzleData.parse()`; failures retry with another sub-seed (up to 8). Hints: two general hints and one that reveals a single slot (never the whole arrangement).
- `ContentPool` now also generates logic puzzles for generated runs.
- Validation: `tools/run_tests.sh` — 262 passed, 0 failed (adds `tests/unit/test_logic_generator.gd`: 100 seed/difficulty combinations unique and valid, tier structure, every pruned clue required, determinism, no first-hint leak); `tools/check_boot.sh` OK.

---

### Task 5.6: Local Procedural Memory Generator

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.6): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `MemoryGenerator` (`game/scripts/puzzles/generators/memory_generator.gd`, `memory-gen-v1`): deterministic targets from a seed with difficulty-controlled features: grid size (3x3 up to 5x4), length (3 up to 8), mode, and interference (easy paths step to neighbouring cells so they chunk well; harder paths scatter across the grid; expert uses a `length - 1` recall threshold).
- Presentation timing is a separate optional input (tier defaults for show/gap/conceal); it never changes the generated target, and the fingerprint excludes it. Accessibility scaling is still applied only by the renderer, so a 3x schedule shows exactly the same cells.
- Output is validated by `PuzzleData.parse()` (retries on failure); `ContentPool` now generates memory puzzles too, so generated runs have procedural content for all three families.
- Validation: `tools/run_tests.sh` — 267 passed, 0 failed (adds `tests/unit/test_memory_generator.gd`); `tools/check_boot.sh` OK.

---

### Task 5.7: Puzzle Solvability, Ambiguity and Content Quality Pipeline

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.7): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `ContentPipeline.validate()` (`game/scripts/puzzles/content_pipeline.gd`, `content-pipeline-v1`): one pipeline for local, procedural and AI content with ordered stages `schema` (shared fields via `PuzzleSchema.validate_common`), `bounds` (prompt size), `solver` (canonical solution derivable), `family` (family validator), `ambiguity` (new `ambiguity()` hook per family: one matching choice / exactly one logic solution / distinct memory cells), `fingerprint` (stored mismatch, duplicate id, duplicate mechanics), `safety` (plain short text, no control characters, markup, links or blocked words) and `hint_leak`.
- Structured rejections `{stage, code, message}` plus the failing stage; a logic puzzle with several solutions is classified as `ambiguity`, not `unsolvable`.
- `PuzzleCatalog.add_entry()` now goes through the pipeline, so bundled files, generated content (`ContentPool`) and the bank validation tool all share it; rejected entries keep their structured reasons.
- Documented in `docs/PUZZLE_SPEC.md`.
- Validation: `tools/run_tests.sh` — 272 passed, 0 failed (adds `tests/unit/test_content_pipeline.gd`: acceptance for every source, a rejection at each stage, duplicates, text rules, catalog reasons); `tools/validate_puzzles.sh` 18 valid; `tools/check_boot.sh` OK.

---

### Task 5.8: Boss-Room Template and Multi-Skill Challenge

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(5.8): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `BossTrial` (`game/scripts/dungeon/boss_trial.gd`, `boss-v1`): deterministic templates per run seed and room (Twin Seals: pattern + logic, Echo Lock: memory + pattern, Mind Gate: logic + memory). Each stage is a normal puzzle of its own family, presented by the host and checked/rated by that family's validator only; validators are never mixed. The room is solved only when every stage is solved in order ("Seal broken!" feedback between stages, stage title in the puzzle window).
- Intentionally harder but bounded: stages are scheduled within their family at the boss band (predicted success 0.45-0.60) with the usual caps and smoothing; in recovery the boss softens to the challenge band.
- Failure and retry: a failed stage ends the attempt, the trial restarts from stage 1 and re-plans its stages on the next interaction (so recovery can soften them). To keep the adaptive profile clean, a puzzle already rated in the current run is not rated again (`rated_fingerprints`, recorded as `repeat_attempt`); boss failures still count toward recovery mode.
- Validation: `tools/run_tests.sh` — 277 passed, 0 failed (adds `tests/integration/test_boss_room.gd`: two-skill templates, ordered stages, failure/retry/re-plan, no double rating, recovery softening); `tools/check_boot.sh` OK.

---

## Phase 6 — AI Puzzle Generation & Safe Content Pipeline

### Task 6.1: AI Puzzle JSON Contract and Prompt Versioning

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.1): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiContract` (`game/scripts/ai/ai_contract.gd`): strict structured contract for AI pattern and logic proposals. Proposals carry structured parameters only (pattern: rule, params, shown; logic: items, clues), plus optional `declared_answer` (cross-checked, never trusted), `difficulty_estimate` (provisional), up to 3 hints, explanation and flavor text.
- Parser policy: responses over 6000 bytes, non-object JSON, unknown top-level fields, unknown pattern params or clue fields, unsupported rules/clue types/families, wrong types, more than 10 clues, and text over 160 characters are rejected with readable errors.
- Versioning: `versions(model)` reports model, `ai-prompt-v1`, `ai-schema-v1`, content pipeline version and new solver versions (`pattern-solver-v1`, `logic-solver-v1`, `memory-validator-v1`) for caching and invalidation.
- `build_request()` (family, difficulty band, allowed mechanics/symbols, bounds, tone; no personal data or telemetry), `prompt_text()` (versioned instructions, solver-first), and `output_schema()` (JSON schema with `additionalProperties: false`) for the proxy.
- Validation: `tools/run_tests.sh` — 282 passed, 0 failed (adds `tests/unit/test_ai_contract.gd`); `tools/check_boot.sh` OK.

---

### Task 6.2: Optional Secret-Safe AI Proxy Skeleton

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.2): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Optional proxy in `backend/` (Python standard library HTTP server, `python -m backend.app.server`): `GET /health`, `POST /v1/puzzle`. Bound to `127.0.0.1` by default, request bodies limited to 16 KB, provider output to 6 KB, provider timeout 20 s (configurable), typed error codes (`timeout`, `rate_limited`, `refused`, `invalid_request`, ...).
- Provider abstraction (`backend/app/providers/`): `MockProvider` (offline, deterministic structured proposals; used when no key is set and in tests) and `AnthropicProvider` (official Anthropic Python SDK, default model `claude-opus-5-5`, JSON-schema structured output with the game's schema, server-side refusal fallbacks, refusal reported as an error).
- Secret safety: keys only from environment variables (`.env.example` documents them; `.env` is git-ignored); `/health` and logs never include the key; the client never receives it. The proxy never interprets model output; the game validates it.
- Core gameplay runs with the proxy absent (nothing in the game depends on it yet; the adapter in Task 6.3 treats it as optional). `backend/.gdignore` keeps it out of Godot imports.
- Pre-commit runs the proxy tests when Python is available. `backend/README.md` documents setup and safety.
- Validation: `python -m unittest discover -s backend/tests -t .` — 7 passed (config/key exposure, default model, mock determinism, bounds and validation, typed provider errors, oversized output, HTTP round trip); `tools/run_tests.sh` — 282 passed; `tools/check_boot.sh` OK.

---

### Task 6.3: Godot AI Content Adapter

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.3): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiContent` autoload (`game/autoload/ai_content.gd`): builds the versioned request (contract + prompt + output schema), sends it to the proxy (`mindforge/ai/proxy_url`, default `http://127.0.0.1:8787`) with a bounded timeout (`mindforge/ai/timeout_seconds`, default 8 s), and returns a typed result `{ok, status, proposal, model, request_id, error}` with status `ok | disabled | busy | timeout | network_error | http_error | invalid_response | rejected`. Nothing raises into gameplay.
- Off by default (`mindforge/ai/enabled = false`); at most 2 requests in flight. No provider-specific logic: the proxy's provider is invisible to the game, and replies are parsed with the strict `AiContract` before anyone sees them.
- The adapter never references GameState, PlayerProfile, SaveManager, score or skills (tested by source check). The HTTP transport is injectable so tests use a fake.
- Validation: `tools/run_tests.sh` — 287 passed, 0 failed (adds `tests/unit/test_ai_adapter.gd`: disabled default, success path, every error status, busy limit, no score/skill/save access); proxy tests 7 passed; `tools/check_boot.sh` OK.

---

### Task 6.4: Solver-First AI Pattern Puzzle Generation

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.4): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiPuzzleBuilder` (`game/scripts/ai/ai_puzzle_builder.gd`) turns a parsed AI proposal into a puzzle solver-first. For pattern proposals the AI provides only rule + parameters + visible length; the deterministic pattern solver derives every visible term and the canonical answer, distractors and local hints are built by the game (shared helpers from `PatternGenerator`), and the result is a normal puzzle (`source: ai`) for the content pipeline.
- A `declared_answer` that differs from the solver rejects the proposal (`declared_answer_conflict`); invalid parameters, unknown rules or extra params are rejected. The AI's difficulty estimate is kept only as provenance; the target difficulty comes from the request (plausibility checks in Task 6.8).
- Provenance records model, request id, prompt/schema/pipeline/solver versions. Building is deterministic for the same proposal and request id.
- Validation: `tools/run_tests.sh` — 291 passed, 0 failed (adds `tests/unit/test_ai_pattern_builder.gd`, including a full content-pipeline pass); `tools/check_boot.sh` OK.

---

### Task 6.5: Solver-First AI Logic Puzzle Generation

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.5): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- AI logic proposals (items + bounded clues of the supported types) are built solver-first in `AiPuzzleBuilder.build_logic()`: structure is checked first (known symbols, unique items, supported clue types, in-range positions, at most 10 clues), then the exhaustive logic solver computes the canonical arrangement locally. Unsatisfiable (`unsatisfiable`) or multi-solution (`not_unique`) clue sets are rejected, as is a `declared_answer` that differs from the solver. Unknown mechanics are rejected; nothing from a proposal is executed.
- Hints for AI logic puzzles come from the local hint ladder (one slot revealed at most).
- `tools/ai_smoke_test.gd`: end-to-end check against a running proxy (request -> strict parse -> solver-first build -> content pipeline). Verified with the mock provider over real HTTP: one pattern and one logic proposal accepted. Headless tools never touch the real save file.
- Validation: `tools/run_tests.sh` — 296 passed, 0 failed (adds `tests/unit/test_ai_logic_builder.gd`); `tools/ai_smoke_test.gd` OK against `python -m backend.app.server`; proxy tests 7 passed; `tools/check_boot.sh` OK.

---

### Task 6.6: Grounded AI Hint and Explanation Generation

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.6): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiHints.ground()` (`game/scripts/ai/ai_hints.gd`): AI-written hints are used only when grounded in the already-validated puzzle (structure + canonical solution): exactly 3 hints, each through the AI text gate, no duplicates, only the strongest (third) hint may reveal the answer, and every number or symbol name a hint mentions must exist in the puzzle (visible terms, parameters, items, slots or solution), so a hint cannot describe a different puzzle. The game assigns the light-to-strong costs (0.1 / 0.25 / 0.5).
- Fallback: on any failure the deterministic local hint ladder is kept; provenance records `hint_source` and `hint_fallback_reason`.
- Explanations stay sanitized presentation text (Task 6.7).
- Validation: `tools/run_tests.sh` — 305 passed, 0 failed (adds `tests/unit/test_ai_hints.gd`); `tools/ai_smoke_test.gd` OK against the mock proxy; `tools/check_boot.sh` OK.

---

### Task 6.7: AI Text Sanitization and Content Safety Gate

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.7): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiTextSanitizer` (`game/scripts/ai/ai_text_sanitizer.gd`, `ai-text-v1`): strips control/zero-width characters and markup (`[bbcode]`, `<html>`), collapses whitespace, then rejects (never silently rewrites) text that is empty, over the display limit (160), contains links/bare domains or e-mail addresses, shouts, uses repeated `!!`/`??`, or falls outside the tone policy (violence, sexual content, hate, self-harm, and words that label the player such as "stupid" or "weak"; whole-word matching).
- Never raw output in the UI: `AiPuzzleBuilder` keeps only sanitized flavor/explanation text in `presentation` and records why anything was dropped in provenance; the puzzle host shows flavor text only from that sanitized field.
- One standard for every source: the content pipeline's `safety` stage now uses the same gate (`ContentPipeline.text_problem`) and also checks presentation text. All bundled puzzles still pass.
- Validation: `tools/run_tests.sh` — 301 passed, 0 failed (adds `tests/unit/test_ai_text_sanitizer.gd`); `tools/validate_puzzles.sh` 18 valid; `tools/check_boot.sh` OK.

---

### Task 6.8: AI Puzzle Validation, Difficulty Plausibility and Quarantine

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.8): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiIntake.intake()` (`game/scripts/ai/ai_intake.gd`) is the only path from an AI reply to playable content: solver-first build -> deterministic difficulty -> full content pipeline (schema, bounds, solver, family, ambiguity, fingerprint/duplicates, safety, hint leak). Anything that fails is quarantined; nothing is activated silently.
- Difficulty plausibility: `feature_difficulty()` estimates difficulty from deterministic complexity features (pattern rule, step/ratio size, cycle length, visible length; logic item count and relational vs direct clues), checked against the bundled puzzles (within 300 points of authored difficulty). The puzzle's target difficulty comes from these features with zero confidence; the AI estimate is kept as provenance, and a gap over 250 is flagged. Content whose features are more than 350 from the requested difficulty is quarantined as `off_target`.
- Quarantine entries are structured: request id, model, family, stage, code (`declared_answer_conflict`, `not_unique`, `off_target`, `duplicate`, ...), messages, proposal fingerprint and all versions (newest 200 kept).
- Validation: `tools/run_tests.sh` — 310 passed, 0 failed (adds `tests/unit/test_ai_intake.gd`); `tools/check_boot.sh` OK.

---

### Task 6.9: Generated-Content Fingerprint, Deduplication and Variety Gate

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.9): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Generated content (procedural or AI) is admitted with `PuzzleCatalog.admit_generated()`, which runs the content pipeline: the puzzle is fingerprinted (SHA-256 of family mechanics) before it can be cached or scheduled, and exact duplicates of bundled or earlier generated content are rejected at the `fingerprint` stage.
- Near repeats: each family now provides `near_signature()` (pattern: rule + step/ratio/cycle shape regardless of start or length; logic: item count + clue-type mix; memory: mode + grid + length), stored as `PuzzleData.near_signature` and in the run history. `VarietyTracker` penalises a near repeat seen in the last 3 rooms (-0.3 each, relaxed in recovery) on top of the existing mechanic/family cooldowns.
- Traceability: provenance keeps model, request id, prompt/schema/pipeline/solver versions; `PuzzleCatalog.invalidate(filter)` removes every puzzle whose provenance matches (e.g. a model or prompt version) and releases its fingerprints.
- Validation: `tools/run_tests.sh` — 313 passed, 0 failed (adds `tests/unit/test_generated_content_gate.gd`); fingerprint snapshot unchanged; `tools/check_boot.sh` OK.

---

### Task 6.10: Validated AI Puzzle Cache and Version Invalidation

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.10): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiCache` (`game/scripts/ai/ai_cache.gd`, `user://ai_cache.json`, cache version 1): stores only AI puzzles that pass the content pipeline, keyed by fingerprint, each with model, prompt/schema/pipeline/solver versions and a timestamp; newest 200 kept; atomic save (temp file, then replace).
- Version invalidation: on load, entries created under different prompt/schema/pipeline/solver versions are revalidated with the current pipeline; those that no longer pass are dropped, the rest get refreshed versions (a different model alone does not invalidate). Corrupt cache files are ignored. `load_into(catalog)` re-admits entries through the pipeline.
- No secrets or telemetry: entries keep puzzle content and provenance only (whitelisted fields); a test checks the file for key names and player data.
- Validation: `tools/run_tests.sh` — 318 passed, 0 failed (adds `tests/unit/test_ai_cache.gd`); `tools/check_boot.sh` OK.

---

### Task 6.11: Async Pre-Generation, Timeout and Offline Fallback

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(6.11): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AiContent.start_pregeneration(catalog, targets)` runs in the background (deferred coroutine, never awaited by gameplay). Generated runs ask for pattern and logic puzzles at the player's rating ±60; accepted puzzles go through `AiIntake` (solver-first, features, pipeline, quarantine) into the run catalog and the validated cache. Cached AI puzzles are loaded at run start.
- Latency never blocks rooms: room selection always uses whatever the catalog holds; until AI content arrives, bundled and procedural puzzles generated around the player's level (Task 5.4-5.6) keep the target difficulty close.
- Bounded timeouts and retries: each target gets at most 2 attempts (one retry after timeout/network error), each with the adapter's timeout; batches report requested/accepted/quarantined/failed counts via `pregeneration_finished`.
- Stale requests: `cancel_pregeneration()` (called when the dungeon leaves the tree) cancels HTTP requests and marks running batches stale; their results are discarded.
- `docs/AI_CONTENT_POLICY.md` gains an implementation map of Phase 6.
- Validation: `tools/run_tests.sh` — 323 passed, 0 failed (adds `tests/integration/test_ai_pregeneration.gd`: a puzzle opens instantly while slow AI requests run, accepted content reaches catalog and cache, bounded retries, stale results discarded, nothing happens when AI is off); `tools/ai_smoke_test.gd` OK; `tools/check_boot.sh` OK.

---

## Phase 7 — Telemetry, Simulation & Difficulty Calibration

### Task 7.1: Local Telemetry Event Schema with Adaptive Provenance

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(7.1): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `TelemetryEvent` (`game/scripts/telemetry/telemetry_event.gd`, event schema version 1): one `puzzle_completed` / `puzzle_abandoned` event per finished puzzle with puzzle id, content and schema version, source, family, mechanic, fingerprint, target/calibrated difficulty, difficulty confidence, outcome, response time, timing-accommodation flag, hints, attempts, predicted success, skill and confidence before/after, a `rating_skipped` marker, recovery state, score/XP awarded, and the adaptive, scoring and content-pipeline versions.
- Privacy: the only identifier is a random 64-bit per-app-session id; no names, e-mail, location or device ids (tested).
- `validate()` checks every field's presence and type (JSON floats accepted for whole numbers), rejects unknown fields and unsupported schema versions, so analysis and calibration can skip malformed events.
- Documented in `docs/SAVE_AND_TELEMETRY.md`.
- Validation: `tools/run_tests.sh` — 327 passed, 0 failed (adds `tests/unit/test_telemetry_event.gd`); `tools/check_boot.sh` OK.

---

### Task 7.2: Puzzle Performance Recorder

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(7.2): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `Telemetry` autoload (`game/autoload/telemetry.gd`): after the score and skill update for a result exist, builds the event (Task 7.1) with session id, run seed, room id, room band, recovery state and versions, and appends one JSON line to `user://telemetry/events.jsonl` (append-only; local only; `mindforge/telemetry/enabled`, on by default).
- Safe failures: malformed events and failed writes are counted (`write_failures`) and never interrupt gameplay. Headless tools and tests never write the player's telemetry file.
- Analysis helpers: `read_back(path)` returns every well-formed event in order and skips (counts) malformed lines; `export_events(events, path)` writes a deterministic export (sorted keys, stable order), so the same events always produce the same bytes.
- Validation: `tools/run_tests.sh` — 331 passed, 0 failed (adds `tests/integration/test_telemetry_recorder.gd`: real gameplay results appended with skill provenance and retry markers, failed writes, malformed lines, deterministic export); `tools/check_boot.sh` OK.

---

### Task 7.3: Developer Skill / Difficulty Debug Overlay

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(7.3): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- Debug overlay `game/scenes/ui/debug_overlay.tscn` in the dungeon: overall and per-family skill with confidence and observations, last predicted success and puzzle difficulty, room base type -> target band, target success and target difficulty with the selector reason, the picked puzzle with its scheduler score and top reasons, planner reasons, and recovery state.
- Disabled in normal play: shown only when `mindforge/debug/overlay` is on (off by default) or toggled with F9 in debug builds (README controls updated).
- Read-only: it only reads PlayerProfile and never calls state-changing methods (tested by profile comparison and a source check); signal connections use bound methods so they end with the node.
- Test hygiene: `tools/run_tests.sh` now also fails on ObjectDB leak warnings (a pending timer in a test was the last one).
- Validation: `tools/run_tests.sh` — 334 passed, 0 failed (adds `tests/integration/test_debug_overlay.gd`); `tools/check_boot.sh` OK.

---

### Task 7.4: Batch Simulated-Player Harness

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(7.4): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `LatentPlayer` (`game/scripts/simulation/latent_player.gd`, `sim-player-v1`): simulated players with known per-family ability for the six archetypes (strong, average, struggling, improving, inconsistent, family specialist). Its behaviour model is independent of the algorithm under test: normal-CDF success curve (spread 170) instead of the game's logistic model, per-puzzle noise, hint use when puzzles feel hard, retries with decaying odds, occasional abandonment; it never sees ratings or predictions (source check).
- `SimulationHarness.run(archetype, seed, rooms, schedule)` (`simulation_harness.gd`, `sim-harness-v1`) plays rooms with the real adaptive stack (a private PlayerProfile instance: warm-up, planner, scheduler, selector, skill model, recovery) over a fixed candidate pool (bundled + procedural puzzles across the difficulty range). Deterministic per (archetype, seed); exports per-room rows and a comparable summary (success/hint/abandon rates, per-family final estimate vs latent ability, error over the last 5 rooms). `schedule = "static"` provides a fixed ramp for Task 7.8. The real player profile is never touched.
- `tools/simulate_players.gd`: all archetypes x seeds, prints a table and writes `user://simulation/summary.json`.
- First finding (input for Task 7.5): with the current parameters estimates move too slowly (after 36 rooms a strong player is still estimated around 540 against a latent 800, a struggling one around 465 against 250), largely because a success after several attempts still counts as a near-full success.
- Validation: `tools/run_tests.sh` — 339 passed, 0 failed (adds `tests/unit/test_simulation_harness.gd`); `tools/simulate_players.gd` runs all 18 simulations in about 3 s; `tools/check_boot.sh` OK.

---

### Task 7.5: Adaptive Convergence, Oscillation and Recovery Metrics

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(7.5): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `AdaptiveMetrics.compute(rows)` (`game/scripts/simulation/adaptive_metrics.gd`, `adaptive-metrics-v1`), per family and overall: band occupancy (predicted success inside the standard band), true fit (latent success 0.55-0.90), convergence room, final error, oscillation (mean target change), sign flips, overshoot over the 75%-success difficulty, recovery time.
- Regression thresholds (`tests/unit/test_adaptive_metrics.gd`, 45 rooms, seeds 1-2): strong players reach >= 650 in every family, struggling stay <= 480, average within 500 ± 150, specialist pattern at least 150 above logic, improving players followed within 150, oscillation <= 40, sign flips <= 0.7, standard-band occupancy >= 0.5, recovery episodes <= 8 rooms.
- The thresholds caught a real failure in v1 (strong players stuck near 540), so the adaptive parameters were re-balanced to `adaptive-v2` (`adaptive_config.gd`): K 90 -> 14, per-puzzle cap 45, confidence gain 0.05, puzzle trust floor 0.85, correct floor 0.45, extra attempts -0.3 each (max 0.55), hint penalty 0.6 x cost (max 0.35). The repeat-attempt rule now only skips re-rating a puzzle seen within the last two results (immediate retries), not a later reappearance. Unit tests that pinned v1 numbers now read the config values; docs (`ADAPTIVE_DIFFICULTY.md`, `ADAPTIVE_EVALUATION.md`, README) updated.
- After tuning (seeds 1-2): strong ~730/800, average ~500-610, struggling ~330-410 vs latent ~250 (retries and hints inflate success; the sim defines latent ability as unassisted first-try ability), specialist pattern ~700 vs logic ~430, oscillation ~17-30 points.
- Validation: `tools/run_tests.sh` — 347 passed, 0 failed; `tools/check_boot.sh` OK.

---

### Task 7.6: Empirical Puzzle Difficulty Calibration with Confidence

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(7.6): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
- `DifficultyCalibrator` (`game/scripts/telemetry/difficulty_calibrator.gd`, `calibration-v1`): groups usable telemetry events by puzzle fingerprint and, once a puzzle has at least `min_samples` (20) events, estimates its calibrated difficulty by maximum likelihood under the game's success model given each player's skill before the attempt (grid search, then 1-point refinement). Confidence = n / (n + 40), capped at 0.95; entries record sample count, calibration and adaptive algorithm versions.
- Never learns from malformed telemetry: events failing schema validation, without skill_before, marked as skipped repeat attempts, or without a fingerprint are ignored and counted.
- Never overwrites authored difficulty: `apply()` only sets `calibrated_difficulty` and `difficulty_confidence`; selection then prefers the calibrated value (`effective_difficulty()`), and the higher confidence also gives the puzzle more weight in skill updates.
- `tools/calibrate_difficulty.gd` builds `user://calibration.json` from the local telemetry log; the dungeon applies it when loading puzzles. Event file reading/export moved into `telemetry_event.gd` so tools do not depend on autoload scripts.
- Validation: `tools/run_tests.sh` — 352 passed, 0 failed (adds `tests/unit/test_difficulty_calibrator.gd`: recovers a true difficulty of 620 within 50 from 400 synthetic events, sample threshold and low confidence near it, unusable events skipped, authored target unchanged, save/load); `tools/calibrate_difficulty.gd` runs; `tools/check_boot.sh` OK.

---

### Task 7.7: Puzzle Completion, Hint and Abandonment Analytics

**Status:** `[x]` Completed

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
- [x] Task-specific implementation exists.
- [x] Relevant automated/headless validation passes.
- [x] No new runtime errors in the affected playable flow.
- [x] Documentation and task status are synchronized.
- [x] A dedicated `task(7.7): ...` Git commit exists.
- [x] The commit is pushed to GitHub and upstream verification succeeds when `origin` is configured.
- [x] Scope does not spill into the next task.

**Implementation Notes**
Summaries of success, hints, attempts, completion time and abandonment per family and puzzle, with accommodated timing as a separate cohort; tools/telemetry_report.gd.

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
