# raspi — Hardware

Verified live 2026-07-21 (`cat /proc/device-tree/model`, `uname -a`, `cat /etc/os-release`,
`nproc`, `free -h`, `df -h`, `lsblk`).

| Field | Value |
|---|---|
| Model | Raspberry Pi 4 Model B Rev 1.4 |
| CPU | 4× Cortex-A72 (aarch64) |
| RAM | 1.8 GiB usable (`free -h` total) — see discrepancy note below |
| Storage | `mmcblk0`, 58.2 GB total (57 GB on the root partition `mmcblk0p2`, 512 MB `/boot/firmware`) |
| Swap | 1.8 GiB (zram) |
| OS | Debian GNU/Linux 13 (trixie), kernel `6.12.75+rpt-rpi-v8` |
| Hostname | `esp-devbox64` |

**Discrepancy vs. the original planning doc** (`workspace-update.md`, direction 2): that
doc stated "1 GB RAM, 32 GB SD card." Live check shows ~1.8 GiB RAM (consistent with the
2 GB Pi 4 variant, not 1 GB) and a ~58 GB SD card (consistent with a 64 GB card, not
32 GB). The planning doc's figures were apparently a rough/incorrect recollection —
this file's numbers are the verified ones.

## Role

- Session coordinator (runs Claude Code) — see `nodes/INDEX.md`
- Testing station: physically cabled to bench hardware (ESP32 boards via USB/serial,
  RS-485 adapter for Modbus, GPIO) for ZaxModbus/EnergyCalibrator/EmonESP firmware
  development and flashing. This role is tied to the physical cabling and does not
  transfer to another machine without rewiring.
