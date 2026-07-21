# Node Index

Single source of truth for node count and role assignment. Every other doc in this
repo references this table rather than restating it — adding a node means adding a
row here + a `nodes/<name>/` directory, nothing else needs to change.

| Node | Role | Status | IP | Notes |
|------|------|--------|-----|-------|
| raspi | coordinator, testing station | active | 192.168.110.225 | This machine. Runs Claude Code (session coordination); physically cabled to bench hardware (serial/USB/GPIO/RS-485) — see `nodes/raspi/hardware.md`. **Coordinator role planned to transfer to `futro` once it's active — see `nodes/futro/setup-plan.md`; `raspi` then narrows to testing station only.** |
| workstation | infrastructure host | active | 192.168.110.11 | Hosts shared services (DB, dashboards, MQTT broker, parsers) for all projects — see `nodes/workstation/hardware.md`. |
| futro | coordinator (once active) | planned | — | Fujitsu Futro S740, not yet acquired. Takes over the full coordinator role from `raspi` on bring-up — see `nodes/futro/setup-plan.md`. |
