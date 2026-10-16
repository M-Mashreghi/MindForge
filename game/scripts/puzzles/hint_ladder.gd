extends RefCounted
## Ordered hints for one puzzle attempt, from light to strong. Each level's
## cost is charged once: asking again after the last hint, or re-reading an
## earlier one, never adds cost. Scoring (Phase 4) reads `total_cost`.

var hints: Array = []
## Number of distinct levels revealed so far.
var levels_used: int = 0
var total_cost: float = 0.0


func _init(puzzle_hints: Array = []) -> void:
	hints = puzzle_hints


func has_more() -> bool:
	return levels_used < hints.size()


## Reveals the next level: {"level": 1-based, "text", "cost"}; {} when none
## are left (no cost is charged in that case).
func next_hint() -> Dictionary:
	if not has_more():
		return {}
	var hint: Dictionary = hints[levels_used]
	levels_used += 1
	total_cost += float(hint["cost"])
	return {"level": levels_used, "text": hint["text"], "cost": float(hint["cost"])}


## Already revealed hints, for redisplay (free).
func revealed() -> Array:
	var out: Array = []
	for i in levels_used:
		out.append({"level": i + 1, "text": hints[i]["text"], "cost": float(hints[i]["cost"])})
	return out


func remaining() -> int:
	return hints.size() - levels_used


## True when `text` mentions any answer token as a whole word/number.
static func leaks_answer(text: String, answer_tokens: PackedStringArray) -> bool:
	var lowered := text.to_lower()
	for token in answer_tokens:
		var t := token.strip_edges().to_lower()
		if t.is_empty():
			continue
		var regex := RegEx.create_from_string("(^|[^a-z0-9])" + _escape(t) + "($|[^a-z0-9])")
		if regex.search(lowered) != null:
			return true
	return false


static func _escape(text: String) -> String:
	var out := ""
	for ch in text:
		out += ("\\" + ch) if ch in ".^$*+?()[]{}|\\-" else ch
	return out
