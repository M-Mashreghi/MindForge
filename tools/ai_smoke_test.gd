extends SceneTree
## End-to-end check of the optional AI path against a running proxy:
##   python -m backend.app.server            (terminal 1; mock provider without a key)
##   godot --headless --path . -s res://tools/ai_smoke_test.gd   (terminal 2)
## Requests one pattern and one logic proposal, builds them solver-first
## and runs them through the content pipeline. Exit code 1 on failure.

const AiPuzzleBuilder := preload("res://game/scripts/ai/ai_puzzle_builder.gd")
const ContentPipeline := preload("res://game/scripts/puzzles/content_pipeline.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var ai: Node = root.get_node("AiContent")
	ai.enabled = true
	var builder := AiPuzzleBuilder.new()
	var failed := false
	for family in [&"pattern", &"logic"]:
		var reply: Dictionary = await ai.request_proposal(family, 500.0)
		if not reply["ok"]:
			printerr("FAIL %s: %s %s" % [family, reply["status"], reply["error"]])
			failed = true
			continue
		var built: Dictionary = builder.build(reply["proposal"], {"model": reply["model"],
			"request_id": reply["request_id"], "target_difficulty": 500.0})
		if not built["ok"]:
			printerr("FAIL %s build: %s" % [family, "; ".join(built["errors"])])
			failed = true
			continue
		var checked := ContentPipeline.validate(built["raw"])
		if not checked["accepted"]:
			printerr("FAIL %s pipeline: %s" % [family, "; ".join(ContentPipeline.messages(checked))])
			failed = true
			continue
		print("ok %s: %s from %s" % [family, checked["puzzle"].id, reply["model"]])
	print("ai smoke test: %s" % ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
