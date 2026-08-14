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

## Step 3 — Build → flash → serial-monitor → smoke-test round trip — NOT YET RUN

The actual unverified gap that remains: futro has never flashed a board through its own
USB and had the result verified. Use `ZaxModbus/arduino/build_s3zero.sh` (Unit_A's board
type).

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
`feedback_post_flash_smoke_test` — never report success without this).

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
   for the full permanent bench, not just extrapolating from one board.
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
regardless of how this resolves. Step 3, once run, will be the first real write to
`boards.json` (`flash_guard.py update`) originating from futro under actual use — worth
watching that it lands correctly through the `sshfs` mount as part of Step 3's own check,
not just assumed.

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
   4096-byte file. **Not yet run.**
3. **Flash + smoke test:** literal `----- SMOKE TEST: PASS -----`, same firmware version
   as before, Demo-Mode accounted for. **Not yet run.**
4. **Unit_A disposition decided and recorded:** staying on futro for as long as Phase 2
   testing needs it (user decision, 2026-08-14). **PASS, recorded in
   `nodes/futro/status.md`.**
5. **RS-485 from futro:** real Modbus data read via futro's own adapter, negative control
   included. **PASS, done 2026-08-14** (single-device scope; multi-drop-at-scale noted as
   a separate open item under Step 5, not required for this checklist item).
6. **Bench-location decision recorded:** stated explicitly, referencing the multi-drop
   scope limit. FAIL if undocumented.
7. **`boards.json` authority decision recorded:** exactly one writable copy, backup cron
   source matches wherever authority landed. FAIL on any two-independent-copies state.
8. **Cutover documented, raspi verified intact:** both machines' build scripts still run
   post-cutover. FAIL if raspi's toolchain was degraded in the process.

Until all 8 PASS, raspi remains the practical development machine for any work that can't
tolerate an unverified step, regardless of what any status doc's role field says.
