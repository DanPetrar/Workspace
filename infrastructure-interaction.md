# Infrastructure Interaction — Fleet-Wide Data Flow & Operating Rules

Successor to the old `Workstation` repo's `INFRASTRUCTURE.md` sections 2–3. Per-node
facts (what each machine runs) live in `nodes/<node>/status.md`; this file owns the
**cross-node** picture — who talks to whom, and the standing rules for where new work
goes.

_Verified live 2026-08-06._ The old file was last verified 2026-06-03 and had drifted
in three ways found during the 2026-07-21 rewrite (see corrections below) — re-verify
this file periodically the same way, don't assume it stays accurate on its own.

**2026-08-06 correction:** the 2026-07-21 rewrite's own "Pi broker (currently FAILED)"
framing was itself already wrong when written — `zax-parser` has connected to
`BROKER_HOST="localhost"` on the Workstation since 2026-06-24, a month before that
verification pass, which checked Pi mosquitto's `systemctl` status but never re-checked
`zax-parser`'s actual broker target. There is no Pi-relay hop in the live data path and
hasn't been since 2026-06-24 — confirmed again today alongside the 192.168.110.x →
192.168.20.x network migration cleanup (also fixed here: `zaxmodbus-parser` was found to
independently confirm the same thing — both parsers connect to `localhost:1883` on the
Workstation, nothing subscribes to Pi's broker).

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
ZAX UNITS A/B/C/D                        ZAXMODBUS FIELD FLEET (Board_01-12)   BENCH (Unit_D, cal_F07F8C)
  zax_E47730/E482C0/73DA28/F07F8C          zax_<mac> x12                        box CTs + SDM630 ref meter
         |                                      |                                     |
         | MQTT (binary sec/min)                | MQTT                                | MQTT (sec bin / min JSON)
         v                                      v                                     v
                        WS broker  mosquitto :1883  (192.168.20.11)  <-------------------+
         |                                      |                                     |
         v                                      v                                     v
   zax-parser (localhost)            zaxmodbus-parser (localhost)      cal_collector (localhost)
         |                                      |                              |
         v                                      v                          SQLite
   InfluxDB :8086 -----------------------------------------------------> cal_data.db      cal-parser (localhost)
   (org zax; buckets zaxenergy, zaxmodbus)                                   |                  |
         |                                                              cal_reports :8080        |
         +------------------------------- Grafana :3000 -----------------------------------------+

  Modbus (separate from MQTT, ad-hoc not persistent): ZaxModbus bench units also
  pollable via Pi's RS-485 (/dev/ttyUSB0, /home/pi/zaxmodbus_modbus_poller.py) ->
  InfluxDB zaxmodbus bucket directly (redundant path to the MQTT one above, per
  ZaxModbus's own dual-transport design) — verified 2026-08-06: not a running
  service/cron, run manually for test/verification sessions only.

  Disabled: zax-bridge -> zax/json -> zax-influx (local WS broker, no publisher,
  superseded by zax-parser; confirmed still inactive+disabled live 2026-08-06)
```

- **ZAX path (Units A/B/C/D):** units → **Workstation broker directly** → `zax-parser`
  (localhost-subscribed) → InfluxDB `zaxenergy` → Grafana. No Pi-relay hop — see the
  2026-08-06 correction above.
- **ZaxModbus field-fleet path (Board_01–12):** units → Workstation broker →
  `zaxmodbus-parser` → InfluxDB `zaxmodbus` → Grafana, **plus** an ad-hoc (not
  persistent) parallel Modbus/RS-485 verification path via the Pi's local bench units.
- **Bench path (Unit_D):** WS broker → `cal_collector` (→ SQLite → `cal_reports`
  PDF/web) and `cal-parser` (→ InfluxDB → Grafana). Note `zax_F07F8C` (ZaxModbus,
  Unit_D) and `cal_F07F8C` (EnergyCalibrator bench) are the **same physical board**
  (MAC suffix `F07F8C`), repurposed between projects — not two different units.
- Both brokers anonymous on `:1883`. The Workstation broker is the sole production
  path for every unit above; Pi's broker is local dev/test-only (see Operating rule 4).

## Units (publishers)

| Unit | IP | MQTT topic | Publishes to |
|---|---|---|---|
| Unit_A | 192.168.20.231 (reserved) | `zax_E47730` | WS broker directly |
| Unit_B | 192.168.20.232 (reserved) | `zax_E482C0` | WS broker directly |
| Unit_C | 192.168.20.233 (reserved) | `zax_73DA28` | WS broker directly |
| Unit_D (bench) | 192.168.20.234 (reserved) | `zax_F07F8C` / `cal_F07F8C` | WS broker directly (dual role, see note above) |
| ZaxModbus field fleet (Board_01–12) | not verified here — field-deployed, not on this bench LAN; see `boards.json`/ZaxModbus project docs | `zax_<mac>` per board | WS broker directly |

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
4. **Brokers:** the Workstation broker is the sole production broker for every unit
   above. Pi's own broker is local dev/test-only (verified 2026-08-06: zero connected
   clients) — don't add production publishers to it.
5. **Data-safety for any cutover:** parallel-run → verify stores agree → switch
   publisher → decommission old path. Never tear down the old path first.
6. **Driving another node:** direct SSH (`ssh ws`, `ssh futro`) is the default.
   `COORDINATION.md`'s GitHub task-spec hand-off is the fallback for work that must run
   in a Claude session *on* that node.
7. **Coordinator role is a field, not a fact:** whichever node is marked `role:
   coordinator` in `nodes/INDEX.md` drives the others — don't hardcode "the Pi does X"
   in new docs; reference the index instead (see `COORDINATION.md`).
