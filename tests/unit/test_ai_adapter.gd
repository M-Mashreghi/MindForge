extends "res://tests/test_case.gd"

var ai: Node
var _saved_transport: Callable


func before_each() -> void:
	ai = tree.root.get_node("AiContent")
	_saved_transport = ai.transport
	ai.enabled = true


func after_each() -> void:
	ai.transport = _saved_transport
	ai.enabled = false
	ai.in_flight = 0


func _reply(code: int, payload: Dictionary) -> Callable:
	return func(_url, _body, _timeout):
		await tree.process_frame
		return {"code": code, "body": JSON.stringify(payload), "error": ""}


const GOOD := {"family": "pattern", "rule": "arithmetic", "params": {"start": 1, "step": 3}, "shown": 4}


func test_disabled_by_default_and_when_off() -> void:
	check(not bool(ProjectSettings.get_setting("mindforge/ai/enabled", true)), "AI disabled in project settings")
	ai.enabled = false
	var r: Dictionary = await ai.request_proposal(&"pattern", 500.0)
	check_eq(r["status"], "disabled", "disabled status, no request made")


func test_success_returns_parsed_proposal() -> void:
	var sent := []
	ai.transport = func(url, body, timeout):
		sent.append([url, JSON.parse_string(body), timeout])
		await tree.process_frame
		return {"code": 200, "body": JSON.stringify({"ok": true, "text": JSON.stringify(GOOD), "model": "m1"}), "error": ""}
	var r: Dictionary = await ai.request_proposal(&"pattern", 480.0)
	check(r["ok"], "ok")
	check_eq(r["proposal"]["rule"], "arithmetic", "proposal parsed")
	check_eq(r["model"], "m1", "model recorded")
	check(sent[0][0].ends_with("/v1/puzzle"), "endpoint")
	check(sent[0][1].has("prompt") and sent[0][1].has("output_schema"), "prompt and schema sent")


func test_typed_errors_never_raise() -> void:
	ai.transport = func(_u, _b, _t):
		await tree.process_frame
		return {"code": 0, "body": "", "error": "timeout"}
	check_eq((await ai.request_proposal(&"logic", 500.0))["status"], "timeout", "timeout")
	ai.transport = func(_u, _b, _t):
		await tree.process_frame
		return {"code": 0, "body": "", "error": "connection_failed"}
	check_eq((await ai.request_proposal(&"logic", 500.0))["status"], "network_error", "proxy absent")
	ai.transport = _reply(502, {"ok": false, "error": "refused"})
	var http_err: Dictionary = await ai.request_proposal(&"logic", 500.0)
	check_eq([http_err["status"], http_err["error"]], ["http_error", "refused"], "provider error passed on")
	ai.transport = func(_u, _b, _t):
		await tree.process_frame
		return {"code": 200, "body": "<html>", "error": ""}
	check_eq((await ai.request_proposal(&"logic", 500.0))["status"], "invalid_response", "non-JSON reply")
	ai.transport = _reply(200, {"ok": true, "text": "{\"family\": \"pattern\", \"rule\": \"primes\"}"})
	check_eq((await ai.request_proposal(&"pattern", 500.0))["status"], "rejected", "contract violation")
	check_eq((await ai.request_proposal(&"memory", 500.0))["status"], "rejected", "family not offered")


func test_concurrency_limit() -> void:
	ai.in_flight = ai.MAX_IN_FLIGHT
	check_eq((await ai.request_proposal(&"pattern", 500.0))["status"], "busy", "busy when saturated")


func test_adapter_never_touches_score_skill_or_save() -> void:
	var source: String = (load("res://game/autoload/ai_content.gd") as GDScript).source_code
	for word in ["GameState", "PlayerProfile", "SaveManager", "score", "skills", "save_profile"]:
		var code_lines := Array(source.split("\n")).filter(func(l): return not l.strip_edges().begins_with("##"))
		check(not "\n".join(code_lines).contains(word), "adapter code does not reference %s" % word)
