# Test Units — Local Bench

**Authority note:** `/home/pi/boards.json` on the raspi node is the sole authority for
board identity, firmware, version, and last-flash time — it's read live by
`flash_guard.py` before every USB/OTA flash to prevent bricking or wrong-firmware
flashes. **This file never duplicates those fields.** It documents bench role,
physical/wiring location, and purpose only, keyed by MAC to cross-reference the
`boards.json` entry.

Scope: the units that remain **permanently on the local bench** (per the user's
original direction), not the wider ZaxModbus field fleet (Board_01–12) or other
units in `boards.json` whose physical location isn't confirmed as bench-resident.

## Unit_A

- **MAC:** `3c:0f:02:e4:77:30` — cross-reference `boards.json` for current
  firmware/version
- **Board:** Waveshare S3-Zero
- **Bench role:** primary ZaxModbus test target (D2). Dual-cabled: Pi USB (CDC/JTAG
  serial) + real measurement box (GPIO5/GND). Also on the shared RS-485 bus.
- **Modbus:** slave address 20
- **Purpose:** the main hardware-in-the-loop target for ZaxModbus firmware
  development/test (Phase 0–7 test platform, destructive-test sacrificial unit)

## Unit_B

- **MAC:** `3c:0f:02:e4:82:c0`
- **Board:** Waveshare S3-Zero
- **Bench role:** **canary — unselectable by the ZaxModbus test platform** (deliberate
  safety rule; never touched by automated tests). Box-cabled, Modbus off.
- **Purpose:** soak-tested reference unit, kept stable intentionally.

## Unit_C

- **MAC:** `10:20:ba:73:da:28`
- **Board:** LilyGO T7-S3
- **Bench role:** secondary ZaxModbus test target (D2), the LilyGO board-type
  representative. On the shared RS-485 bus.
- **Modbus:** slave address 22
- **Purpose:** covers LilyGO-specific behavior (larger PSRAM/flash, different LED
  scheme) the S3-Zero target can't exercise.

## Unit_D

- **MAC:** `80:b5:4e:f0:7f:8c`
- **Board:** LilyGO T7-S3
- **Bench role:** present and on the bus, not a formal automated-test target (D2) —
  used for concurrent multi-unit soak/commission testing alongside A/C.
- **Modbus:** slave address 21
- **Purpose:** third bench unit for multi-unit bus-sharing validation.

## Other `boards.json` entries (not covered here)

- **Board_01–12** — the deployed ZaxModbus field fleet, not local-bench units. Tracked
  in `boards.json` only; not duplicated in this bench-scoped file.
- **Unit_E, Unit_F** — present in `boards.json` (Unit_F runs EnergyCalibrator firmware,
  a different project) but their current physical bench presence wasn't confirmed live
  as part of this build — add an entry here once confirmed, don't assume.

## Future units

Add a new `## Unit_<name>` section here (role/wiring/purpose, no firmware fields) when
a new unit joins the permanent local bench.
