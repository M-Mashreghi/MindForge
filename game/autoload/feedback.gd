extends Node
## Central audio/animation feedback hooks.
##
## Sounds: every EventBus.feedback_requested kind (and `play()` calls for
## transitions, doors and UI) maps to a short placeholder tone that is
## generated in code at startup, so no third-party audio is shipped.
## Volume follows the player's `master_volume` setting on the Master bus.
## Animations: `pulse()` and `count_up()` are the only motion helpers; with
## the `reduced_motion` setting they skip the motion and apply the final
## state immediately.

const SAMPLE_RATE := 22050
const SFX_BUS := &"SFX"

## kind -> list of [frequency Hz, duration s] notes played back to back
## (frequency 0 = short noise burst).
const SOUND_SPECS := {
	&"puzzle_success": [[660.0, 0.08], [990.0, 0.14]],
	&"puzzle_retry": [[440.0, 0.1]],
	&"puzzle_failure": [[300.0, 0.12], [220.0, 0.2]],
	&"hint_used": [[880.0, 0.06]],
	&"room_completed": [[523.0, 0.08], [659.0, 0.08], [784.0, 0.18]],
	&"boss_stage_cleared": [[392.0, 0.08], [587.0, 0.16]],
	&"room_transition": [[0.0, 0.18]],
	&"door_open": [[196.0, 0.1], [294.0, 0.12]],
	&"ui_click": [[1200.0, 0.03]],
	&"score_tick": [[1500.0, 0.025]],
}

var sounds: Dictionary = {}
var last_played: StringName = &""
## Headless runs (tests, tools) only record what would play: there is no
## audio output and playbacks would outlive the process.
var output_enabled: bool = true
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	output_enabled = DisplayServer.get_name() != "headless"
	_ensure_bus()
	for kind in SOUND_SPECS:
		sounds[kind] = _synthesize(SOUND_SPECS[kind])
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)
	EventBus.feedback_requested.connect(func(kind, _data): play(kind))
	EventBus.profile_changed.connect(func(_id): apply_volume())
	apply_volume()


## Stop playback before the tree goes away so no playback outlives its player.
func _exit_tree() -> void:
	for player in _players:
		player.stop()
		player.stream = null
	sounds.clear()


## Plays the placeholder sound for `kind`. Returns false for unknown kinds.
func play(kind: StringName) -> bool:
	if not sounds.has(kind):
		return false
	last_played = kind
	if not output_enabled:
		return true
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = sounds[kind]
	player.play()
	return true


## Applies the master volume setting (0..1) to the Master bus; 0 mutes.
func apply_volume() -> void:
	var volume := clampf(float(PlayerProfile.setting("master_volume")), 0.0, 1.0)
	AudioServer.set_bus_mute(0, volume <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))


func motion_enabled() -> bool:
	return not PlayerProfile.reduced_motion()


## Small scale pulse on `node` (a Control or Node2D). Returns the tween, or
## null when reduced motion is on (nothing moves).
func pulse(node: CanvasItem, strength: float = 0.12) -> Tween:
	if not motion_enabled() or node == null:
		return null
	if node is Control:
		(node as Control).pivot_offset = (node as Control).size / 2.0
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * (1.0 + strength), 0.08)
	tween.tween_property(node, "scale", Vector2.ONE, 0.12)
	return tween


## Counts a label's number from `from` to `to` using `fmt` (e.g. "%d").
## With reduced motion the final value is shown at once.
func count_up(label: Label, from: int, to: int, fmt: String = "%d", seconds: float = 0.4) -> Tween:
	if label == null:
		return null
	if not motion_enabled() or from == to:
		label.text = fmt % to
		return null
	var tween := label.create_tween()
	tween.tween_method(func(v: float): label.text = fmt % roundi(v), float(from), float(to), seconds)
	return tween


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, SFX_BUS)
	AudioServer.set_bus_send(index, &"Master")


## Generates a 16-bit mono WAV from note specs: sine tones (or a noise
## burst for frequency 0) with a short fade in/out to avoid clicks.
static func _synthesize(notes: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	var noise := RandomNumberGenerator.new()
	noise.seed = 1
	for note in notes:
		var freq: float = note[0]
		var count := int(SAMPLE_RATE * float(note[1]))
		for i in count:
			var t := float(i) / SAMPLE_RATE
			var env := minf(1.0, minf(i / (SAMPLE_RATE * 0.005), (count - i) / (SAMPLE_RATE * 0.02)))
			var v := (noise.randf_range(-1.0, 1.0) * 0.5) if freq <= 0.0 else sin(TAU * freq * t)
			var sample := int(clampf(v * env * 0.35, -1.0, 1.0) * 32767.0)
			data.append(sample & 0xFF)
			data.append((sample >> 8) & 0xFF)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav
