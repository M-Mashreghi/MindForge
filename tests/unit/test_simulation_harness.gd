extends "res://tests/test_case.gd"

const Harness := preload("res://game/scripts/simulation/simulation_harness.gd")
const LatentPlayer := preload("res://game/scripts/simulation/latent_player.gd")


func test_all_archetypes_exist() -> void:
	for a in ["strong", "average", "struggling", "improving", "inconsistent", "specialist"]:
		check(LatentPlayer.ARCHETYPES.has(a), "archetype %s" % a)


func test_latent_model_is_independent_of_the_adaptive_algorithm() -> void:
	var source: String = (load("res://game/scripts/simulation/latent_player.gd") as GDScript).source_code
	for word in ["adaptive", "Elo", "SkillProfile", "PlayerProfile", "predict", "scheduler"]:
		var code := "\n".join(Array(source.split("\n")).filter(func(l): return not l.strip_edges().begins_with("##")))
		check(not code.contains(word), "latent player code does not use %s" % word)
	check(is_equal_approx(LatentPlayer.normal_cdf(0.0), 0.5), "cdf(0) = 0.5")
	check(LatentPlayer.normal_cdf(1.0) > 0.84 and LatentPlayer.normal_cdf(1.0) < 0.842, "cdf(1)")


func test_runs_are_deterministic_and_comparable() -> void:
	var a: Dictionary = Harness.run("average", 7, 18)
	var b: Dictionary = Harness.run("average", 7, 18)
	check_eq(a["summary"], b["summary"], "same archetype and seed, same summary")
	check_eq(a["rows"].map(func(r): return r["puzzle_id"]), b["rows"].map(func(r): return r["puzzle_id"]), "same puzzles")
	for key in ["harness_version", "player_model", "archetype", "seed", "schedule", "rooms", "success_rate", "hint_rate", "abandon_rate", "families"]:
		check(a["summary"].has(key), "summary has %s" % key)


func test_estimates_order_strong_above_struggling() -> void:
	# Direction only; convergence thresholds live in the metrics tests (Task 7.5).
	var strong: Dictionary = Harness.run("strong", 3, 30)["summary"]
	var weak: Dictionary = Harness.run("struggling", 3, 30)["summary"]
	for f in ["pattern", "logic", "memory"]:
		check(strong["families"][f]["final_estimate"] > weak["families"][f]["final_estimate"],
			"%s: strong %s vs struggling %s" % [f, strong["families"][f]["final_estimate"], weak["families"][f]["final_estimate"]])


func test_simulation_does_not_touch_the_real_profile() -> void:
	var profile: Node = tree.root.get_node("PlayerProfile")
	var before: Dictionary = profile.export_state()
	Harness.run("improving", 1, 12)
	check_eq(profile.export_state(), before, "real profile unchanged")
