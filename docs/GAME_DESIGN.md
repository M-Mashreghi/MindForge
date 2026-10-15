# MindForge Game Design Document

## 1. Fantasy

The player explores a mysterious dungeon called the MindForge. Each chamber tests a different cognitive skill. The dungeon observes how the player performs and reshapes future challenges around that player.

## 2. Player Promise

> “The dungeon is always near the edge of my ability.”

The player should rarely feel that the game is trivially easy or impossibly hard.

## 3. Core Loop

1. Enter a room.
2. Observe the puzzle.
3. Interact / answer.
4. Receive immediate feedback.
5. Gain score / XP / reward.
6. Adaptive system updates skill.
7. Next room receives a target family and difficulty.

## 4. Puzzle Families

### Pattern
Examples:
- number/symbol sequences,
- alternating rules,
- matrix-like missing element,
- multi-rule sequences at high difficulty.

### Logic
Examples:
- switches and doors,
- ordering constraints,
- truth/lie rules,
- small deduction grids.

### Memory
Examples:
- rune sequence playback,
- tile positions,
- paired-object recall,
- delayed recall after a distraction.

## 5. Progression

### Run progression
- room number,
- temporary score,
- streak,
- current health/focus if enabled,
- temporary buffs.

### Profile progression
- overall skill,
- family skills,
- lifetime XP,
- best score,
- unlocked cosmetics / themes,
- achievement flags.

## 6. Scoring

Reference formula:

```text
score = base
      × difficulty_multiplier
      × speed_multiplier
      × streak_multiplier
      × hint_multiplier
      × attempt_multiplier
```

Multipliers must be capped and deterministic.

The system should reward harder correct answers without making speed the dominant factor.

## 7. Failure

A failed puzzle should not immediately end a run.

Possible response:
- reduce score opportunity,
- provide stronger hint,
- offer a recovery room,
- lower target difficulty gradually.

## 8. Boss Rooms

Post-MVP boss rooms combine two puzzle skills and should use deterministic templates before AI generation is allowed.

## 9. Accessibility

Plan for:
- no color-only information,
- readable font sizing,
- adjustable timers,
- reduced-motion option,
- keyboard navigation where possible.

## 10. Adaptive Experience Design

The dungeon should adapt invisibly enough that the player experiences a coherent world rather than a visible difficulty algorithm.

Use room type to contextualize difficulty:
- recovery rooms,
- standard rooms,
- challenge rooms,
- boss rooms.

Do not label the player as "weak" or "strong".

## 11. Difficulty Is Not Only Numerical Complexity

Puzzle difficulty may depend on:
- number of rules,
- number of distractors,
- working-memory load,
- depth of deduction,
- amount of information,
- hint availability,
- time pressure.

Prefer changing cognitive/mechanical complexity before relying only on shorter timers.

## 12. Variety Guardrail

Adaptive selection must not endlessly repeat the same family simply because it fits the numeric target best.

The scheduler balances:
- difficulty fit,
- novelty,
- recent history,
- family coverage,
- recovery needs.

## 13. AI Is Optional

The core game must already be fun using local and procedural content.

AI should increase content variety, not rescue a weak base game.
