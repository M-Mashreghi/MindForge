extends "res://tests/test_case.gd"

const Palette := preload("res://game/scripts/ui/palette.gd")
const UiTheme := preload("res://game/scripts/ui/ui_theme.gd")
const RoomDef := preload("res://game/scripts/dungeon/room_def.gd")


func test_text_pairs_meet_wcag_aa_contrast() -> void:
	for pair_name in Palette.TEXT_PAIRS:
		var pair: Array = Palette.TEXT_PAIRS[pair_name]
		var ratio := Palette.contrast_ratio(pair[0], pair[1])
		check(ratio >= 4.5, "%s contrast %.2f >= 4.5" % [pair_name, ratio])


func test_contrast_ratio_reference_values() -> void:
	check(is_equal_approx(Palette.contrast_ratio(Color.WHITE, Color.BLACK), 21.0), "white on black is 21:1")
	check(is_equal_approx(Palette.contrast_ratio(Color.GRAY, Color.GRAY), 1.0), "same color is 1:1")


func test_every_room_type_has_a_distinct_marker_shape() -> void:
	var markers := {}
	for room_type in RoomDef.RoomType.values():
		markers[Palette.marker(room_type)] = true
	check_eq(markers.size(), RoomDef.RoomType.size(), "one marker shape per room type (not color only)")


func test_theme_is_applied_to_the_root_window() -> void:
	var theme: Theme = tree.root.theme
	check(theme != null, "root window has the shared theme")
	if theme:
		check(theme.has_stylebox("focus", "Button"), "buttons have a focus ring")
		var focus := theme.get_stylebox("focus", "Button") as StyleBoxFlat
		check(focus != null and focus.border_width_left >= UiTheme.FOCUS_WIDTH, "focus ring is thick enough to see")
		check_eq(theme.get_color("font_color", "Label"), Palette.TEXT, "labels use palette text")


func test_no_bundled_binary_art_or_audio() -> void:
	# All art is drawn in code and all sound is synthesized (docs/ASSETS.md);
	# any shipped media file must be added to the asset register first.
	var found := PackedStringArray()
	_scan("res://game", found)
	check(found.is_empty(), "unregistered media files: %s" % ", ".join(found))


func _scan(path: String, found: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp", "svg", "wav", "ogg", "mp3", "ttf", "otf", "woff", "woff2"]:
			found.append(path.path_join(file))
	for dir in DirAccess.get_directories_at(path):
		_scan(path.path_join(dir), found)
