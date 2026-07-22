# futro — Inventory

Verified live 2026-07-22, at close of bring-up. Update whenever a tool is
installed/removed/reconfigured.

| Tool | Version |
|---|---|
| Git | 2.47.3 |
| Python 3 | 3.13.5 |
| Claude Code | 2.1.217 |
| GitHub CLI (`gh`) | 2.96.0 |

Node.js/npm are **not installed** — nothing in the coordinator role has needed them so
far; add if a project requires it.

## Deliberately absent (role boundary — see `setup-plan.md` section 4.5)

`arduino-cli`, `esptool.py`, `~/boards.json`, `flash_guard.py` — all testing-station
tooling, stays on `raspi` only. Confirmed absent as part of the 9-point validation
checklist.
