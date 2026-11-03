extends Control
## Main menu: New Run, Settings and Exit.
## Keyboard/controller focus starts on New Run from the first frame; every
## setting is reachable with ui_up/ui_down and ui_cancel closes Settings.

const Accessibility := preload("res://game/scripts/settings/accessibility.gd")

@onready var _menu: VBoxContainer = %Menu
@onready var _new_run_button: Button = %NewRunButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton
@onready var _settings_panel: Control = %SettingsPanel
@onready var _settings_back_button: Button = %SettingsBackButton
@onready var _warmup_toggle: CheckButton = %WarmupToggle
@onready var _reduced_motion_toggle: CheckButton = %ReducedMotionToggle
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _relaxed_timing_toggle: CheckButton = %RelaxedTimingToggle
@onready var _memory_timing_option: OptionButton = %MemoryTimingOption
@onready var _ui_scale_option: OptionButton = %UiScaleOption

var _starting := false


func _ready() -> void:
	_new_run_button.pressed.connect(_on_new_run_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_settings_back_button.pressed.connect(_on_settings_back_pressed)
	_settings_panel.visible = false
	_warmup_toggle.button_pressed = GameState.warmup_enabled
	_reduced_motion_toggle.button_pressed = PlayerProfile.reduced_motion()
	_volume_slider.value = float(PlayerProfile.setting("master_volume"))
	_reduced_motion_toggle.toggled.connect(func(on): PlayerProfile.set_setting("reduced_motion", on))
	_volume_slider.value_changed.connect(_on_volume_changed)
	_relaxed_timing_toggle.button_pressed = bool(PlayerProfile.setting("relaxed_timing"))
	_relaxed_timing_toggle.toggled.connect(func(on): PlayerProfile.set_setting("relaxed_timing", on))
	_fill_option(_memory_timing_option, Accessibility.TIMING_SCALES, "memory_timing_scale", "%sx time", "Normal")
	_fill_option(_ui_scale_option, Accessibility.UI_SCALES, "ui_scale", "%d%%", "")
	_new_run_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _settings_panel.visible and event.is_action_pressed("ui_cancel"):
		_on_settings_back_pressed()
		get_viewport().set_input_as_handled()


func _on_new_run_pressed() -> void:
	# Guard against repeated presses while the scene change is pending.
	if _starting:
		return
	_starting = true
	_new_run_button.disabled = true
	GameState.begin_new_run(GameState.make_run_seed(), _warmup_toggle.button_pressed)


## Fills `option` with `values` and keeps the `key` setting in sync.
## `label_format` gets the value (or the percentage when it uses %d);
## `default_label` names the 1.0 entry when not empty.
func _fill_option(option: OptionButton, values: Array, key: String, label_format: String, default_label: String) -> void:
	option.clear()
	var current := float(PlayerProfile.setting(key))
	for i in values.size():
		var value := float(values[i])
		var label := default_label if default_label != "" and is_equal_approx(value, 1.0) else 			(label_format % roundi(value * 100.0) if "%d" in label_format else label_format % str(value))
		option.add_item(label, i)
		if is_equal_approx(value, current):
			option.select(i)
	option.item_selected.connect(func(index): PlayerProfile.set_setting(key, float(values[index])))


func _on_volume_changed(value: float) -> void:
	PlayerProfile.set_setting("master_volume", value)
	Feedback.play(&"ui_click")


func _on_settings_pressed() -> void:
	_menu.visible = false
	_settings_panel.visible = true
	_reduced_motion_toggle.grab_focus()


func _on_settings_back_pressed() -> void:
	_settings_panel.visible = false
	_menu.visible = true
	_settings_button.grab_focus()


func _on_exit_pressed() -> void:
	get_tree().quit()
