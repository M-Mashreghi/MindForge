extends RefCounted
## Builds the shared interface Theme from the palette: stone-panel buttons
## with a bright brass focus ring (visible for keyboard/controller users),
## dark rune-bordered panels and palette text colors. Applied to the root
## window at startup, so every scene inherits it; scenes only override
## sizes and layout.

const Palette := preload("res://game/scripts/ui/palette.gd")

const FOCUS_WIDTH := 3
const RADIUS := 6


static func build() -> Theme:
	var theme := Theme.new()
	for type in ["Button", "OptionButton", "CheckButton", "CheckBox"]:
		theme.set_color("font_color", type, Palette.TEXT)
		theme.set_color("font_hover_color", type, Palette.TEXT)
		theme.set_color("font_pressed_color", type, Palette.TEXT)
		theme.set_color("font_focus_color", type, Palette.TEXT)
		theme.set_color("font_hover_pressed_color", type, Palette.TEXT)
		theme.set_color("font_disabled_color", type, Palette.TEXT_DISABLED)
		theme.set_stylebox("focus", type, box(Color(0, 0, 0, 0), Palette.FOCUS, FOCUS_WIDTH))
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, box(Palette.PANEL_SOFT, Palette.PANEL_BORDER.darkened(0.25), 1))
		theme.set_stylebox("hover", type, box(Palette.PANEL_HOVER, Palette.PANEL_BORDER, 1))
		theme.set_stylebox("pressed", type, box(Palette.PANEL_HOVER, Palette.RUNE, 2))
		theme.set_stylebox("disabled", type, box(Palette.PANEL_SOFT.darkened(0.3), Palette.STONE_DARK, 1))
	for type in ["CheckButton", "CheckBox"]:
		var flat := box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0)
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			theme.set_stylebox(state, type, flat)
	theme.set_color("font_color", "Label", Palette.TEXT)
	theme.set_stylebox("panel", "PanelContainer", box(Palette.PANEL, Palette.PANEL_BORDER, 2, 18))
	theme.set_stylebox("panel", "PopupMenu", box(Palette.PANEL, Palette.PANEL_BORDER, 1, 6))
	theme.set_stylebox("hover", "PopupMenu", box(Palette.PANEL_HOVER, Palette.FOCUS, 1))
	theme.set_color("font_color", "PopupMenu", Palette.TEXT)
	theme.set_color("font_hover_color", "PopupMenu", Palette.TEXT)
	theme.set_stylebox("slider", "HSlider", box(Palette.STONE_DARK, Palette.PANEL_BORDER, 1, 0, 4))
	theme.set_stylebox("grabber_area", "HSlider", box(Palette.RUNE_DIM, Color(0, 0, 0, 0), 0, 0, 4))
	theme.set_stylebox("grabber_area_highlight", "HSlider", box(Palette.RUNE, Color(0, 0, 0, 0), 0, 0, 4))
	theme.set_stylebox("focus", "HSlider", box(Color(0, 0, 0, 0), Palette.FOCUS, FOCUS_WIDTH))
	return theme


static func box(bg: Color, border: Color, width: int, margin: int = 10, height: int = -1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(RADIUS)
	style.set_content_margin_all(margin)
	if height >= 0:
		style.content_margin_top = height
		style.content_margin_bottom = height
	return style
