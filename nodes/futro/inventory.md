# futro — Inventory

Verified live 2026-07-22. Update whenever a tool is installed/removed/reconfigured.

| Tool | Version |
|---|---|
| Git | 2.47.3 |
| Python 3 | 3.13.5 |
| Node.js | 20.20.2 (NodeSource, required by ponytail's Claude Code hooks) |
| Claude Code | 2.1.217 |
| GitHub CLI (`gh`) | 2.96.0 |
| `arduino-cli` | 1.4.1, ESP32 core 3.3.7 — matches raspi |
| ESP-IDF | v6.0.1 (`~/esp/esp-idf`) — matches raspi |
| `esptool` | via the ESP32 arduino-cli core (bundled, not separate), same as raspi |

## Dev-toolchain parity (added 2026-07-22, same day as bring-up)

Reverses the original "raspi-only" framing — see `setup-plan.md` amendment for the
full reasoning (futro is co-located with the bench; boards/USB cables move between
machines by hand as needed).

- `~/Arduino/libraries/` — copied from raspi (ZaxCommon, ArduinoJson, PubSubClient,
  ModbusMaster, OneWire, DallasTemperature, Adafruit_NeoPixel)
- `flash_guard.py` + `identity_guard.py` — copied/symlinked matching raspi's layout
- `~/boards.json` — **not a local copy.** Symlinked to an `sshfs` mount
  (`~/pi-raspi-mnt`, backed by a hard link at `raspi:~/shared/boards.json`) so raspi
  stays the single writable authority. Confirmed both read and write-through live.
  Mount is a systemd service, `/etc/systemd/system/sshfs-boards.service`
  (`Restart=on-failure`, `After=network-online.target`, enabled at boot) — **verified
  to survive a real reboot** 2026-07-22 (mounted automatically, `flash_guard.py list`
  read the shared catalog correctly with no manual step).
- `dialout` group added to `dan-futro` for serial port access once hardware is
  plugged into futro's own USB ports
- **Verified end-to-end 2026-07-22:** `bash ~/ZaxModbus/arduino/build_s3zero.sh
  --build-only` compiled clean (1,138,899 bytes, 57%) using the real project build
  script, and `flash_guard.py list` read the live shared catalog (17 boards, matching
  raspi exactly)
