extends Node
## Godot side of the optional AI content path. Sends structured requests
## to the local proxy (backend/) and returns typed results; it never raises
## gameplay errors and never touches score, skill or save data. Gameplay
## code only ever sees validated puzzles that came out of the content
## pipeline, never raw provider output.
##
## Result: {"ok": bool, "status": String, "proposal": Dictionary,
##          "model": String, "request_id": String, "error": String}
## status: ok | disabled | busy | timeout | network_error | http_error |
##         invalid_response | rejected

const AiContract := preload("res://game/scripts/ai/ai_contract.gd")

const ENABLED_SETTING := "mindforge/ai/enabled"
const URL_SETTING := "mindforge/ai/proxy_url"
const TIMEOUT_SETTING := "mindforge/ai/timeout_seconds"
const MAX_IN_FLIGHT := 2

## Off by default: the game is complete without AI.
var enabled: bool = false
var proxy_url: String = "http://127.0.0.1:8787"
var timeout_seconds: float = 8.0
## Callable(url: String, body: String, timeout: float) -> {"code": int, "body": String, "error": String}.
## Awaited; tests replace it with a fake transport.
var transport: Callable
var in_flight: int = 0
var _counter: int = 0


func _ready() -> void:
	enabled = bool(ProjectSettings.get_setting(ENABLED_SETTING, false))
	proxy_url = str(ProjectSettings.get_setting(URL_SETTING, proxy_url))
	timeout_seconds = float(ProjectSettings.get_setting(TIMEOUT_SETTING, timeout_seconds))
	transport = _http_transport


## Asks the proxy for one proposal. Always returns a typed result.
func request_proposal(family: StringName, target_difficulty: float) -> Dictionary:
	_counter += 1
	var request_id := "req-%d-%d" % [Time.get_ticks_msec(), _counter]
	var out := {"ok": false, "status": "", "proposal": {}, "model": "", "request_id": request_id, "error": ""}
	if not enabled:
		out["status"] = "disabled"
		return out
	if not family in AiContract.FAMILIES:
		out["status"] = "rejected"
		out["error"] = "family not offered to AI"
		return out
	if in_flight >= MAX_IN_FLIGHT:
		out["status"] = "busy"
		return out
	var request := AiContract.build_request(family, target_difficulty, request_id)
	request["prompt"] = AiContract.prompt_text(request)
	request["output_schema"] = AiContract.output_schema(family)
	in_flight += 1
	var response: Dictionary = await transport.call(proxy_url.path_join("v1/puzzle"), JSON.stringify(request), timeout_seconds)
	in_flight -= 1
	return interpret(response, out)


## Turns a transport response into a typed result (pure; tested directly).
static func interpret(response: Dictionary, out: Dictionary) -> Dictionary:
	var error: String = str(response.get("error", ""))
	if error == "timeout":
		out["status"] = "timeout"
		return out
	if error != "":
		out["status"] = "network_error"
		out["error"] = error
		return out
	var json := JSON.new()
	if json.parse(str(response.get("body", ""))) != OK or typeof(json.data) != TYPE_DICTIONARY:
		out["status"] = "invalid_response"
		out["error"] = "proxy reply is not JSON"
		return out
	var reply: Dictionary = json.data
	if int(response.get("code", 0)) != 200 or not reply.get("ok", false):
		out["status"] = "http_error"
		out["error"] = str(reply.get("error", "http %d" % int(response.get("code", 0))))
		return out
	var parsed := AiContract.parse(str(reply.get("text", "")))
	if not parsed["ok"]:
		out["status"] = "rejected"
		out["error"] = "; ".join(parsed["errors"])
		return out
	out["ok"] = true
	out["status"] = "ok"
	out["proposal"] = parsed["proposal"]
	out["model"] = str(reply.get("model", ""))
	return out


func _http_transport(url: String, body: String, timeout: float) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = timeout
	add_child(http)
	var err := http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		return {"code": 0, "body": "", "error": "request_failed"}
	var done: Array = await http.request_completed
	http.queue_free()
	var result: int = done[0]
	if result == HTTPRequest.RESULT_TIMEOUT:
		return {"code": 0, "body": "", "error": "timeout"}
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"code": 0, "body": "", "error": "connection_failed"}
	return {"code": done[1], "body": (done[3] as PackedByteArray).get_string_from_utf8(), "error": ""}
