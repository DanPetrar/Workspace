# futro — Phase 2 Plan: Development-Machine Validation

**Status: not started.** Phase 1 (coordinator-role transfer, raspi → futro) is done and
verified — see `nodes/futro/setup-plan.md` §5, all 9 checks PASS as of 2026-08-06. This
document covers Phase 2: proving futro can be the machine where builds *and flashes*
actually happen, not just where compiles run and coordination is hosted. Target start was
"week of 2026-08-10" (set 2026-08-06); as of today (2026-08-14) no Phase 2 work has been
done yet — this plan doesn't relitigate the slip, just picks up from here.

**What's already settled (do not re-decide):**
- No external SSD purchase for raspi (2026-07-30) — futro's own SSD covers it.
- Full toolchain parity (arduino-cli, ESP-IDF, `flash_guard.py`, `boards.json` via `sshfs`)
  is installed and checklist-verified on futro.
- futro is 2–3.6× faster on warm rebuilds — not being re-tested here; this plan is about
  the one thing that *hasn't* been proven: futro's own USB ports.

**Board availability constraint (revised):** the user has confirmed only **Unit_A and
Unit_D** are available to connect to futro for this work. Unit_E/Unit_F (this plan's
earlier idle-spare candidates) are not in play. This is a materially different risk
profile from "genuinely idle spare" — both A and D are live, wired-in bench units, so
Step 1 below now carries pre/post safety checklists that a spare board wouldn't need.

**What this plan resolves:** which of Unit_A/Unit_D to use and how to do that safely, the
round-trip test itself, restoring the unit to the bench afterward, where the permanent
bench lives long-term, who owns `boards.json`, and what "cutover" means in practice (raspi
is a fallback, not a decommission target, until every step below is PASS).

---

## Step 1 — Select a board and move it to futro (safely)

### 1.0 What Unit_A and Unit_D actually are right now

Re-checked live, not assumed from the last session (`boards.json` +
`ZaxModbus/tools/zaxtest/units.yaml`):

| | Unit_A | Unit_D |
|---|---|---|
| Board | `waveshare_s3zero` | `lilygo_t7s3` |
| Firmware | ZaxModbus v1.1.19, **validated: true** | ZaxModbus v1.1.19, **validated: false** |
| Test-platform role | **`target`** — the D2-approved automated test target for the s3zero line | **`bench`** — "on the bench and on the bus, but not a test target" |
| `usb_port` registered in `units.yaml` | **Yes** — `gate.py`/pytest excursions drive this exact port directly | No entry — no automated harness has a hard dependency on Unit_D's USB port specifically |
| Physical wiring (per `units.yaml` notes) | **Dual-cabled**: Pi-USB (CDC) + box GND/GPIO5 (box 5V deliberately disconnected — powered from Pi-USB) | Not documented as box-wired; just "on the bench and on the bus" (RS-485) |

**Recommendation: use Unit_D first, and treat Unit_A as optional.**
- `role: target` means Unit_A is what `gate.py --board s3zero` sweeps in automatically —
  there is no per-unit exclude flag. Unplugging it risks colliding with any in-flight or
  scheduled test-platform run on the s3zero line, not just losing bench data.
- Unit_A is dual-cabled (box wiring in addition to USB) — more to disconnect cleanly and
  more to get wrong on reconnect.
- Unit_A is already `validated: true` — it's the known-good reference unit for its line;
  no reason to add risk to it for a test that doesn't need it.
- Unit_D is `role: bench`, not `target` — no automated harness reaches for it, so moving
  it doesn't collide with a running test suite. Its only "live" exposure is RS-485
  bus/soak participation, which Step 1.1 checks for directly.
- Different board type (`lilygo_t7s3` vs `waveshare_s3zero`) is a secondary reason, not
  the deciding one — Unit_D alone is enough to prove the futro-USB mechanism works at all,
  which is this plan's actual open question.

