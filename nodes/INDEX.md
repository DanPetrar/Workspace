# Node Index

Single source of truth for node count and role assignment. Every other doc in this
repo references this table rather than restating it — adding a node means adding a
row here + a `nodes/<name>/` directory, nothing else needs to change.

| Node | Role | Status | IP | Notes |
|------|------|--------|-----|-------|
| raspi | testing station + dev toolchain | active | 192.168.110.225 | Holds the permanent bench (serial/USB/GPIO/RS-485 for Units A-D) — see `nodes/raspi/hardware.md`. Coordinator role transferred to `futro` 2026-07-22. **Keeps every capability it had before** — nothing removed. |
| workstation | infrastructure host | active | 192.168.110.11 | Hosts shared services (DB, dashboards, MQTT broker, parsers) for all projects — see `nodes/workstation/hardware.md`. |
| futro | coordinator + dev toolchain | active | 192.168.110.8 | Fujitsu Futro S740, co-located with the bench. Took over the full coordinator role from `raspi` 2026-07-22, **plus full dev-toolchain parity added the same day** (arduino-cli/ESP-IDF/flash_guard.py — user direction, Fable-reviewed, reverses the original testing-station-exclusivity plan) — see `nodes/futro/setup-plan.md` amendment and `nodes/futro/status.md`. Boards/USB cables move between raspi and futro by hand as needed; `boards.json` stays single-authority on raspi via `sshfs`. |
