extends RefCounted
## Shared placeholder styles for puzzle cells/slots, so empty cells stay
## visible against the dark host panel.

const CELL_BG := Color(0.2, 0.19, 0.28)
const CELL_BG_HOVER := Color(0.26, 0.24, 0.36)
const CELL_BORDER := Color(0.45, 0.42, 0.6)
const CELL_FOCUS := Color(0.95, 0.9, 1.0)


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
