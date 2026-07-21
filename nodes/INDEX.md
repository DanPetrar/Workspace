# Node Index

Single source of truth for node count and role assignment. Every other doc in this
repo references this table rather than restating it — adding a node means adding a
row here + a `nodes/<name>/` directory, nothing else needs to change.

| Node | Role | Status | IP | Notes |
|------|------|--------|-----|-------|
| raspi | coordinator, testing station | active | 192.168.110.225 | This machine. Runs Claude Code (session coordination); physically cabled to bench hardware (serial/USB/GPIO/RS-485) — see `nodes/raspi/hardware.md`. |
| workstation | infrastructure host | active | 192.168.110.11 | Hosts shared services (DB, dashboards, MQTT broker, parsers) for all projects — see `nodes/workstation/hardware.md`. |
| futro | — | planned | — | Fujitsu Futro S740, not yet acquired. Intended to inherit the raspi coordinator role once bring-up completes — see `nodes/futro/hardware.md`. |
