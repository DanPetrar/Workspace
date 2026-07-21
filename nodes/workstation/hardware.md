# workstation — Hardware

Verified live 2026-07-21 via `ssh ws` (`cat /etc/os-release`, `uname -a`, `nproc`,
`lscpu`, `free -h`, `df -h`, `lsblk`).

| Field | Value |
|---|---|
| CPU | Intel(R) Core(TM) i3-6100U @ 2.30GHz, 4 threads (x86_64) |
| RAM | 7.1 GiB usable (`free -h` total) |
| Storage | 2 disks: `nvme0n1` 238.5 GB (root + `/boot/efi`), `sda` 223.6 GB (mounted `/workspace`) |
| Swap | 4.0 GiB |
| OS | Ubuntu 26.04 LTS (Resolute Raccoon), kernel `7.0.0-15-generic` |
| Hostname | `MainDevbox` |

**Correction (carried over from `workspace-update.md` direction 6):** the old
`Workstation` repo's `README.md` states the OS as "Debian Linux" — confirmed **wrong**
live; it's genuinely Ubuntu 26.04. This file records the correct value; the stale
README claim is not otherwise fixed by this build (separate repo).

Matches the planning doc's stated CPU/RAM/disk figures (Core i3, 8 GB RAM, 2×240 GB
SSD) closely — no discrepancy here, unlike raspi's.

## Role

Infrastructure host — see `nodes/INDEX.md` and `infrastructure-interaction.md` for
what runs here and how it's reached.
