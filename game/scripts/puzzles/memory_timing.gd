extends RefCounted
## Builds the show/conceal schedule for a memory puzzle. Timing comes only
## from `presentation` and the accessibility `timing_scale`; the canonical
## target cells are untouched, so timing never changes puzzle identity.

const DEFAULT_SHOW_MS := 700
const DEFAULT_GAP_MS := 250
const DEFAULT_CONCEAL_MS := 600
const MIN_SCALE := 0.5
const MAX_SCALE := 4.0


## Returns [{"state": "show"|"gap"|"conceal", "cell": int (-1 = none), "ms": int}].
## Sequence mode lights cells one at a time; positions mode lights them together.
static func build_schedule(mode: String, target: Array, presentation: Dictionary, timing_scale: float = 1.0) -> Array:
	var scale := clampf(timing_scale, MIN_SCALE, MAX_SCALE)
	var show_ms := roundi(float(presentation.get("show_ms", DEFAULT_SHOW_MS)) * scale)
	var gap_ms := roundi(float(presentation.get("gap_ms", DEFAULT_GAP_MS)) * scale)
	var conceal_ms := roundi(float(presentation.get("conceal_ms", DEFAULT_CONCEAL_MS)) * scale)
	var steps: Array = []
	if mode == "positions":
		steps.append({"state": "show", "cells": target.duplicate(), "ms": show_ms * maxi(1, target.size() / 2)})
	else:
		for i in target.size():
			steps.append({"state": "show", "cells": [target[i]], "ms": show_ms})
			if i < target.size() - 1:
				steps.append({"state": "gap", "cells": [], "ms": gap_ms})
	steps.append({"state": "conceal", "cells": [], "ms": conceal_ms})
	return steps


static func total_ms(schedule: Array) -> int:
	var total := 0
	for step in schedule:
		total += int(step["ms"])
	return total
