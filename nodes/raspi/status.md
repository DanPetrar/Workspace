# raspi — Status

Succeeds the raspi-relevant slice of the old `Workstation` repo's `STATUS.md` (which
was, in practice, almost entirely about the workstation node — see
`nodes/workstation/status.md`). Verified live 2026-07-21, not copied from that file.

## Services

| Service | State | Notes |
|---|---|---|
| `zax_directory.service` | ✅ active | ZaxEnergy Unit Directory |
| `mosquitto.service` | ✅ active (restored 2026-08-06) | Root cause: invalid `log_type connect`/`log_type disconnect` directives in `/etc/mosquitto/conf.d/conn_log.conf`, failed since 2026-06-26; file moved aside, not deleted. Reclassified local-dev/test-only — confirmed zero production publisher/subscriber uses it (ZAX fleet has published directly to the Workstation broker since 2026-06-24). See `INFRASTRUCTURE.md` and `infrastructure-interaction.md`. |
| `zaxmodbus-poller.service` | inactive, disabled | Expected — started manually per test session (see ZaxModbus repo's `tools/conftest.py` `poller_stopped` fixture), not meant to run continuously. |
| temperature log (`pi` crontab) | ✅ added 2026-09-15 | Every minute `vcgencmd measure_temp` + `vcgencmd get_throttled` → journal tag `pitemp` (`journalctl -t pitemp`). Added after a bench Pi without cooling failed hot; raspi is in a metal case with a fan — first entry 34.5 °C, `throttled=0x0`. |

## Role in the current fleet

- Coordinates ZaxModbus/EnergyCalibrator/EmonESP firmware work directly (Arduino
  build/flash toolchain, `flash_guard.py` + `/home/pi/boards.json`)
- RS-485 bus (`/dev/ttyUSB0`) — Modbus polling for the ZaxModbus bench fleet. **Since 2026-09-18 no RS-485
  adapter is plugged in** (the CH340 lives on the PiGate Pi, the Prolific on GW3M710); it is moved here only
  for a ZaxModbus gate. Unit_A's and Unit-ETH00's own USB cables are on raspi (`/dev/ttyACM0`/`ttyACM1`,
  by-id names in ZaxModbus `tools/zaxtest/units.yaml`). Bench units powered off 2026-09-18 15:00 for ~10 days.
- **Since 2026-10-13 the bench holds PS-Z001**, the first new-hardware unit (NEW-BOX + S3-Zero, MAC
  `3C:0F:02:E4:92:18`, ZaxModbus firmware 1.2.1 from branch `v1.2.1-newbox`): USB on raspi (`/dev/ttyACM0`), WiFi
  `192.168.20.119`, MQTT topic `zax_E49218` -> Workstation -> Grafana. The PiGate bench (Unit_A, Unit-ETH00,
  Waveshare) was dismounted by the owner the same day; the two lines above describe the state before that.
  Record: ZaxModbus `Doc/new-hardware/PS-Z001/2026-10-13-session-close.md`.
- **USB controller wedge (third time, 2026-10-13):** every device failing with `error -110` / `-71` /
  `unable to enumerate` after 28 days of uptime = the Pi's xHCI controller, not the device. Fix without a reboot:
  `echo 0000:01:00.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind; sleep 3; echo 0000:01:00.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind`
  (ZaxModbus `Doc/errors-history.md` 2026-10-13).
- **2026-10-14:** a new CH340 USB-RS485 adapter is on the Pi (`/dev/ttyUSB0`, `usb-1a86_USB_Serial-if00-port0`, no
  serial number), verified on Unit_A (100/100). PS-Z001 runs 1.2.4 by OTA and is off the Pi's USB (to be moved to a
  real grid). Record: ZaxModbus `Doc/new-hardware/PS-Z001/2026-10-14-session-close.md`.
- **2026-10-14 evening:** PS-Z001 fw 1.2.7 since 20:52 (1.2.5 Modbus TX/RX swapped, 1.2.6 web UI energy, 1.2.7 raw BOX
  minute set in the error log), moved to a real grid with Modbus off until
  2026-10-16 09:00. raspi runs the hourly report recorder `hourly.py` (setsid nohup, no auto-restart after a raspi
  reboot). Record: ZaxModbus `Doc/new-hardware/PS-Z001/2026-10-14-evening-status.md`.
- **2026-10-15:** PS-Z001 back from the box team (BOX energy direction fixed), USB reflash 1.2.7, PS-Z001 history erased
  (InfluxDB + unit), grid run 2 since 13:07 with the raspi recorder `grid-20261015/hourly.py` (no auto-restart).
  fw 1.2.9 since 16:15, Modbus ON and verified via GW2Pi4 (moved next to the unit; its gateway stopped+disabled,
  `mbpoll.py` running there). The raspi has no USB serial adapter now (the CH340 went to GW2Pi4).
  Record: ZaxModbus `Doc/new-hardware/PS-Z001/2026-10-15-status.md`.
- Hosts this Claude Code coordination session

## Open items (not addressed by this build)

- None — `mosquitto.service` fixed 2026-08-06 (see above).
