# raspi — Status

Succeeds the raspi-relevant slice of the old `Workstation` repo's `STATUS.md` (which
was, in practice, almost entirely about the workstation node — see
`nodes/workstation/status.md`). Verified live 2026-07-21, not copied from that file.

## Services

| Service | State | Notes |
|---|---|---|
| `zax_directory.service` | ✅ active | ZaxEnergy Unit Directory |
| `mosquitto.service` | ✅ active (restored 2026-08-06) | Root cause: invalid `log_type connect`/`log_type disconnect` directives in `/etc/mosquitto/conf.d/conn_log.conf`, failed since 2026-06-26; file moved aside, not deleted. Reclassified local-dev/test-only — confirmed zero production publisher/subscriber uses it (ZAX fleet has published directly to the Workstation broker since 2026-06-24). See `INFRASTRUCTURE.md` and `infrastructure-interaction.md`. |
| `zaxmodbus-poller.service` | inactive, disabled | Expected — started manually per test session (see ZaxModbus repo's `tools/conftest.py` `poller_stopped` fixture), not meant to run continuously. |

## Role in the current fleet

- Coordinates ZaxModbus/EnergyCalibrator/EmonESP firmware work directly (Arduino
  build/flash toolchain, `flash_guard.py` + `/home/pi/boards.json`)
- RS-485 bus (`/dev/ttyUSB0`) — Modbus polling for the ZaxModbus bench fleet
- Hosts this Claude Code coordination session

## Open items (not addressed by this build)

- None — `mosquitto.service` fixed 2026-08-06 (see above).
