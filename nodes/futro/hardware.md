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

Full plan (Linux version, partition scheme, human install steps, remote completion by
`raspi`'s Claude Code session, and validation checks): see
[`setup-plan.md`](setup-plan.md).
