# raspi — Status

Succeeds the raspi-relevant slice of the old `Workstation` repo's `STATUS.md` (which
was, in practice, almost entirely about the workstation node — see
`nodes/workstation/status.md`). Verified live 2026-07-21, not copied from that file.

## Services

| Service | State | Notes |
|---|---|---|
| `zax_directory.service` | ✅ active | ZaxEnergy Unit Directory |
| `mosquitto.service` | ⚠️ **failed** (exit-code, status=3) since 2026-06-26 — enabled but not running | 3+ weeks down at time of writing. Legacy local broker for ZAX units per the old migration record — not otherwise investigated or fixed as part of this build; flagged here as a live finding, not a fix. |
| `zaxmodbus-poller.service` | inactive, disabled | Expected — started manually per test session (see ZaxModbus repo's `tools/conftest.py` `poller_stopped` fixture), not meant to run continuously. |

## Role in the current fleet

- Coordinates ZaxModbus/EnergyCalibrator/EmonESP firmware work directly (Arduino
  build/flash toolchain, `flash_guard.py` + `/home/pi/boards.json`)
- RS-485 bus (`/dev/ttyUSB0`) — Modbus polling for the ZaxModbus bench fleet
- Hosts this Claude Code coordination session

## Open items (not addressed by this build)

- `mosquitto.service` failure — worth a look next time Pi-side MQTT is actually needed.
