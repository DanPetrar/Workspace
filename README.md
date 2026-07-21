# Workspace

Documents and coordinates the development hardware fleet behind the ZaxEnergy
projects: currently the **raspi** (coordinator + testing station) and **workstation**
(shared infrastructure host) nodes, with a **futro** node planned. See
[`nodes/INDEX.md`](nodes/INDEX.md) for the current node list, roles, and status.

## Scope

Infrastructure, hardware, and cross-node coordination live here. Project-specific
specs, firmware, and test plans stay in their own project repos (ZaxModbus,
EnergyCalibrator, etc.) — this repo cross-references them, never duplicates them.

## Start here

- [`nodes/INDEX.md`](nodes/INDEX.md) — node list, roles, status
- [`infrastructure-interaction.md`](infrastructure-interaction.md) — what runs where,
  data flow, operating rules
- [`COORDINATION.md`](COORDINATION.md) — session-handoff workflow
- [`test-units.md`](test-units.md) — local bench hardware (role/wiring only —
  `/home/pi/boards.json` is the authority for firmware/version)
- `nodes/<node>/` — per-node hardware facts, status, inventory, setup history

## Relationship to the old `Workstation` repo

This is a **separate, new project** — `Workstation` (`github.com/DanPetrar/Workstation`)
stays untouched and remains the working reference until Workspace's structure is
complete and verified, at which point a cutover happens. See `workspace-update.md` in
the old repo for the full reformulation history and decisions behind this rebuild.
