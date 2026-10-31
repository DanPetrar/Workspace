# Node Index

Single source of truth for node count and role assignment. Every other doc in this
repo references this table rather than restating it — adding a node means adding a
row here + a `nodes/<name>/` directory, nothing else needs to change.

| Node | Role | Status | IP | Notes |
|------|------|--------|-----|-------|
| raspi | standby (rollback) | standby | 192.168.20.225 | Bench moved to f22 2026-10-31 (`nodes/f22/switch-plan.md`). Reads boards.json from f22 over sshfs (`~/f22-mnt`); keeps mq1884 (port 1884, Unit_A #79), system mosquitto 1883 and its toolchain for the V14 rollback. zax_directory stopped. No Claude sessions until the owner releases it. See `nodes/raspi/hardware.md`. |
| workstation | infrastructure host | active | 192.168.20.11 | Hosts shared services (DB, dashboards, MQTT broker, parsers) for all projects — see `nodes/workstation/hardware.md`. |
| futro | coordinator + dev toolchain | active | 192.168.20.226 | Fujitsu Futro S740, co-located with the bench. Took over the full coordinator role from `raspi` 2026-07-22, **plus full dev-toolchain parity added the same day** (arduino-cli/ESP-IDF/flash_guard.py — user direction, Fable-reviewed, reverses the original testing-station-exclusivity plan) — see `nodes/futro/setup-plan.md` amendment and `nodes/futro/status.md`. Boards/USB cables move between raspi and futro by hand as needed; `boards.json` stays single-authority on raspi via `sshfs`. |
| f22 | testing station + dev toolchain | active | 192.168.20.222 | Fujitsu Futro S940, Intel J5005 x86_64, Debian 13.7, 220 GB SSD; bench machine since 2026-10-31 (PS-E002 + CH340 on USB). boards.json authority (`~/shared/boards.json`), nightly backup to ws 00:15; futro and raspi mount it. Address from DHCP (reservation: owner to confirm). See `nodes/f22/role-setup-plan.md`, `switch-plan.md`. |

Still naming the raspi as the bench, unchanged on purpose (2026-10-31): Workstation `INFRASTRUCTURE.md`, `inventory.md`, `COORDINATION.md`, `infrastructure/health-pi.sh`; Workspace `infrastructure/zax_parser.py` (document copy).
