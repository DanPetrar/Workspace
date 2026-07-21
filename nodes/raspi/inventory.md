# raspi — Inventory

Verified live 2026-07-21. Update whenever a tool is installed/removed/reconfigured.

| Tool | Version |
|---|---|
| Git | 2.47.3 |
| Python 3 | 3.13.5 |
| Node.js | 20.20.2 |
| npm | 10.8.2 |
| Claude Code | 2.1.216 |
| arduino-cli | 1.4.1 |
| GitHub CLI (`gh`) | 2.92.0 |
| esptool | via `python3 -m esptool` (part of the `esp32` arduino-cli core, `~/.arduino15/packages/esp32/tools/esptool_py/`) |

## Embedded/firmware-specific

- Arduino cores + libraries under `~/Arduino/`, `~/.arduino15/`
- `flash_guard.py` + `/home/pi/boards.json` — board catalog + pre-flash identity/cable
  guard, used by every USB flash script across the ZaxModbus/EnergyCalibrator/EmonESP
  projects
- `identity_guard.py` — newer unified firmware-identity guard, partially rolled out
  (see `IDENTITY_GUARD_PLAN.md` in the Pi home directory)
