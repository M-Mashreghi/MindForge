# MindForge Asset Register

Every visual, sound and font the game uses, with its source and license.
Add a row here **before** committing any new media file; the test
`tests/unit/test_visual_theme.gd` fails when an image, audio or font file
appears under `game/` (all current assets are generated in code).

## Visual language

A torch-lit stone dungeon with violet "mind rune" accents. All colors come
from `game/scripts/ui/palette.gd`; the interface theme is built from it in
`game/scripts/ui/ui_theme.gd` and applied to the root window at startup.

- Readability: every text/background pair in `Palette.TEXT_PAIRS` meets
  WCAG AA (4.5:1), checked by tests.
- Not color only: locked doors show a padlock and bars, open doors an
  archway, solved doors an arrow; room types have different pedestal marker
  shapes (circle standard, leaf recovery, triangle challenge, crown boss);
  the player's facing is shown by the face position and an arrow; puzzle
  symbols are distinct shapes, memory cells show a star, not only a glow.
- Focus: a thick brass focus ring on every control for keyboard and
  controller users.

## Register

| Asset | Where | Source | License |
|---|---|---|---|
| Dungeon floor, walls, torches, pedestal | `game/scenes/rooms/dungeon_room.gd` (`_draw`) | Original, drawn in code | Project license |
| Doors (locked / open / solved) | `game/scenes/rooms/door.gd` | Original, drawn in code | Project license |
| Player figure | `game/scenes/dungeon/player.gd` | Original, drawn in code | Project license |
| Puzzle symbols (circle, triangle, square, star, ...) | `game/scenes/puzzles/symbol_glyph.gd` | Original, drawn in code | Project license |
| Interface theme and puzzle cell styles | `game/scripts/ui/ui_theme.gd`, `game/scenes/puzzles/puzzle_styles.gd` | Original, `StyleBoxFlat` from the palette | Project license |
| Sound effects | `game/autoload/feedback.gd` | Original, synthesized tones at startup | Project license |
| Interface font | Godot engine default (no font file shipped) | Open Sans SemiBold bundled with Godot 4.5 | SIL OFL 1.1 (see Godot's `COPYRIGHT.txt`) |
| README screenshots | `docs/images/*.png` | Captured from the game with `tools/capture_screenshots.gd` | Project license |

`game/assets/art`, `game/assets/audio` and `game/assets/fonts` are empty
and reserved for future licensed media.
