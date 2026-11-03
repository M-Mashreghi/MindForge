extends RefCounted
## Tiny timing helpers for the performance baseline (tools/profile_performance.gd)
## and the frame-budget tests. Wall-clock microseconds, reported in ms.


## Start a span: returns the current tick in microseconds.
static func now_usec() -> int:
	return Time.get_ticks_usec()


static func elapsed_ms(start_usec: int) -> float:
	return float(Time.get_ticks_usec() - start_usec) / 1000.0


## {"count", "median_ms", "p95_ms", "max_ms"} for a list of samples in ms.
static func summarize(samples: Array) -> Dictionary:
	if samples.is_empty():
		return {"count": 0, "median_ms": 0.0, "p95_ms": 0.0, "max_ms": 0.0}
	var sorted := samples.duplicate()
	sorted.sort()
	var n := sorted.size()
	return {
		"count": n,
		"median_ms": snappedf(float(sorted[n / 2]), 0.01),
		"p95_ms": snappedf(float(sorted[mini(n - 1, ceili(n * 0.95) - 1)]), 0.01),
		"max_ms": snappedf(float(sorted[n - 1]), 0.01),
	}
