# Infrastructure Interaction — Fleet-Wide Data Flow & Operating Rules

Successor to the old `Workstation` repo's `INFRASTRUCTURE.md` sections 2–3. Per-node
facts (what each machine runs) live in `nodes/<node>/status.md`; this file owns the
**cross-node** picture — who talks to whom, and the standing rules for where new work
goes.

_Verified live 2026-07-21._ The old file was last verified 2026-06-03 and had drifted
in three ways found during this rewrite (see corrections below) — re-verify this file
periodically the same way, don't assume it stays accurate on its own.

## Amendment 2026-07-22 — raspi/futro dev-toolchain split reversed

Rules 2 and 3 below originally read as a strict raspi-only split (mirroring
`nodes/futro/setup-plan.md` section 4.5 at the time). **User direction 2026-07-22:**
futro gets full software toolchain parity with raspi (arduino-cli, ESP-IDF,
`flash_guard.py`) — futro is co-located next to the physical bench, so USB/serial
boards can be plugged into whichever machine is doing that day's work. raspi keeps
every capability it has today; nothing is removed. See `nodes/futro/setup-plan.md`
section 4.5 amendment and `nodes/futro/hardware.md`/`nodes/raspi/hardware.md` for the
full detail — this file's rules 2/3 are updated to match, not silently rewritten.

## Corrections vs. the old `INFRASTRUCTURE.md`

1. **Pi `mosquitto.service` is not running.** The old doc listed it ✅ active; live
   check shows it **failed since 2026-06-26** (see `nodes/raspi/status.md`). The ZAX
   field-unit MQTT path below assumes this broker is up — it currently isn't.
2. **Unit_B's real MQTT topic is `zax_E482C0`**, not `zax_3C3C3C` as previously
   recorded (confirmed against ZaxModbus's `units.yaml` and the MAC-tail naming
   convention every other unit follows).
3. **The old doc predates the 12-board ZaxModbus fleet** (added 2026-06-22, per
   `nodes/workstation/status.md`) — its data-flow map only covered the legacy
   ZaxEnergySurvey-era units (A/B/C) and the EnergyCalibrator bench (D). The
   `zaxmodbus-parser` pipeline below was missing entirely; added here.

## Data flow

```
LEGACY ZAX UNITS (A/B/C)                 ZAXMODBUS FLEET (12 boards)          BENCH (Unit D, cal_F07F8C)
  zax_E47730/E55008.../zax_3C boards       zax_<mac> x12                        box CTs + SDM630 ref meter
         |                                      |                                     |
         | MQTT (binary sec/min)                | MQTT                                | MQTT (sec bin / min JSON)
         v                                      v                                     v
  Pi broker :1883 (.225)          [see: currently FAILED]           WS broker :1883 (.11) <---+
         |                                      |                                     |        |
         | (WS subscribes remotely)             | (WS subscribes remotely)            |        |
         v                                      v                                     v        |
   zax-parser (WS)                    zaxmodbus-parser (WS)              cal_collector (WS)    |
         |                                      |                              |               |
         v                                      v                          SQLite              |
   InfluxDB :8086 -----------------------------------------------------> cal_data.db      cal-parser (WS)
   (org zax; buckets zaxenergy, zaxmodbus)                                   |                  |
         |                                                              cal_reports :8080        |
         +------------------------------- Grafana :3000 -----------------------------------------+

  Modbus (separate from MQTT): ZaxModbus fleet also polled via Pi's RS-485
  (/dev/ttyUSB0) -> zaxmodbus-poller -> InfluxDB zaxmodbus bucket (redundant path to
  the MQTT one above, per ZaxModbus's own dual-transport design)

  Disabled: zax-bridge -> zax/json -> zax-influx (local WS broker, no publisher,
  superseded by zax-parser; confirmed still inactive+disabled live 2026-07-21)
```

- **Legacy ZAX path (A/B/C):** units → Pi broker → `zax-parser` (WS, remote-subscribed)
  → InfluxDB `zaxenergy` → Grafana. **Currently broken end-to-end** — the Pi broker
  it depends on is down (see correction 1).
- **ZaxModbus fleet path (12 boards):** units → WS broker → `zaxmodbus-parser` →
  InfluxDB `zaxmodbus` → Grafana, **plus** a parallel Modbus/RS-485 path via the Pi.
- **Bench path (Unit D):** WS broker → `cal_collector` (→ SQLite → `cal_reports`
  PDF/web) and `cal-parser` (→ InfluxDB → Grafana).
- Both brokers anonymous on `:1883`.

## Units (publishers)

| Unit | IP | MQTT topic | Publishes to |
|---|---|---|---|
| Unit A | 192.168.110.152 | `zax_E47730` | Pi broker (currently down) |
| Unit C | 192.168.110.125 | `zax_73DA28` | Pi broker (currently down) |
| Unit B | 192.168.110.76 | `zax_E482C0` | Pi broker (currently down; field unit, user-managed, may be offline anyway) |
| Unit D (bench) | 192.168.110.104 | `cal_F07F8C` | WS broker |
| ZaxModbus fleet (Board_01–12) | .121–.131 range | `zax_<mac>` per board | WS broker |

## Operating rules

1. **New permanent/production service → the Workstation node**, via `ssh ws`. Update
   `nodes/workstation/status.md` in the same commit.
2. **Serial-attached work → whichever node the hardware is physically plugged into.**
   USB serial, GPIO, RS-485 work needs the board physically connected — raspi holds
   the permanent bench (Units A-D, RS-485 bus); futro (co-located) can take a board's
   USB cable for ad-hoc local dev. This is still a physical-cabling constraint, just no
   longer a raspi-exclusive one (amended 2026-07-22, see above).
3. **Firmware build works on either raspi or futro** (both carry the Arduino toolchain
   + ESP-IDF). **Flashing/serial-monitor works on whichever node the board is currently
   plugged into.** `boards.json` stays single-authority on raspi
   (`/home/pi/boards.json`) — futro's `flash_guard.py` reaches it over an `sshfs`
   mount, never a local copy, so the catalog never has two independently-writable
   copies (amended 2026-07-22, see above).
4. **Brokers:** WS broker is the permanent one. The Pi broker exists only for the
   legacy ZAX field units — and is currently down (correction 1); don't add new
   publishers to it regardless of whether it's fixed.
5. **Data-safety for any cutover:** parallel-run → verify stores agree → switch
   publisher → decommission old path. Never tear down the old path first.
6. **Driving another node:** direct SSH (`ssh ws`, and whatever alias the Futro gets
   once it exists) is the default. `COORDINATION.md`'s GitHub task-spec hand-off is the
   fallback for work that must run in a Claude session *on* that node.
7. **Coordinator role is a field, not a fact:** whichever node is marked `role:
   coordinator` in `nodes/INDEX.md` drives the others — don't hardcode "the Pi does X"
   in new docs; reference the index instead (see `COORDINATION.md`).
