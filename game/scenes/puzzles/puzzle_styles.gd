extends RefCounted
## Shared styles for puzzle cells/slots (from the palette), so empty cells
## stay visible against the dark host panel and focus is always obvious.

const Palette := preload("res://game/scripts/ui/palette.gd")
const CELL_BG := Palette.PANEL_SOFT
const CELL_BG_HOVER := Palette.PANEL_HOVER
const CELL_BORDER := Palette.PANEL_BORDER
const CELL_FOCUS := Palette.FOCUS


static func apply_cell_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(CELL_BG, CELL_BORDER, 1))
	button.add_theme_stylebox_override("hover", _box(CELL_BG_HOVER, CELL_BORDER, 1))
	button.add_theme_stylebox_override("pressed", _box(CELL_BG_HOVER, CELL_FOCUS, 2))
	button.add_theme_stylebox_override("disabled", _box(CELL_BG.darkened(0.25), CELL_BORDER.darkened(0.4), 1))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), CELL_FOCUS, 3))


static func _box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(6)
	return box
