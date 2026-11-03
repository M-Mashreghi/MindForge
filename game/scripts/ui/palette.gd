extends RefCounted
## The MindForge visual language: a torch-lit stone dungeon with violet
## "mind rune" accents. Every color the game draws comes from here so the
## look stays coherent, and the text pairs below are checked for WCAG
## contrast by tests. State is never shown by color alone: doors, room types
## and the player's facing each also have a distinct shape.
## All art is drawn in code from these values; no image files are shipped.

# Stone and floor.
const VOID := Color(0.04, 0.035, 0.06)
const STONE := Color(0.27, 0.25, 0.31)
const STONE_LIGHT := Color(0.38, 0.35, 0.43)
const STONE_DARK := Color(0.16, 0.15, 0.19)
const MORTAR := Color(0.11, 0.1, 0.13)
const FLOOR_LINE := Color(0, 0, 0, 0.28)

# Light and accents.
const TORCH := Color(1.0, 0.68, 0.3)
const TORCH_GLOW := Color(1.0, 0.6, 0.25, 0.10)
const RUNE := Color(0.66, 0.56, 0.98)
const RUNE_DIM := Color(0.42, 0.36, 0.66)
const WOOD := Color(0.42, 0.29, 0.18)
const WOOD_DARK := Color(0.2, 0.13, 0.08)
const IRON := Color(0.62, 0.6, 0.66)
const BRASS := Color(0.88, 0.76, 0.48)
const SUCCESS := Color(0.5, 0.92, 0.58)
const WARNING := Color(0.98, 0.82, 0.38)
const DANGER := Color(0.98, 0.5, 0.48)

# Player.
const PLAYER_CLOAK := Color(0.32, 0.62, 0.86)
const PLAYER_HOOD := Color(0.18, 0.36, 0.55)
const PLAYER_FACE := Color(0.96, 0.86, 0.72)

# Interface.
const PANEL := Color(0.08, 0.07, 0.12, 0.96)
const PANEL_SOFT := Color(0.13, 0.12, 0.19)
const PANEL_HOVER := Color(0.19, 0.17, 0.28)
const PANEL_BORDER := Color(0.47, 0.42, 0.66)
const FOCUS := Color(0.98, 0.9, 0.62)
const TEXT := Color(0.95, 0.93, 0.98)
const TEXT_MUTED := Color(0.76, 0.73, 0.86)
const TEXT_DISABLED := Color(0.55, 0.53, 0.62)

## Floor tints by room type (index = RoomDef.RoomType): standard, recovery,
## challenge, boss. Each type also has its own pedestal marker shape.
const FLOOR_BY_TYPE := [
	Color(0.17, 0.16, 0.21),
	Color(0.14, 0.19, 0.17),
	Color(0.2, 0.16, 0.14),
	Color(0.2, 0.13, 0.17),
]
## Pedestal marker per room type: circle (standard), leaf (recovery),
## triangle (challenge), crown (boss).
const MARKER_BY_TYPE := ["circle", "leaf", "triangle", "crown"]

## Text/background pairs that must stay readable (WCAG AA, 4.5:1).
const TEXT_PAIRS := {
	"text_on_panel": [TEXT, PANEL],
	"muted_on_panel": [TEXT_MUTED, PANEL],
	"text_on_button": [TEXT, PANEL_SOFT],
	"text_on_hover": [TEXT, PANEL_HOVER],
	"success_on_panel": [SUCCESS, PANEL],
	"warning_on_panel": [WARNING, PANEL],
	"danger_on_panel": [DANGER, PANEL],
	"focus_on_panel": [FOCUS, PANEL],
}


static func floor_color(room_type: int) -> Color:
	return FLOOR_BY_TYPE[clampi(room_type, 0, FLOOR_BY_TYPE.size() - 1)]


static func marker(room_type: int) -> String:
	return MARKER_BY_TYPE[clampi(room_type, 0, MARKER_BY_TYPE.size() - 1)]


## WCAG relative-luminance contrast ratio between two opaque colors.
static func contrast_ratio(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(c: Color) -> float:
	var channels := [c.r, c.g, c.b]
	for i in 3:
		var v: float = channels[i]
		channels[i] = v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
