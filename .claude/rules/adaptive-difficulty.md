# Adaptive Difficulty Rules

Maintain:
- overall skill,
- family skills,
- observation counts,
- confidence/uncertainty.

Inputs may include:
- correctness,
- normalized response time,
- hint count,
- attempt count,
- current puzzle difficulty,
- recent performance.

Rules:
- correctness dominates,
- timing is bounded and accessibility-aware,
- ratings are bounded,
- updates are gradual,
- low-confidence calibration may move faster,
- high-confidence ratings move more slowly,
- target difficulty is selected using predicted-success bands,
- recovery mode uses hysteresis,
- puzzle difficulty estimates have their own confidence.

Never:
- increase difficulty solely because of one lucky answer,
- decrease it drastically after one mistake,
- infer low cognitive skill solely from slow accessible input,
- trust an AI difficulty label as calibrated truth.
