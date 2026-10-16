extends Control
## Main menu: New Run, Settings (placeholder) and Exit.
## Keyboard/controller focus starts on New Run from the first frame.

@onready var _menu: VBoxContainer = %Menu
@onready var _new_run_button: Button = %NewRunButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton
@onready var _settings_panel: Control = %SettingsPanel
@onready var _settings_back_button: Button = %SettingsBackButton
@onready var _warmup_toggle: CheckButton = %WarmupToggle
@onready var _reduced_motion_toggle: CheckButton = %ReducedMotionToggle
@onready var _volume_slider: HSlider = %VolumeSlider

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
