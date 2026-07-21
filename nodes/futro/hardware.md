# futro — Hardware

**Status: `planned`. Not yet acquired — nothing below has been independently verified.**

| Field | Value (as stated by user, unverified) |
|---|---|
| Model | Fujitsu Futro S740 |
| CPU | Intel Celeron |
| RAM | 8 GB DDR4 |
| Storage | 1× 500 GB SSD |
| OS (intended) | Debian 13 (trixie) x86_64 — chosen to match `raspi`'s OS exactly (see `nodes/raspi/hardware.md`) |

## Role (intended, once active)

Inherits the `raspi` node's coordinator role (see `nodes/INDEX.md`) — the Claude Code
session-coordination duties specifically. Physically-tied work (USB/serial/RS-485/GPIO
bench hardware) stays with `raspi` regardless, since it depends on physical cabling,
not compute headroom.

## Bring-up (when acquired)

1. Human: minimal manual setup — Debian 13 install, network config, SSH key — up to
   SSH reachability. A detailed step-by-step doc for this is a separate deliverable,
   not yet written.
2. Claude (from `raspi`, via SSH): completes the rest — mirrors the pattern already
   used for `workstation` (see `MIGRATION-pi-to-workstation.md` in the old `Workstation`
   repo for that precedent).
3. Once live: fill in this file with verified specs, flip `nodes/INDEX.md` status to
   `active`, add `nodes/futro/{status,inventory}.md` + `setup/`, add
   `infrastructure/health-futro.sh`.
