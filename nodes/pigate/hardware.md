# pigate — Hardware

**Status: `planned`.** Not yet received. Everything below is **expected, not verified** —
replace with live values (`cat /proc/device-tree/model`, `free -h`, `lsblk`,
`/etc/os-release`) at bring-up, as `nodes/futro/hardware.md` did.

| Field | Value |
|---|---|
| Model | Raspberry Pi 4 (expected) |
| RAM | 2 GB (expected) |
| Storage | 64 GB SD card (expected blank) |
| OS | Raspberry Pi OS Lite 64-bit (planned) |
| Hostname | not yet chosen |
| IP | DHCP, not yet on the LAN |

## Attached bench hardware

| Item | Role | State |
|---|---|---|
| RS-485 USB adapter | one PiGate line, direct serial | existing adapter, which one still to be chosen |
| Waveshare RS485 TO ETH (B) | one PiGate line, over Modbus TCP `:4196` | on the LAN at `192.168.20.110` (DHCP, re-checked 2026-09-11), no units on its line yet. Config record: `ZaxModbus/Doc/rs485-eth-gateway/bench-setup.md` |
| ZaxModbus units | Modbus slaves on the PiGate lines | not yet chosen — must not be units on the gate segments |
