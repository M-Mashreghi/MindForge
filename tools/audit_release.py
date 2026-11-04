"""Release audit: secrets, licensing and dependencies (docs/DEPENDENCIES.md).

    python tools/audit_release.py            # tracked files
    python tools/audit_release.py --history  # also every committed revision

Fails (exit 1) when:
- a tracked file is `.env` or export credentials, or any tracked file (or, with
  --history, any past revision) contains something shaped like a provider key;
- `.env.example` holds a value for a secret variable;
- an image, audio, font or binary media file is tracked but not listed in
  docs/ASSETS.md;
- a Godot addon, a Python requirement or a CI action is used but not listed
  in docs/DEPENDENCIES.md, or a listed one is no longer used.
Standard library only.
"""

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SECRET_PATTERNS = [
    re.compile(r"sk-ant-[A-Za-z0-9_\-]{16,}"),
    re.compile(r"\bsk-[A-Za-z0-9]{20,}"),
    re.compile(r"\bghp_[A-Za-z0-9]{20,}"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
]
SECRET_FILES = re.compile(r"(^|/)\.env$|export_credentials\.cfg$|\.(pem|p12|keystore)$")
SECRET_VARS = re.compile(r"^\s*([A-Z0-9_]*(KEY|SECRET|TOKEN|PASSWORD)[A-Z0-9_]*)\s*=\s*(\S+)")
MEDIA = {".png", ".jpg", ".jpeg", ".webp", ".svg", ".wav", ".ogg", ".mp3", ".ttf", ".otf", ".woff", ".woff2"}
# This file and the pre-commit script contain the patterns themselves.
SELF = {"tools/audit_release.py", "tools/precommit_check.sh", ".github/workflows/ci.yml"}


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True,
                          encoding="utf-8", errors="replace").stdout


def tracked() -> list:
    return [p for p in git("ls-files").splitlines() if p]


def scan_text(label: str, text: str, problems: list) -> None:
    for pattern in SECRET_PATTERNS:
        if pattern.search(text):
            problems.append(f"possible secret ({pattern.pattern}) in {label}")


def check_secrets(files: list, history: bool, problems: list) -> None:
    for path in files:
        if SECRET_FILES.search(path):
            problems.append(f"secret-bearing file is tracked: {path}")
        if path in SELF:
            continue
        file = ROOT / path
        if file.suffix.lower() in MEDIA or not file.is_file():
            continue
        scan_text(path, file.read_text(encoding="utf-8", errors="replace"), problems)
    example = ROOT / ".env.example"
    if example.exists():
        for line in example.read_text(encoding="utf-8").splitlines():
            m = SECRET_VARS.match(line)
            if m:
                problems.append(f".env.example sets a value for {m.group(1)}")
    if history:
        for path in git("log", "--all", "--name-only", "--format=").splitlines():
            if path and SECRET_FILES.search(path):
                problems.append(f"secret-bearing file in history: {path}")
        log = git("log", "--all", "-p", "--format=commit %H", "--", ".", *[f":!{p}" for p in SELF])
        scan_text("git history", log, problems)


def check_media(files: list, problems: list) -> None:
    register = (ROOT / "docs" / "ASSETS.md").read_text(encoding="utf-8")
    for path in files:
        if pathlib.PurePosixPath(path).suffix.lower() not in MEDIA:
            continue
        # Screenshots are covered by the docs/images row of the register.
        if path.startswith("docs/images/") and "docs/images/" in register:
            continue
        if path not in register:
            problems.append(f"media file not in docs/ASSETS.md: {path}")


def used_dependencies(files: list) -> dict:
    used = {"addon": set(), "python": set(), "action": set()}
    for path in files:
        if path.startswith("addons/") and path.count("/") >= 2:
            used["addon"].add(path.split("/")[1])
    requirements = ROOT / "backend" / "requirements.txt"
    if requirements.exists():
        for line in requirements.read_text(encoding="utf-8").splitlines():
            line = line.split("#")[0].strip()
            if line:
                used["python"].add(re.split(r"[<>=!~\[ ]", line)[0].lower())
    for path in files:
        if path.startswith(".github/workflows/"):
            for m in re.finditer(r"uses:\s*([\w.\-]+/[\w.\-]+)@", (ROOT / path).read_text(encoding="utf-8")):
                used["action"].add(m.group(1))
    return used


def listed_dependencies() -> dict:
    listed = {"addon": set(), "python": set(), "action": set()}
    for line in (ROOT / "docs" / "DEPENDENCIES.md").read_text(encoding="utf-8").splitlines():
        m = re.match(r"\|\s*(addon|python|action)\s*\|\s*`([^`]+)`", line)
        if m:
            listed[m.group(1)].add(m.group(2).lower() if m.group(1) == "python" else m.group(2))
    return listed


def check_dependencies(files: list, problems: list) -> None:
    used, listed = used_dependencies(files), listed_dependencies()
    for kind in used:
        for name in sorted(used[kind] - listed[kind]):
            problems.append(f"{kind} dependency not in docs/DEPENDENCIES.md: {name}")
        for name in sorted(listed[kind] - used[kind]):
            problems.append(f"docs/DEPENDENCIES.md lists unused {kind} dependency: {name}")


def main() -> int:
    files = tracked()
    problems: list = []
    check_secrets(files, "--history" in sys.argv, problems)
    check_media(files, problems)
    check_dependencies(files, problems)
    for problem in problems:
        print(f"FAIL {problem}")
    print(f"release audit: {len(files)} tracked files, {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
