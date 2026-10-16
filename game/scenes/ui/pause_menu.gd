extends CanvasLayer
## Pause menu: Resume, Restart run (same seed) and Abandon run with a
## confirmation step. Runs while the tree is paused.

signal resumed

@onready var _root: Control = %PauseRoot
@onready var _menu: Control = %PauseMenuBox
@onready var _confirm: Control = %ConfirmBox
@onready var _resume: Button = %ResumeButton
@onready var _restart: Button = %RestartButton
@onready var _abandon: Button = %AbandonButton
@onready var _confirm_yes: Button = %ConfirmYesButton
@onready var _confirm_no: Button = %ConfirmNoButton

var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_resume.pressed.connect(close)
	_restart.pressed.connect(_on_restart)
	_abandon.pressed.connect(_show_confirm)
	_confirm_yes.pressed.connect(_on_abandon_confirmed)
	_confirm_no.pressed.connect(_hide_confirm)


func open() -> void:
	if is_open or GameState.is_changing_scene():
		return
	is_open = true
	_root.visible = true
	_hide_confirm()
	get_tree().paused = true


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	resumed.emit()


func confirming() -> bool:
	return _confirm.visible


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if confirming():
			_hide_confirm()
		else:
			close()


func _show_confirm() -> void:
	_menu.visible = false
	_confirm.visible = true
	_confirm_no.grab_focus()


func _hide_confirm() -> void:
	_confirm.visible = false
	_menu.visible = true
	_resume.grab_focus()


func _on_restart() -> void:
	_disable_all()
	GameState.restart_run()


func _on_abandon_confirmed() -> void:
	_disable_all()
	GameState.return_to_main_menu()


func _disable_all() -> void:
	for button in [_resume, _restart, _abandon, _confirm_yes, _confirm_no]:
		button.disabled = true
