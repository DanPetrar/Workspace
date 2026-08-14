# futro — Phase 2 Plan: Development-Machine Validation

**Status: in progress.** Phase 1 (coordinator-role transfer, raspi → futro) is done and
verified — see `nodes/futro/setup-plan.md` §5, all 9 checks PASS as of 2026-08-06. This
document covers Phase 2: proving futro can be the machine where builds *and flashes*
actually happen, not just where compiles run and coordination is hosted.

## Amendment 2026-08-14 — board swapped to Unit_A; move + RS-485 already done live

Two prior planning rounds picked Unit_D as the lower-risk test board and treated the
physical move, the USB round trip, and RS-485 validation as future steps behind safety
checklists. Reality has moved ahead of that plan:

- **Board is Unit_A, not Unit_D** — direct user instruction, overriding this plan's
  earlier recommendation. Re-examined below (§ Step 1): the specific risk that made Unit_D
  look safer (box wiring, harder to disconnect/reconnect cleanly) turns out not to apply
  to Unit_A either — **Unit_A was never connected to the box.** Only USB (now → futro) and
  the RS-485 adapter are wired. The `role: target` risk (this is the automated s3zero
  test-platform target) still stands and was not cleared through the checklist this plan
  had written for it — see § Step 1 for what that means in hindsight.
- **The physical move already happened.** Unit_A and a CH340 RS-485-to-USB adapter are
  both connected to futro right now. raspi's `/dev/serial/by-id/` is confirmed empty —
  nothing USB-serial is left plugged in there.
- **The plan's own flagged gap — "PASS only proves USB-CDC flash, not RS-485/Modbus from
  futro" — is now closed, verified live, this session.** See § Step 3.5 below. The
  strikethrough markers through this document mark exactly what that resolved.
