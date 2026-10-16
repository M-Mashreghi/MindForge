extends RefCounted
## Test-only puzzle family: prompt {"value": n}, answer is 2n.
## Used to prove generic code works without knowing a real family.


func solve(prompt: Dictionary) -> Variant:
	if typeof(prompt.get("value")) != TYPE_INT:
		return null
	return {"answer": prompt["value"] * 2}


func validate(puzzle: Dictionary) -> PackedStringArray:
	var solved: Variant = solve(puzzle["prompt"])
	if solved == null:
		return PackedStringArray(["doubling: prompt.value must be an integer"])
	if puzzle["solution"].get("answer") != solved["answer"]:
		return PackedStringArray(["doubling: stored solution differs from solver"])
	return PackedStringArray()


func check_response(puzzle: Dictionary, response: Dictionary) -> Dictionary:
	return {"correct": response.get("answer") == solve(puzzle["prompt"])["answer"]}


func mechanics(puzzle: Dictionary) -> Dictionary:
	return {"value": puzzle["prompt"]["value"]}


func answer_tokens(puzzle: Dictionary) -> PackedStringArray:
	return PackedStringArray([str(solve(puzzle["prompt"])["answer"])])
