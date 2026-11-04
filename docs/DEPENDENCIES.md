# MindForge Dependencies and Licenses

Everything the project uses that it did not write. `tools/audit_release.py`
fails when a Godot addon, Python requirement or CI action is used but not
listed here, or listed but no longer used. Media assets are registered
separately in [ASSETS.md](ASSETS.md).

## Inventory

| Kind | Name | Used for | Required? | License |
|---|---|---|---|---|
| engine | Godot Engine 4.5.2-stable | Game engine, editor, headless test runner, export templates | Yes | MIT (Godot `LICENSE.txt`; bundled third-party code under the licenses in Godot's `COPYRIGHT.txt`) |
| font | Open Sans SemiBold (Godot default font) | All interface text; ships inside the engine, no font file in the repository | Yes | SIL OFL 1.1 |
| python | `anthropic` | Claude provider of the optional AI proxy (`backend/app/providers/anthropic_provider.py`, imported lazily) | No: the proxy falls back to the offline mock provider, and the game runs without the proxy | MIT |
| action | `actions/checkout` | CI: check out the repository | CI only | MIT |
| action | `actions/setup-python` | CI: Python for the proxy tests and audits | CI only | MIT |
| action | `actions/cache` | CI: cache the pinned Godot binary | CI only | MIT |

The Python standard library covers the proxy server, its tests and all
repository tools (`tools/*.py`). There are no Godot addons (`addons/` does
not exist) and no GDScript libraries from outside the project.

## Not shipped in exports

The export presets exclude `backend/`, `tests/`, `tools/`, `docs/` and
`.env*`, so the only third-party code in a release build is the Godot
engine itself (with its font).

## Audit

```bash
python tools/audit_release.py            # tracked files
python tools/audit_release.py --history  # plus every committed revision
```

Last full audit (Task 8.7): no tracked `.env` or credentials in the tree or
history, no key-shaped strings in any revision, `.env.example` holds only
empty secret values, every media file is registered, and the dependency
list above matches what is used.