**Only bring in Unit_A** if the user specifically wants both board lines (s3zero +
lilygo) proven through futro's USB, not just one. If so, do it as a second pass *after*
Unit_D's round trip (Steps 1–4) is fully PASS, and re-run the 1.1 pre-disconnect check
against Unit_A's own state (`role: target`, dual cabling) before touching it — don't reuse
Unit_D's clearance.

### 1.1 Pre-disconnect safety checklist (do this before touching any cable)

1. Confirm no test-platform run is currently using the s3zero/lilygo lines:
   `ssh bench 'ps aux | grep -E "pytest|gate.py|soak_l3" | grep -v grep'` — expect empty
   output. If anything is running, wait for it to finish or ask the user before
   proceeding; don't unplug into an active run.
2. Re-confirm the board's role hasn't changed since the table above:
   `ssh bench "grep -A8 'Unit_D:' ~/ZaxModbus/tools/zaxtest/units.yaml"` — expect
   `role: bench`.
3. Snapshot the "before" state so there's something exact to restore/compare against:
   `ssh bench 'python3 -c "import json; print(json.load(open(\"/home/pi/boards.json\"))[\"80:b5:4e:f0:7f:8c\"])"'`
   — write down version, `last_flash`, `validated`.
4. Confirm the unit is actually alive on the bus right now (proves it's genuinely "on the
   bus" as documented, and gives a last-known-good timestamp):
   `ssh bench 'python3 ~/ZaxModbus/tools/board_test.py 21 zax_F07F8C/sec --duration 30'` —
   expect real records, not a timeout/empty result.
5. Note the exact disconnect time (a line in a scratch file is enough — Step 1.3 turns it
   into a proper log entry).

**Success criterion for 1.1:** PASS only if all four checks (1–4) come back clean. FAIL on
any active test-platform run, an unexpected role, or no bus response — stop and resolve
before disconnecting.

### 1.2 Physical move

1. Disconnect Unit_D's cable(s) at the raspi-bench end (power/USB and/or RS-485, per
   whatever's actually plugged in — `units.yaml` doesn't fully enumerate Unit_D's wiring,
   so confirm at the bench what's actually connected before pulling anything).
2. Carry it to futro; plug into a free futro USB port.
3. Confirm enumeration: `ssh futro 'ls /dev/ttyACM* /dev/ttyUSB* 2>&1'` — before/after
   comparison, expect exactly one new node.

**Success criterion for 1.2:** PASS if exactly one new `/dev/tty{ACM,USB}*` node appears
on futro. FAIL if it doesn't enumerate — stop, don't proceed to Step 2 with a device that
isn't visible yet.

### 1.3 Log the resulting bus/data gap

Unit_D disappearing from the RS-485 bus for the duration of this test is an expected,
planned outage, not a fault — but nothing downstream (fleet poller, Grafana, whatever
consumes `zax_F07F8C`) knows that unless it's written down. Add a short entry to
`nodes/futro/status.md` (or wherever the session log lives) now, while the disconnect time
is fresh: unit name, disconnect timestamp, reason ("Phase 2 USB round-trip test on
futro"), expected reconnect window. Step 4 closes this entry out.

**Success criterion:** PASS if the entry exists before Step 2 starts. FAIL if the outage
is undocumented — a future session shouldn't have to rediscover this as an unexplained gap
the way WISHLIST #15's unexplained 3-record holes had to be chased down after the fact.

---

## Step 2 — USB cable/port sanity check (pre-flight, before any flash)

House convention (`feedback_usb_cable_verify`): a MAC-read alone doesn't expose a marginal
cable or port; a 4 KB read-flash does. This has never been run through futro's own USB
controller — worth doing before trusting a flash result to it.

**Do:** `ssh futro 'python3 -m esptool --port /dev/ttyACM0 read_flash 0x0 4096 /tmp/futro_cable_test.bin'`
(substitute the actual port from Step 1.2).

**Check:** command exits 0 and `/tmp/futro_cable_test.bin` is exactly 4096 bytes.
**Success criterion:** PASS on clean exit + correct file size.

**If FAIL** — this is a judgment call, not a script, so work through it in order rather
than guessing:
1. Try a different physical cable — short, known data-capable (not a charge-only cable).
2. Try a different futro USB port — prefer a rear/direct port over a front-panel hub if
   one is involved.
3. Re-run the same `read_flash` command after each swap.
4. If it still fails after both swaps, treat this as a real futro port/driver issue, not a
   cable fluke — stop here, don't carry an unresolved failure into Step 3 where it would
   be harder to distinguish from a toolchain problem.

---

## Step 3 — Build → flash → serial-monitor → smoke-test round trip, on futro's own USB

This is the actual unverified gap. The existing build scripts
(`ZaxModbus/arduino/build_lilygo.sh` for Unit_D, or `build_s3zero.sh` if the optional
Unit_A pass happens) already bundle flash + a second-reset + an automated smoke test that
captures boot serial and prints a PASS/FAIL line — this reuses that convention rather than
inventing a new one.

**Before running:** flash the **same version Unit_D is already running (v1.1.19)**, not a
new one. This is a deliberate choice, not an oversight: the goal is to prove futro's
toolchain mechanism, not to actually advance Unit_D's firmware. Flashing the same version
keeps the unit's functional state unchanged regardless of how the test goes, and avoids
turning "test the USB round trip" into "also change what's running on a live bench unit."

**Also before running:** confirm no unrelated USB-serial adapter is present on futro —
`ssh futro 'ls /dev/ttyUSB* 2>&1'` should come back empty. The build script's Modbus probe
looks for `/dev/ttyUSB*` as an RS-485 dongle; if none is present it prints a WARNING and
skips the probe (see note below) — but if a stray, unrelated device happens to be there it
could be misread as a Modbus adapter and produce a confusing false FAIL.

**Do:**
```
ssh futro 'cd ~/ZaxModbus/arduino && bash build_lilygo.sh /dev/ttyACM0'
```
(port from Step 1.2). Let it run to completion — flash, `identity_guard.py` check, reset,
smoke capture.

**Check:** tail the script's own smoke log line, e.g.
`ssh futro 'tail -5 /tmp/arduino_smoke_ZaxModbus_lilygo.log'` plus the script's final
stdout line.
**Success criterion:** PASS only on a literal `----- SMOKE TEST: PASS -----` line in the
script's own output (per `feedback_post_flash_smoke_test` — never report success without
this).

**Important caveat on what PASS actually proves:** futro has no RS-485-to-USB dongle
wired up yet, so the build script's Modbus RTU probe will find no `/dev/ttyUSB*` and print
`WARNING: no /dev/ttyUSB* found — skipping Modbus check` — that's a skip, not a failure,
and the script still reaches `SMOKE TEST: PASS` on the boot/CDC checks alone. **A PASS here
proves USB-CDC flash + boot + config from futro. It does NOT prove RS-485/Modbus works
from futro** — that hardware path is untested by this step and matters for Step 5 (bench
location) below.

**If FAIL** — triage in this order before concluding it's a futro defect:
1. Check the log for which stage failed: `identity_guard.py` rejection (wrong board/image
   pairing), `[BOOT]` line missing (setup() never completed), or the Modbus block itself
   failing (only possible if a stray `/dev/ttyUSB*` was present — see the pre-check above).
2. Re-confirm Step 2 actually passed on this exact cable/port — a cable that passed a 4 KB
   read can still be marginal at flash-speed writes; if in doubt, redo Step 2.
3. Only after ruling out 1–2, treat it as a genuine futro-toolchain gap and stop — debug on
   Unit_D itself (already off the bench, no additional risk), don't move to Unit_A to
   "try a different board" as a workaround.

---

## Step 4 — Reconnect Unit_D to raspi's bench and confirm it's whole again

Restoring the unit isn't just plugging the cable back in — confirm the bench is actually
back to its pre-test state, not just physically connected.

**Do:**
1. Disconnect Unit_D from futro.
2. Reconnect it at raspi exactly as it was before Step 1.2 (same port/cabling identified
   during the pre-disconnect check).
3. Confirm RS-485 bus response resumes:
   `ssh bench 'python3 ~/ZaxModbus/tools/board_test.py 21 zax_F07F8C/sec --duration 30'` —
   expect real records again, same as the Step 1.1 baseline.
4. Confirm firmware/version state matches what's expected. Because Step 3 deliberately
   reflashed the *same* version (v1.1.19), the functional firmware is unchanged; only
   `last_flash`/`last_ota` timestamps in `boards.json` will have moved (the flash script's
   own `flash_guard.py update` call does this automatically) — that's expected, not a
   problem. Confirm with:
   `ssh bench 'python3 -c "import json; print(json.load(open(\"/home/pi/boards.json\"))[\"80:b5:4e:f0:7f:8c\"])"'`
   — version should still read `1.1.19`.
5. Note: `validated: false` on Unit_D predates this plan and isn't something this round
   trip changes or needs to resolve — the validation gate (`ready_check.py`,
   version-exact bare PASS) is a separate procedure, out of scope here. Don't run it as
   part of Phase 2 unless the user asks for it separately.
6. Close out the Step 1.3 log entry: add the reconnect timestamp and confirmation that bus
   response resumed.

**Success criterion:** PASS if the bus check in step 3 above returns real data and the
version in `boards.json` still reads `1.1.19`. FAIL if the unit doesn't respond on
reconnect (treat as a bench-wiring problem to fix immediately, not a Phase 2 backlog item)
or if the firmware version changed unexpectedly.

---

## Step 5 — Bench-location decision (Units A–D / RS-485, long-term)

Explicitly undecided per the user's constraints. Steps 1–4 passing does **not** force this
decision, and — per the caveat in Step 3 — it specifically does not resolve it either:
Steps 1–4 prove futro's USB-CDC flash path works, not that RS-485/GPIO (what the permanent
bench actually runs on) works from futro. Don't treat a Step 3 PASS as "so the bench can
just move now."

