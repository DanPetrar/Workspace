# futro — Hardware

**Status: `active`.** Acquired, installed, and bring-up completed 2026-07-22. Verified
live (`lscpu`, `free -h`, `lsblk -d -o NAME,SIZE,MODEL`, `/sys/firmware/efi`,
`/etc/os-release`) over SSH from `raspi` during bring-up.

| Field | Value |
|---|---|
| Model | Fujitsu Futro S740 |
| CPU | Intel Celeron J4105 @ 1.50GHz, 4 cores (x86_64) |
| RAM | 7.5 GiB usable (8 GB DDR4 nominal) |
| Storage | 1× 476.9 GB SSD (Transcend TS512GMTS430S, 512 GB nominal) |
| Boot mode | UEFI |
| Partitions | `sda1` 487 MB vfat `/boot/efi`; `sda2` 7.5 GB swap; `sda3` 469 GB ext4 `/` — matches the plan's section 2 scheme exactly |
| OS | Debian GNU/Linux 13 (trixie) x86_64 |
| Hostname | `futro` |
| IP | 192.168.110.8 (DHCP, `eno1`) |

## Role

- Session coordinator (runs Claude Code) — see `nodes/INDEX.md`. Took over the full
  coordinator role from `raspi` on this bring-up.
- **Full dev-toolchain parity with raspi** (added 2026-07-22, same day as bring-up —
  see `setup-plan.md` amendment): arduino-cli + ESP32 core + ESP-IDF + Arduino
  libraries + `flash_guard.py`, matching raspi's versions. `boards.json` stays
  single-authority on raspi, reached via `sshfs` mount — never a local copy.
- Co-located with the permanent bench — boards/USB cables can be moved to futro's own
  ports for local flash/serial-monitor work. The permanent bench itself (Units A-D,
  RS-485 bus) stays wired to raspi; drive it remotely via `ssh bench` when it's not
  physically moved.

## Bring-up

Full plan (Linux version, partition scheme, human install steps, remote completion by
`raspi`'s Claude Code session, and validation checks): see
[`setup-plan.md`](setup-plan.md). All 9 validation checks passed 2026-07-22.
