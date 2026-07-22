# Node Index

Single source of truth for node count and role assignment. Every other doc in this
repo references this table rather than restating it — adding a node means adding a
row here + a `nodes/<name>/` directory, nothing else needs to change.

| Node | Role | Status | IP | Notes |
|------|------|--------|-----|-------|
| raspi | testing station | active | 192.168.110.225 | Physically cabled to bench hardware (serial/USB/GPIO/RS-485) — see `nodes/raspi/hardware.md`. **Coordinator role transferred to `futro` 2026-07-22 (all 9 validation checks passed) — see `nodes/futro/setup-plan.md`.** |
| workstation | infrastructure host | active | 192.168.110.11 | Hosts shared services (DB, dashboards, MQTT broker, parsers) for all projects — see `nodes/workstation/hardware.md`. |
| futro | coordinator | active | 192.168.110.8 | Fujitsu Futro S740. Took over the full coordinator role from `raspi` 2026-07-22 — see `nodes/futro/setup-plan.md` and `nodes/futro/status.md`. |