**What the human should actually look at before recording this decision** (not scriptable
— a physical/judgment checklist):
1. Physical cable run: how long would the RS-485 trunk need to be if it moved to futro's
   location vs. staying at raspi's — is futro close enough to the bench's current position
   that this is a non-issue, or does it need new cabling/a longer bus run?
2. Whether an RS-485-to-USB dongle for futro even exists yet — Step 3's caveat showed
   there isn't one wired up today. If the bench moves, this needs sourcing and testing in
   its own right, not assumed to work because CDC-USB flashing did.
3. Power/placement at the bench itself — does relocating change how Units A–D are powered
   or physically mounted, independent of which machine polls them.
4. Whether moving the bench interrupts anything currently running (soak tests, the
   test-platform's `role: target`/`role: bench` units) for longer than the Step 1–4
   round trip did — a permanent bench move is a bigger disruption than a temporary loan.

**Do:** Human decision — stays wired to raspi, or physically moves to futro. Record the
choice and the reasoning (referencing the checklist above) in `nodes/futro/status.md` (or
`nodes/raspi/status.md`, whichever gains the bench).

**Check:** `grep -n "bench location" nodes/*/status.md` (or equivalent heading) after the
decision is written.
**Success criterion:** PASS if a status doc states the decision unambiguously (which
machine, as of what date, and whether RS-485-from-futro has actually been tested or is
still an open gap). FAIL if the docs still say "undecided" — that's a valid long-term
state, but then Step 7's cutover must explicitly say raspi keeps the bench indefinitely
rather than leaving it implicit.

---

## Step 6 — `boards.json` authority decision

Currently single-authority on raspi, reached by futro via `sshfs`; nightly backup cron
(raspi → Workstation, 00:15) already covers the "irreplaceable SD-card state" risk
regardless of how this resolves — that safety net does not need to change based on this
decision.

**What the human should actually look at before recording this decision:**
1. Current mount health from futro's side: `ssh futro 'mount | grep sshfs'` — confirm it's
   actually mounted and not silently stale (this broke once already, 2026-08-01 network
   migration, until fixed 2026-08-06 — worth a fresh look, not an assumption).
2. Write frequency vs. read frequency: `boards.json` is written once per flash (rare,
   human-paced) and read constantly (every test-platform run, every `flash_guard.py`
   invocation) — this favors keeping a single writer wherever flashing happens most often,
   which may shift if futro becomes the primary flashing machine.
3. Whichever way this goes, check the 00:15 backup cron's source path — if authority
   moves to futro, the cron needs to retarget in the same change, not as a follow-up.

**Do:** Human decision — keep raspi as sole writer (futro keeps reading/writing through
the existing `sshfs` mount, which already works per Phase 1 check #8), or move the
canonical file to futro (raspi would then need the reverse mount, and the nightly backup
source would need to retarget). Record the choice + reasoning in `nodes/futro/status.md`.

**Check:** `ssh futro 'ls -la ~/boards.json'` — PASS state is unambiguous either way
(symlink into `sshfs` mount = raspi stays authority; a real file = futro is now
authority, and raspi's copy must become the symlink instead).
**Success criterion:** PASS if exactly one machine holds the writable file and the other's
`boards.json` is verifiably a symlink/mount, not a second independent copy. FAIL if both
machines have real, independently-editable copies (the exact split-brain the `sshfs`
design was meant to prevent) — if authority moves to futro, update the 00:15 backup cron's
source in the same change, don't leave it backing up a now-stale raspi copy.

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
1. `ssh futro 'bash ~/ZaxModbus/arduino/build_lilygo.sh --build-only 2>&1 | tail -5'` —
   compile-only run (documented script flag, no port/flash needed).
2. `ssh bench 'bash ~/ZaxModbus/arduino/build_lilygo.sh --build-only 2>&1 | tail -5'` on
   raspi — same check, unchanged.
**Success criterion:** PASS if both machines produce a clean compile (exit 0, `.bin`
artifact present in the script's build dir) after cutover (futro as primary, raspi as
verified-working fallback). FAIL if raspi's toolchain was touched, disabled, or left
unverified during this step — that would violate the "safe fallback" constraint directly.

**Rollback trigger:** if Step 3 (or a later real build/flash on futro) fails in a way that
isn't quickly diagnosable, fall back to raspi for that work, reconnect/restore whichever
unit is involved per Step 4's pattern, and reopen Step 3 rather than declaring Phase 2 done
around a known gap.

---

## Final validation checklist

All must PASS before Phase 2 is treated as complete, matching the bar `setup-plan.md` §5
set for Phase 1:

1. **Pre-disconnect safety cleared and board staged on futro:** no active test-platform
   run at disconnect time, role/state snapshot taken, new `/dev/tty*` node confirmed on
   futro. FAIL if any half is unverified.
2. **Cable/port sanity:** `esptool read_flash 0x0 4096` on futro exits 0, 4096-byte file.
   FAIL on any esptool error.
3. **Flash + smoke test:** literal `----- SMOKE TEST: PASS -----` in the build script's own
   output, run from futro against futro's own USB port, same firmware version as before
   the test. FAIL on any other outcome.
4. **Board reconnected and bench confirmed whole:** RS-485 bus response resumes on raspi,
   `boards.json` version matches pre-test state, outage log entry closed out. FAIL if the
   unit doesn't respond on reconnect.
5. **Bench-location decision recorded:** stated explicitly (which machine, and whether
   RS-485-from-futro is tested or still open), not left implicit. FAIL if undocumented.
6. **`boards.json` authority decision recorded:** exactly one writable copy, the other a
   verified symlink/mount; backup cron source matches wherever authority landed. FAIL on
   any two-independent-copies state.
7. **Cutover documented, raspi verified intact:** both machines' build scripts still run
   post-cutover; `CLAUDE.md`/status docs updated on both. FAIL if raspi's toolchain was
   degraded in the process.

Until all 7 PASS, raspi remains the practical development machine for any work that can't
tolerate an unverified step, regardless of what any status doc's role field says —
matching the same principle Phase 1 used.