- **Data source is Demo-Mode, not the box**, for all of this — a pre-approved approach
  (`Doc/WISHLIST.md`, 2026-07-16 scope decision: *"OK — tests that require a USB
  connection to the Pi. In that configuration the BOX is not attached, so Demo-Mode
  supplies the data. This approach is approved."*). `demo_en` is a real `Config.h`/NVS
  flag (`POST /api/config {"demo_en":true}`), not an improvised workaround.

Steps 1–1.3 below are now **historical** — record of what was (and wasn't) checked before
the move, not a gate that still needs clearing. Steps 2 and 3 are still ahead: the cable
sanity check and the flash+smoke test itself have not been run against this real
connection yet.

**Decided 2026-08-14:** Unit_A stays on futro for as long as Phase 2 testing needs it —
see § Step 4. Recorded in `nodes/futro/status.md`.

---

## Step 1 — Board selection and move (DONE 2026-08-14 — historical record)

### 1.0 What Unit_A actually is (re-verified fresh this round, not reused)

| | Unit_A |
|---|---|
| Board | `waveshare_s3zero` |
| Firmware | ZaxModbus v1.1.19, `validated: true` |
| Test-platform role | `role: target` — the D2-approved automated test target for the s3zero line, per `units.yaml` |
| `usb_port` registered in `units.yaml` | Yes — `.../usb-Espressif_USB_JTAG_serial_debug_unit_3C:0F:02:E4:77:30-if00`, i.e. `gate.py`/pytest excursions on the s3zero line drive this exact device |
| Box wiring | **Not connected.** `units.yaml`'s notes describe a 2026-07-18 dual-cabling (Pi-USB CDC + box GND/GPIO5), but per the user's correction this round, only the USB/RS-485 side is actually live — the box side was never hooked up. The box-wiring risk this plan flagged when comparing Unit_A vs. Unit_D does not apply. |

**What this changes from the prior recommendation:** the two reasons Unit_D looked safer
were (a) box wiring made Unit_A harder to disconnect/reconnect cleanly, and (b) Unit_A's
`role: target` status meant `gate.py` could sweep it into a run with no per-unit exclude.
(a) turns out to be moot — there's no box connection to worry about. (b) still stands and
is the one real residual risk from this choice; see 1.1.

### 1.1 Pre-disconnect safety check — what happened, in hindsight

This plan had written a pre-disconnect checklist (confirm no active `gate.py`/pytest run,
confirm role, snapshot `boards.json` state, confirm live bus response) for exactly this
kind of move. The move happened before that checklist could run against it. Reconstructing
after the fact:

- **Active test-platform run at move time:** not checked live (no `ps aux` snapshot was
  taken before disconnecting). No trace of a run was found afterward in
  `tools/zaxtest/`'s logs or `.pytest_cache` timestamps, which is consistent with (but
  doesn't prove) nothing having been running. Treat this as an unconfirmed gap, not a
  confirmed-clean check — if a `gate.py` run on the s3zero line ever comes back with an
  unexplained mid-run failure from around this session's start time, this is the first
  thing to suspect.
- **`role: target` state:** confirmed above (1.0) via a fresh `units.yaml` read.
- **`boards.json` pre-move snapshot:** ZaxModbus v1.1.19, `validated: true`,
  `last_flash: 2026-08-07T21:00:54`, `last_ota: 2026-08-06` — this is the state to compare
  against once Step 3 runs.

**Lesson for the rest of this plan, not a redo:** don't re-run the move. If Unit_A ever
needs to go back to the bench and come back to futro again later, do use the checklist
this section describes — it just didn't gate this particular move.

### 1.2 Physical move (confirmed complete)

- Unit_A: `/dev/ttyACM0` on futro, MAC-matched via
  `/dev/serial/by-id/usb-Espressif_USB_JTAG_serial_debug_unit_3C:0F:02:E4:77:30-if00` →
  confirms this is genuinely Unit_A, not a different board on the same port number.
- RS-485 adapter (CH340-based): `/dev/ttyUSB0` on futro.
- raspi side: `/dev/serial/by-id/` no longer exists (empty) — nothing USB-serial remains
  plugged in there.

**Success criterion:** PASS — both devices enumerate correctly on futro by exact MAC/type
match, and raspi's side is confirmed clear. No open item here.

### 1.3 Outage log

Unit_A left the s3zero test-platform target slot and the RS-485 bus for the duration of
this work. **Done** — `nodes/futro/status.md` has a 2026-08-14 entry: unit name, the fact
that exact disconnect time wasn't logged in the moment (see 1.1), reason ("Phase 2
USB+RS-485 round-trip validation on futro"), and the Step 4 decision ("staying on futro
for as long as Phase 2 needs it," no return date set).

---

## Step 2 — USB cable/port sanity check (pre-flight, before any flash) — NOT YET RUN

Still ahead. House convention (`feedback_usb_cable_verify`): a MAC-read alone doesn't
expose a marginal cable or port; a 4 KB read-flash does. This is specifically about the
ESP flash-target port (`/dev/ttyACM0`) — separate from the RS-485 adapter, which has
already been functionally exercised (§ Step 3.5) but never had this specific cable-health
check run against it either.

**Do:**
```
ssh futro 'python3 -m esptool --port /dev/ttyACM0 read_flash 0x0 4096 /tmp/futro_cable_test.bin'
```

**Check:** command exits 0 and `/tmp/futro_cable_test.bin` is exactly 4096 bytes.
**Success criterion:** PASS on clean exit + correct file size.

**If FAIL** — work through in order:
1. Try a different physical cable — short, known data-capable (not charge-only).
2. Try a different futro USB port — prefer a rear/direct port over a front-panel hub.
3. Re-run the same `read_flash` command after each swap.
4. If it still fails after both swaps, treat this as a real futro port/driver issue —
   stop here, don't carry an unresolved failure into Step 3.

---

## Step 3 — Build → flash → serial-monitor → smoke-test round trip — DONE 2026-08-14, PASS (amended criterion)

Run against Unit_A via `ZaxModbus/arduino/build_s3zero.sh /dev/ttyACM0`. Two real,
previously-unknown bugs surfaced and were fixed en route (both were "works on raspi,
breaks on any other machine" hardcoded-path bugs, committed and synced to futro before
re-running):

1. `build_s3zero.sh`/`build_lilygo.sh` hardcoded `source /home/pi/esp/esp-idf/export.sh`
   → fixed to `$HOME/esp/esp-idf/export.sh` (`ZaxModbus` commit `48c5c18`).
2. `identity_guard.py` (in `ZaxCommon`) hardcoded the `ESPTOOL` glob to `/home/pi/...` →
   fixed via `os.path.expanduser("~/...")` (`ZaxCommon` commit `f96de49`).
3. Also needed: invoking the build script over `ssh futro '...'` non-interactively skips
   `.bashrc`/`.profile`, so `~/.local/bin` (where `arduino-cli` lives) isn't on `PATH`.
   Not a script bug — an invocation detail. Use `ssh futro 'bash -lc "..."'` (login shell)
   for any future futro build/flash command run this way.

With those fixed: compile succeeded, `identity_guard.py` matched image+device, `esptool`
wrote and verified all 4 flash regions cleanly, board reset.

**The literal serial smoke-test then FAILED** — `[BOOT]` line never appeared,
`/tmp/arduino_smoke_ZaxModbus_s3zero.log` came back a 0-byte file. Investigated rather
than accepted at face value:
- `/api/sysinfo` immediately after showed `fw_version: 1.1.19`, `boot_count`
  incremented 90→92 (matching flash+reset), `mqtt_connected: true`. `/api/data` showed
  live Demo-Mode values. **The board is fully healthy — this is a capture problem, not a
  flash or boot defect.**
- Live-diagnosed (Fable, this session): a real `/restart`-triggered reboot with a fresh
  10s capture starting 1s after the trigger still got 0 bytes — not a "missed the early
  banner" timing issue. `dmesg` showed zero USB disconnect/reconnect events around the
  reset — the device does not actually re-enumerate on futro's USB stack, contradicting
  the assumption `build_s3zero.sh`'s own comment was tuned against (on raspi). An
  explicit DTR+RTS `pyserial` open (bypassing `cat` entirely) also got 0 bytes, ruling
  out a DTR-assertion gap in `cat`'s bare `open()`.
- **Conclusion: a genuine, unresolved USB-CDC gap specific to futro**, for this
  peripheral class specifically (the ESP32-S3's native silicon USB-Serial/JTAG
  peripheral / Arduino `HWCDC`, `CDCOnBoot=cdc`) — `esptool` reaches the same port fine
  via the ROM-bootloader UART (a different code path), but the *running app's* console
  endpoint delivers nothing to futro's kernel under every method tried. Root-causing it
  needs USB-protocol tracing (`usbmon`) — disproportionate for what this check exists to
  prove, so **left open and tracked** (see `nodes/futro/status.md`), not silently patched
  around.

**Amended success criterion for Step 3 on futro:** per `feedback_post_flash_smoke_test`,
a literal `SMOKE TEST: PASS` line is still the bar everywhere it's achievable — this
amendment is scoped to futro's confirmed CDC-capture gap specifically, not a general
loosening of that convention. When the serial capture is empty AND the board's
own USB-CDC peripheral is the confirmed cause (not a fresh, undiagnosed failure), PASS
instead requires ALL of: `fw_version` matches the version just flashed, `boot_count`
incremented across the flash, and `mqtt_connected: true` — all via `/api/sysinfo`. This
is not a weaker check, it's a different, equally-direct one; it does not apply if the
board fails to come up on WiFi/HTTP at all, which would need the normal FAIL triage.

**Original text below, kept for reference on any board/setup where serial capture does
work (e.g. raspi, or futro once the CDC gap is fixed):**

**Before running:**
- Flash the **same version Unit_A is already running (v1.1.19)**, not a new one — proves
  the toolchain mechanism without changing what's functionally on a live test-platform
  target. A normal (non-`FIRST_FLASH`) reflash doesn't erase NVS, so `demo_en` should
  persist through it — worth confirming, not assuming (see the check below).
- **Demo-Mode is already on** (enabled this session, § Step 3.5). Don't toggle it off and
  back on "to be safe" — that's an untested extra step with no purpose here. If Step 3's
  smoke test shows `demo_en` reverted to `false` post-flash, that's useful information
  (NVS didn't survive the reflash as expected) — note it and re-enable, don't silently
  paper over it.

**Do:**
```
ssh futro 'cd ~/ZaxModbus/arduino && bash build_s3zero.sh /dev/ttyACM0'
```
Let it run to completion — flash, `identity_guard.py` check, reset, smoke capture.

**Check:** tail the script's own smoke log line, e.g.
`ssh futro 'tail -5 /tmp/arduino_smoke_ZaxModbus_s3zero.log'` plus the script's final
stdout line.
**Success criterion:** PASS only on a literal `----- SMOKE TEST: PASS -----` line (per
`feedback_post_flash_smoke_test` — never report success without this) — **unless the
futro CDC-capture gap above is the confirmed cause of an empty log, in which case use the
amended `/api/sysinfo` criterion instead.**

**What PASS proves now vs. before:** the RS-485 dongle is present this time (`/dev/ttyUSB0`
exists), so the build script's own Modbus probe (FC03 slave-address read, then FC04 Phase R
voltage) will actually execute instead of skipping with a WARNING. Because Demo-Mode
supplies non-zero moving values, the "V == 0.0 → FAIL (no box connected?)" branch should
not trip — that branch exists for the *bench's* master-live assumption, and Demo-Mode is
this test's approved substitute for it. If it does trip, don't assume Demo-Mode failed —
check `demo_en` state first (see above) before treating it as a real defect.

**If FAIL** — triage in order: `identity_guard.py` rejection → `[BOOT]` line missing →
Modbus block failing (check `demo_en` first, per above, before assuming a futro defect) →
re-confirm Step 2 passed on this exact cable/port.

---

## Step 3.5 — RS-485/Modbus from futro's own adapter (DONE 2026-08-14 — resolved)

This closes the gap the previous two plan revisions flagged and left open: *"futro has no
RS-485-to-USB dongle wired up yet... a PASS [in Step 3] proves USB-CDC flash + boot +
config from futro. It does NOT prove RS-485/Modbus works from futro."*
~~That caveat stands.~~ **RESOLVED 2026-08-14, verified live:**

1. `pyserial` was missing on futro (`ModuleNotFoundError` on first attempt) — installed via
   `sudo apt-get install python3-serial` (matches how raspi satisfies the same dependency;
   avoided fighting pip's PEP 668 externally-managed-environment block).
2. Enabled Demo-Mode on Unit_A: `curl -X POST http://192.168.20.231/api/config -d
   '{"demo_en":true}'` → `{"msg":"Saved"}`; `/api/data` then showed real moving per-phase
   V/A/W/Hz/PF values.
3. Read the same live data over Modbus **through futro's own RS-485 adapter**:
   `ModbusClient(port="/dev/ttyUSB0").read_sec(20)` (slave 20 = Unit_A, per `units.yaml`)
   — got a real, non-zero, moving record (ts=1786711173, phase R/S/T voltage ~229–230 V,
   current ~0.9–1.5 A). Confirmed twice: once *before* Demo-Mode was on (all-zeros,
   ts=0 — proving the read mechanism itself works and isn't echoing stale/cached data),
   once *after* (real values) — a genuine negative-then-positive control, not just one
   reading taken on faith.

**Scope limit worth keeping in mind for Step 5:** this proves point-to-point RS-485 read
from futro against one device on one dongle. The permanent bench runs a multi-drop RS-485
bus with up to 4 units on it simultaneously — this test doesn't replicate that topology.
Treat this as "the RS-485 mechanism works from futro," not "the full 4-unit bench bus is
proven to work from futro unchanged."

**Success criterion:** PASS — met. Real Modbus data read from futro's own adapter,
negative control included. No longer an open item.

---

## Step 4 — What happens to Unit_A after Step 3? (DECIDED 2026-08-14)

**User decision: Option B — Unit_A stays on futro for as long as Phase 2 testing needs
it.** Not a fixed-duration loan; no return date set. Recorded in
`nodes/futro/status.md` (2026-08-14 entry).

Consequence, explicit rather than implicit: the s3zero line's `gate.py --board s3zero`
automated test target (`role: target` in `units.yaml`) is unavailable on raspi and
Unit_A does not participate in the permanent bench's RS-485 bus for the duration. If a
`gate.py` run on the s3zero line is needed for unrelated work before Unit_A comes back,
that's a real scheduling conflict to raise with the user, not something to route around
silently.

**Superseded — Option A (return to raspi's bench) was not chosen.** Kept below for
reference in case the decision is revisited later, not as a live step:
~~1. Reconnect Unit_A at raspi exactly where it was (USB + RS-485).~~
~~2. Confirm bus response: `ssh bench 'python3 ~/ZaxModbus/tools/board_test.py 20 zax_E47730/sec --duration 30'` — expect real records.~~
~~3. Confirm `boards.json` version still reads `1.1.19`.~~
~~4. Decide whether to leave `demo_en:true` or turn it back off.~~
~~5. Close out the Step 1.3 outage log entry with the reconnect timestamp.~~

**Success criterion:** PASS — met. Decision made and recorded in `nodes/futro/status.md`,
not left ambiguous.

---

## Step 4.5 — Multi-drop + duration validation of futro's RS-485 path — NOT YET RUN

Step 3.5 proved point-to-point RS-485 from futro against one device with a handful of
single reads. Two real gaps remain before Step 5/6 can be decided with confidence: (a)
does futro's one adapter handle **multiple slaves sharing the same bus** (the bench's
actual topology), and (b) does it hold up over **sustained polling**, not a handful of
one-shot reads. This step closes both, and folds in a second board type's flash path
plus a cross-machine `boards.json`-visibility check while a second unit is on hand
anyway.

**Precondition — locate and connect Unit_D (not assumed available):** Unit_D is not
currently visible on futro or raspi (`/dev/serial/by-id/` empty on both, checked
2026-08-14). **Ask the user to physically locate Unit_D and connect it to futro, sharing
futro's existing RS-485 adapter/bus with Unit_A** (same A/B differential pair — a second
dongle would not test multi-drop, it would just be two more single-device tests). Before
disconnecting it from wherever it currently is, run the same pre-disconnect checklist
Step 1.1 used for Unit_A (active `gate.py`/pytest check, confirm `role: bench` hasn't
changed, snapshot its `boards.json` entry) — it wasn't gated last time; it should be
this time.

**Check:** `ssh futro 'ls /dev/serial/by-id/'` shows both the existing Unit_A entry and a
new LilyGO entry; `ssh futro 'ls /dev/ttyACM*'` shows a second ACM device (LilyGO's CDC
is a separate port from the shared `/dev/ttyUSB0` RS-485 adapter both units talk over).
**Success criterion:** PASS once both are physically present and enumerated. FAIL — stop
here — if Unit_D can't be located/connected; this step can't proceed without it.

### 4.5.1 — Flash Unit_D from futro (second board type + boards.json cross-visibility) — DONE 2026-08-14, PASS (after a real fix)

Step 3 only ever exercised `build_s3zero.sh`. `build_lilygo.sh` shares the same two
hardcoded-path bugs already fixed (`$HOME` substitution, `identity_guard.py`
expanduser) but has never actually been run end-to-end from futro. Flash the **same
version already on Unit_D (v1.1.19)**, matching Step 3's non-destructive convention,
then enable Demo-Mode the same approved way (`POST /api/config {"demo_en":true}`).

**Do:**
```
ssh futro 'bash -lc "cd ~/ZaxModbus/arduino && bash build_lilygo.sh /dev/ttyACM1"'
```
(port will differ from Unit_A's — confirm via the precondition check above.)

**Check:** same amended criterion as Step 3 — `/api/sysinfo` `fw_version` match +
`boot_count` incremented + `mqtt_connected:true` (the futro CDC-capture gap may or may
not reproduce here — LilyGO's CDC implementation differs from the S3-Zero's native
peripheral, so don't assume the Step 3 finding transfers; note whichever way it goes).
**Then, from raspi (not futro):**
`python3 -c "import json; print(json.load(open('/home/pi/boards.json'))['80:b5:4e:f0:7f:8c'])"`
— confirms the write `flash_guard.py` just made on futro is immediately visible on
raspi's own copy of the file, not just through futro's `sshfs` mount looking at itself.

**Success criterion:** PASS if the boot-health check passes AND raspi's own read shows
the updated `last_flash` timestamp within a few seconds of the flash completing — the
concrete evidence Step 6 needs (a real write, originating from futro, checked for
visibility from the *other* side), not just Step 3's single same-machine confirmation.

**Actual result: boot-health check PASSED cleanly — literal `SMOKE TEST: PASS`,
including the Modbus RTU check via futro's own adapter (LilyGO's CDC worked fine on
futro, unlike the S3-Zero's unresolved gap — confirms that finding doesn't transfer
across board types, as flagged above). The cross-visibility check FAILED initially, and
that failure uncovered a real, three-week-old infrastructure bug, not a fluke:**

`~/boards.json` on futro is a symlink through the `sshfs` mount to
`bench:/home/pi/shared/boards.json` — which turned out to be a **separate, independent,
stale copy** of the real catalog, not a link to `/home/pi/boards.json`. Created
2026-07-22 (futro's bring-up date) and never reconciled since — every futro-originated
`flash_guard.py` write for over three weeks landed in this dead-end copy, invisible to
raspi's own tooling. Confirmed via a 114-line diff between the two files at time of
discovery.

**Fixed same session (Fable):** merged the one genuinely-newer entry (Unit_D's real
`last_flash` from this flash, `2026-08-14T17:31:32` — everything else in the stale copy
was equal-or-older; `Board_13/14/15` only ever existed in the real file, so nothing else
needed merging), then corrected the topology — moved the real file *into* the exported
`shared/` directory and symlinked `/home/pi/boards.json` down into it (not the reverse;
an outward-pointing symlink from inside an `sshfs`-exported directory doesn't resolve
correctly across the mount boundary — confirmed live, that direction failed with a
`PermissionError` on the first attempt). Backup of the pre-fix real file kept at
`/home/pi/boards.json.bak-20260814-presymlinkfix`. Independently verified after the fix:
21/21 board entries preserved with no other data loss, and futro's own read now matches
raspi's real file exactly, both directions.

**Success criterion: PASS, but only after the fix — record it that way, not as a clean
first-time pass.** `flash_guard.py`'s writer (`open(CATALOG, "w")`) was confirmed to
write through a symlink safely (no tempfile+rename that could silently re-break this),
so the fix should hold for future writes without re-occurring.

**Why not "flash N times" for fluke-proofing instead:** esptool's write+verify is a
deterministic checksum-verified write, not the kind of operation that fails
intermittently the way the CDC byte-stream turned out to be — repeating the identical
operation mostly re-confirms the same result. A second flash of a *different*
board/build-script path is a better use of one more flash cycle than repeating the same
one.

### 4.5.2 — Multi-drop correctness check (both units, one bus, one adapter)

**Do:**
```
ssh futro 'python3 -c "
from zaxtest.modbus import ModbusClient
bus = ModbusClient(port=\"/dev/ttyUSB0\")
a = bus.read_sec(20)
d = bus.read_sec(21)
print(\"Unit_A:\", a)
print(\"Unit_D:\", d)
"'
```
**Check:** both calls return a populated dict (not `None`), and — critically — each
record's values are plausible for *that* unit (not identical to each other, which would
indicate address confusion/cross-talk rather than two genuinely distinct reads).
**Success criterion:** PASS if both units respond correctly and distinctly on the shared
bus. FAIL — and stop before 4.5.3 — on a timeout, a `None`, or duplicate/cross-talked
data; that's a real multi-drop defect (bus contention, termination/biasing, address
collision) worth its own investigation, not something a longer soak will clarify.

### 4.5.3 — Duration soak (4 hours, round-robin, both units)

**Duration justified from the project's own precedent, not invented:**
`tools/zaxtest/soak_l3.py`'s own default is `--hours 4` ("the gate for buffer/memory
changes"), and the closest prior real-world case —
`Doc/bringup-test-plan-s3zero-lilygo.md`'s 4-hour concurrent multi-unit soak, all
sharing one RS-485 bus — ran 61,111 poll cycles with zero bus contention (Unit_A
61,111/61,111, Unit_D 61,029/61,111 = 99.9%). Matching that duration here is directly
comparable evidence, not a new number picked for this plan.

**Not using `soak_l3.py` itself:** its `load_units()` has no unit-filter flag and would
pull in Unit_C (not physically available here), and its snapshot-cycle assertions
assume production data flow that `demo_en` explicitly disables
(`ZaxModbus.ino:1424-1428`) — running it unmodified would produce failures unrelated to
what this step is checking. Instead, reuse the same proven `ModbusClient` class in a
small round-robin loop, and borrow `soak_l3.py`'s own **99.5% Modbus floor**
(`MODBUS_FLOOR_PCT`) as the success bar, rather than inventing a new threshold.

**Do:** write a small standalone script on futro (cleaner than an inline SSH one-liner
three quoting-levels deep) —

```python
# ~/futro_multidrop_soak.py on futro
import time, json
from zaxtest.modbus import ModbusClient
SLAVES = {20: "Unit_A", 21: "Unit_D"}
bus = ModbusClient(port="/dev/ttyUSB0")
counts = {s: {"ok": 0, "fail": 0} for s in SLAVES}
log = open("/tmp/futro_multidrop_soak.jsonl", "w")
end = time.time() + 4 * 3600
while time.time() < end:
    for s in SLAVES:
        ok = bus.read_sec(s) is not None
        counts[s]["ok" if ok else "fail"] += 1
        log.write(json.dumps({"ts": time.time(), "slave": s, "ok": ok}) + "\n")
        log.flush()
    time.sleep(1)
for s, n in SLAVES.items():
    c = counts[s]
    pct = round(100 * c["ok"] / (c["ok"] + c["fail"]), 2)
    print(n, s, pct, c)
```

Run detached, matching `soak_l3.py`'s own documented pattern:
```
ssh futro 'cd ~/ZaxModbus/tools && nohup python3 ~/futro_multidrop_soak.py > /tmp/futro_multidrop_soak_summary.log 2>&1 &'
```

**Check, ~4h later:** `ssh futro 'cat /tmp/futro_multidrop_soak_summary.log'` — per-unit
success percentage and raw counts.
**Success criterion:** PASS if both units individually hold **≥99.5%** successful reads
over the run (matching `soak_l3.py`'s own floor). FAIL if either unit drops meaningfully
below that, or if failures cluster in simultaneous-both-units rounds late in the run (an
adapter/bus-level problem, not a single unit being flaky) — check
`/tmp/futro_multidrop_soak.jsonl` for that pattern specifically before concluding
PASS/FAIL from the summary percentage alone.

**This resolves:** Step 5's checklist item 2 with 2 of 4 bench units, real multi-drop
electrical/protocol behavior over a real duration — not the literal full 4-unit bench.
Note that scope honestly in Step 5's decision record, don't overstate it as "the full
bench proven."

---

## Step 5 — Bench-location decision (Units A–D / RS-485, long-term)

Explicitly undecided per the user's constraints. Step 3.5 changes what's known here —
~~"Steps 1–4 prove futro's USB-CDC flash path works, not that RS-485/GPIO works from
futro"~~ **RESOLVED 2026-08-14** — RS-485 from futro is now verified working, with the
scope limit noted in Step 3.5 (single device, not the full multi-drop bus). Don't treat
that as "so the bench can just move now" — it's a real data point, not full proof at the
target scale.

**What the human should actually look at before recording this decision:**
1. Physical cable run: how long would the RS-485 trunk need to be if it moved to futro's
   location vs. staying at raspi's.
2. Multi-drop behavior at scale: Step 3.5 proved one device on one dongle from futro — the
   real bench runs up to 4 units on one bus. Worth a multi-unit test before trusting this
   for the full permanent bench, not just extrapolating from one board. **Addressed by
   Step 4.5** (pending execution) — real multi-drop (2 of 4 units) over a 4h window, not
   just point-to-point. Still not literally all 4 units simultaneously; note that gap
   explicitly in the decision record rather than treating 4.5 as full-scale proof.
3. Power/placement at the bench itself — does relocating change how Units A–D are powered
   or mounted, independent of which machine polls them.
4. Whether moving the bench interrupts anything currently running for longer than this
   session's Unit_A loan did — a permanent move is a bigger disruption.

**Do:** Human decision — stays wired to raspi, or physically moves to futro. Record the
choice and the reasoning (referencing the checklist above) in `nodes/futro/status.md` (or
`nodes/raspi/status.md`, whichever gains the bench).

**Check:** `grep -n "bench location" nodes/*/status.md` (or equivalent heading) after the
decision is written.
**Success criterion:** PASS if a status doc states the decision unambiguously (which
machine, as of what date, and whether the multi-drop-at-scale gap from item 2 above has
been tested or is still open). FAIL if the docs still say "undecided" — valid as a
long-term state, but then Step 7's cutover must say so explicitly rather than leaving it
implicit.

---

## Step 6 — `boards.json` authority decision

Currently single-authority on raspi, reached by futro via `sshfs`; nightly backup cron
(raspi → Workstation, 00:15) already covers the "irreplaceable SD-card state" risk
regardless of how this resolves.

~~Any earlier assumption in this plan or in `setup-plan.md` §5 check #8 that the `sshfs`
mount "already works" for futro↔raspi `boards.json` access meant a write actually lands
in the file raspi's own tooling reads.~~ **CORRECTED 2026-08-14 — that assumption was
false for over three weeks.** Check #8 verified the mount was *reachable* and
*readable*, not that a write round-trips correctly. Step 4.5.1 found the real bug: the
`sshfs`-exported directory on raspi (`/home/pi/shared/`) held an independent, stale copy
of `boards.json`, not a link to the real file — every futro-originated write since
2026-07-22 silently landed in a dead end. **Fixed 2026-08-14** (see Step 4.5.1 for full
detail): the real file now lives inside the exported directory with
`/home/pi/boards.json` symlinked down into it, and a write from futro is confirmed
(live, both by Fable's fix-verification and independently re-checked) to land correctly
and be immediately visible from raspi's own read. Treat this as now-working, verified
today — not as something that was always fine.

**What the human should actually look at before recording this decision:**
1. Current mount health from futro's side: `ssh futro 'mount | grep sshfs'` — confirm it's
   actually mounted and not silently stale (this broke once already, 2026-08-01 network
   migration, until fixed 2026-08-06).
2. Write frequency vs. read frequency: `boards.json` is written once per flash (rare,
   human-paced) and read constantly (every test-platform run, every `flash_guard.py`
   invocation) — this favors a single writer wherever flashing happens most often, which
   may shift if futro becomes the primary flashing machine.
3. Whichever way this goes, check the 00:15 backup cron's source path — if authority moves
   to futro, retarget the cron in the same change, not as a follow-up.
4. **Cross-machine write visibility** (Step 4.5.1): a futro-originated `boards.json`
   write, confirmed visible from raspi's own read within seconds — not just Step 3's
   single same-machine confirmation. This is closer to what "authority" actually needs
   proven than write *count*.

**Do:** Human decision — keep raspi as sole writer, or move the canonical file to futro
(raspi would then need the reverse mount, and the backup source would need to retarget).
Record the choice + reasoning in `nodes/futro/status.md`.

**Check:** `ssh futro 'ls -la ~/boards.json'` — PASS state is unambiguous either way
(symlink into `sshfs` mount = raspi stays authority; a real file = futro is now
authority, and raspi's copy must become the symlink instead).
**Success criterion:** PASS if exactly one machine holds the writable file and the other's
`boards.json` is verifiably a symlink/mount. FAIL if both machines have real,
independently-editable copies — if authority moves to futro, update the 00:15 backup
cron's source in the same change.

---

## Step 7 — Cutover criteria and rollback

Per the user's explicit constraint: raspi stays a safe fallback until Phase 2 is fully
validated — this step is not a decommission plan. Given the bench-location decision
(Step 5) may well leave the permanent bench on raspi indefinitely, "cutover" here means
*day-to-day development defaults to futro*, not that raspi's capability is removed.

**Do:** Once Steps 1–6 are all PASS, update `CLAUDE.md`'s machine-role note (both raspi
and futro) and `nodes/futro/status.md` to state futro is now the default development
machine for builds/flashes not tied to the permanent bench's physical cabling. Leave
raspi's toolchain, `flash_guard.py`, and (if Step 6 kept it there) `boards.json`
untouched and functional — no uninstall, no capability removal.

**Check:**
1. `ssh futro 'bash ~/ZaxModbus/arduino/build_s3zero.sh --build-only 2>&1 | tail -5'` —
   compile-only run (documented script flag, no port/flash needed).
2. `ssh bench 'bash ~/ZaxModbus/arduino/build_s3zero.sh --build-only 2>&1 | tail -5'` on
   raspi — same check, unchanged.
**Success criterion:** PASS if both machines produce a clean compile (exit 0, `.bin`
artifact present) after cutover. FAIL if raspi's toolchain was touched, disabled, or left
unverified during this step.

**Rollback trigger:** if Step 3 (or a later real build/flash on futro) fails in a way
that isn't quickly diagnosable, fall back to raspi for that work, resolve Unit_A's
disposition per Step 4's pattern, and reopen Step 3 rather than declaring Phase 2 done
around a known gap.

---

## Final validation checklist

1. **Board move (historical):** Unit_A + RS-485 adapter confirmed on futro by exact
   MAC/type match; raspi's `/dev/serial/by-id/` confirmed empty. **PASS, done 2026-08-14.**
   Pre-disconnect test-platform-run check was not live-verified (§ Step 1.1) — noted, not
   blocking, but a residual unconfirmed item.
2. **Cable/port sanity:** `esptool read_flash 0x0 4096` on `/dev/ttyACM0` exits 0,
   4096-byte file. **PASS, done 2026-08-14** (via the arduino-cli-bundled `esptool`
   binary directly — the system `python3 -m esptool` module isn't installed on futro;
   noted, not blocking, since Step 3 sources the ESP-IDF venv instead).
3. **Flash + smoke test:** **PASS, done 2026-08-14, amended criterion.** Same firmware
   version reflashed (v1.1.19); literal serial `SMOKE TEST: PASS` did NOT occur (0-byte
   capture — confirmed futro-specific USB-CDC gap, not a flash/boot defect); PASSED
   instead via `/api/sysinfo`: `fw_version` match, `boot_count` incremented 90→92,
   `mqtt_connected: true`. Two hardcoded-path bugs found and fixed en route
   (`ZaxModbus` `48c5c18`, `ZaxCommon` `f96de49`). CDC-capture gap itself is unresolved
   and tracked in `nodes/futro/status.md`, not closed by this amendment.
4. **Unit_A disposition decided and recorded:** staying on futro for as long as Phase 2
   testing needs it (user decision, 2026-08-14). **PASS, recorded in
   `nodes/futro/status.md`.**
5. **RS-485 from futro:** real Modbus data read via futro's own adapter, negative control
   included. **PASS, done 2026-08-14** (single-device scope; multi-drop-at-scale noted as
   a separate open item under Step 5, not required for this checklist item).
5.4. **4.5.1 — second board type flashed + boards.json cross-visibility:** Unit_D flashed
   clean from futro via `build_lilygo.sh`, literal `SMOKE TEST: PASS` including the
   Modbus RTU check (LilyGO's CDC works on futro, unlike the S3-Zero's gap). **PASS,
   done 2026-08-14, but only after fixing a real 3-week-old `sshfs` split-brain bug** —
   see Step 4.5.1 for full detail. `boards.json` writes from futro now correctly reach
   the file raspi's tooling reads.
5.5. **4.5.2/4.5.3 — Multi-drop + duration validation:** both Unit_A and Unit_D respond
   correctly and distinctly on one shared bus/adapter from futro; ≥99.5% Modbus success
   per unit over a 4h round-robin soak. **Not yet run.**
6. **Bench-location decision recorded:** stated explicitly, referencing the multi-drop
   scope limit. FAIL if undocumented.
7. **`boards.json` authority decision recorded:** exactly one writable copy, backup cron
   source matches wherever authority landed. FAIL on any two-independent-copies state.
8. **Cutover documented, raspi verified intact:** both machines' build scripts still run
   post-cutover. FAIL if raspi's toolchain was degraded in the process.

Until all 9 PASS, raspi remains the practical development machine for any work that can't
tolerate an unverified step, regardless of what any status doc's role field says.
