"""Release history check (docs/RELEASE.md).

    python tools/check_release.py               # history only
    python tools/check_release.py --tag v0.1.0  # also: tag on HEAD and on origin

Fails (exit 1) when a task marked done in docs/TASKS.md has no
`task(<id>): ...` commit, when the working tree has uncommitted changes, when
HEAD is not on origin/main, or (with --tag) when the tag is missing locally,
does not point at HEAD, or has not been pushed to origin.
Standard library only.
"""

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def git(*args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if check and result.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def done_tasks() -> list:
    text = (ROOT / "docs" / "TASKS.md").read_text(encoding="utf-8")
    return re.findall(r"- \[x\] \*\*Task (\d+\.\d+)\*\*", text)


def main() -> int:
    problems = []
    subjects = git("log", "--format=%s").splitlines()
    committed = {m.group(1) for s in subjects if (m := re.match(r"task\((\d+\.\d+)\):", s))}
    for task_id in done_tasks():
        if task_id not in committed:
            problems.append(f"Task {task_id} is done but has no task({task_id}) commit")
    if git("status", "--porcelain"):
        problems.append("working tree has uncommitted changes")
    git("fetch", "--quiet", "origin", "main", "--tags", check=False)
    head = git("rev-parse", "HEAD")
    if subprocess.run(["git", "merge-base", "--is-ancestor", head, "origin/main"], cwd=ROOT).returncode != 0:
        problems.append("HEAD is not pushed to origin/main")
    if "--tag" in sys.argv:
        tag = sys.argv[sys.argv.index("--tag") + 1]
        local = git("rev-parse", "--verify", "--quiet", f"refs/tags/{tag}^{{commit}}", check=False)
        if not local:
            problems.append(f"tag {tag} does not exist")
        elif local != head:
            problems.append(f"tag {tag} does not point at HEAD")
        remote = git("ls-remote", "--tags", "origin", f"refs/tags/{tag}", check=False)
        if not remote:
            problems.append(f"tag {tag} is not on origin")
    for problem in problems:
        print(f"FAIL {problem}")
    print(f"release check: {len(done_tasks())} done tasks, {len(committed)} task commits, {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
