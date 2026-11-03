"""Checks that docs/TASKS.md and docs/PROJECT_PHASES_AND_TASKS.md agree.

Every task must appear in both files with the same completion state, and a
completed task must have all Definition of Done boxes ticked.
Usage: python tools/check_task_ledger.py   (exit 1 on any mismatch)
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TASKS = ROOT / "docs" / "TASKS.md"
PHASES = ROOT / "docs" / "PROJECT_PHASES_AND_TASKS.md"


def ledger() -> dict:
    found = {}
    for line in TASKS.read_text(encoding="utf-8").splitlines():
        m = re.match(r"- \[( |x)\] \*\*Task (\d+\.\d+)\*\*", line)
        if m:
            found[m.group(2)] = m.group(1) == "x"
    return found


def phases() -> dict:
    text = PHASES.read_text(encoding="utf-8")
    found = {}
    for block in re.split(r"\n(?=### Task )", text)[1:]:
        m = re.match(r"### Task (\d+\.\d+):", block)
        if not m:
            continue
        block = block.split("\n---\n")[0]
        done = "**Status:** `[x]`" in block
        open_boxes = "- [ ] " in block
        found[m.group(1)] = (done, open_boxes)
    return found


def main() -> int:
    tasks, plan = ledger(), phases()
    problems = []
    for task_id in sorted(set(tasks) | set(plan), key=lambda t: tuple(int(p) for p in t.split("."))):
        if task_id not in tasks:
            problems.append(f"Task {task_id} missing from TASKS.md")
        elif task_id not in plan:
            problems.append(f"Task {task_id} missing from PROJECT_PHASES_AND_TASKS.md")
        else:
            done, open_boxes = plan[task_id]
            if tasks[task_id] != done:
                problems.append(f"Task {task_id}: TASKS.md says {'done' if tasks[task_id] else 'open'}, phases doc disagrees")
            if done and open_boxes:
                problems.append(f"Task {task_id}: completed but Definition of Done has unticked boxes")
    for problem in problems:
        print(f"FAIL {problem}")
    print(f"task ledger: {len(tasks)} tasks, {sum(tasks.values())} done, {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
