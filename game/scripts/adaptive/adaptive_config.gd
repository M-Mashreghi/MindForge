extends RefCounted
## Tunable parameters for the adaptive system. Every value is a plain
## number so tests and balance experiments can override them; the defaults
## are design hypotheses to calibrate from telemetry.

const ALGORITHM_VERSION := "adaptive-v1"

## Rating scale (docs/ADAPTIVE_DIFFICULTY.md section 2).
var skill_min: float = 0.0
var skill_max: float = 1000.0
var skill_prior: float = 500.0
var confidence_max: float = 0.95
