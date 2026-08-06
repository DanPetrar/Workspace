# futro — Status

Bring-up completed 2026-07-22, run from `raspi`'s Claude Code session per
`setup-plan.md` section 4. Verified live at close of bring-up.

## Services / setup

| Item | State |
|---|---|
| Claude Code CLI | ✅ installed, v2.1.223 (self-updated 2026-08-06), `~/.local/bin/claude` |
| `gh` auth | ✅ logged in as `DanPetrar`, protocol `ssh`, scopes `repo, admin:public_key, gist, read:org` |
| git identity | ✅ `DanPetrar` / `delazax@zapptronic.eu`, `init.defaultBranch main` |
| SSH → `ws` (workstation) | ✅ key-based, no prompt |
| SSH → `bench` (raspi) | ✅ key-based, no prompt |
| Project repos (9) | ✅ all cloned, all `git fetch` clean |
| `CLAUDE.md` | ✅ Futro-specific version in place, role split documented on both machines |

## Role in the current fleet

- Full coordinator role (everything `raspi`'s Claude Code session used to do)
- **Full dev-toolchain parity with raspi, added the same day** (user direction,
  Fable-reviewed — see `setup-plan.md` amendment): arduino-cli/ESP-IDF/`flash_guard.py`
  installed, verified via a real compile of ZaxModbus and a live read of the shared
  `boards.json`. See `inventory.md` for detail.
- Co-located with the permanent bench — no RS-485/USB/serial/GPIO hardware plugged
  into futro's own ports yet, but the toolchain is ready for when a board is moved
  over. Reaches `raspi` via `ssh bench` for the permanent bench (Units A-D, RS-485)
  while it stays wired there.
- Hosts the coordination Claude Code session going forward

## Next step — validate futro as the primary development machine (2026-07-30)

**User direction, 2026-07-30:** over the coming days, continue the migration and
validate that futro can *become* the development machine, rather than only holding
toolchain parity with raspi.

What is already settled:

- Toolchain parity exists and was proven by real compiles (see `inventory.md`).
- futro is **2–3.6× faster on warm rebuilds** — the normal edit/compile loop.
- **Decision: do NOT buy an external SSD for raspi.** It was considered on 2026-07-30 and
  rejected — futro already has a 477 GB SSD, 7.5 GiB RAM (vs raspi's 1.8 GiB) and an SD
  card, and the measured compile advantage. Spending on raspi would produce a slower
  duplicate of a machine already owned and co-located with the bench.

What validation still needs to cover:

- Flashing and serial monitoring from futro's own USB ports with a board physically moved
  over — the toolchain is ready but no hardware has been plugged into futro yet.
- Whether the permanent bench (Units A–D, RS-485) stays wired to raspi long-term, or moves.
  raspi's role is tied to physical cabling, not to capability.
- `boards.json` authority. It currently lives on raspi and futro reaches it via `sshfs`.
  If futro becomes primary, decide whether authority moves — and note that today this is
  the one irreplaceable piece of state on raspi's **SD card**, which is also its most
  likely hardware failure. A periodic backup of `boards.json` (and ideally an SD image) is
  worth doing regardless of which way the migration goes.

## 2026-08-06 — network migration completion + full 9-point checklist re-run

The 2026-08-01 network migration (192.168.110.x → 192.168.20.x) never touched futro —
its `~/.ssh/config` `ws`/`bench` aliases were still on the old subnet, breaking the
`boards.json` sshfs mount. Fixed today, then the full 9-point validation checklist from
`setup-plan.md` §5 was re-run end-to-end:

| # | Check | Result |
|---|---|---|
| 1 | SSH futro→ws, key-based | ✅ PASS |
| 2 | SSH futro→bench, key-based | ✅ PASS |
| 3 | `gh auth status` | ✅ PASS — DanPetrar, protocol ssh |
| 4 | `git fetch`, all 9 repos | ✅ PASS — no prompts/errors |
| 5 | Claude Code ≥ raspi's version | ✅ PASS (after self-update: futro was 2.1.217, behind raspi's 2.1.223 — ran `claude update`, now 2.1.223 = raspi's) |
| 6 | Fresh-session context test | ⏳ **Manual step — needs the user**, see note below |
| 7 | Reverse round-trip `futro→bench→flash_guard.py --help` | ✅ PASS |
| 8 | Toolchain parity (replacement check) | ✅ PASS — arduino-cli 1.4.1 + esp32:esp32 core, `boards.json` is a live symlink into the sshfs mount |
| 9 | Workspace docs closed out | ✅ PASS (after `git pull` on all 9 repos, which had not been pulled since 2026-07-22 bring-up — up to 34 commits behind on some) |

**Check 6 cannot be run by Claude Code itself** — it requires a brand-new (non-resumed)
Claude Code session on futro, asked *"What is the current state of the ZaxModbus
project, and what's the bench fleet's firmware version?"*, with a pass defined as a
specific version string traceable to a file on disk, no hedging. **Still open, waiting
on the user.**

**Fixed same day:** futro's `dan-futro` user had **no passwordless sudo** (`sudo -n -l`
→ "a password is required" when first checked). User added
`/etc/sudoers.d/010_dan-futro-nopasswd` (`dan-futro ALL=(ALL) NOPASSWD: ALL`) via
`visudo`, matching raspi's own `010_pi-nopasswd` setup exactly. Verified:
`ssh futro 'sudo -n whoami'` → `root`, no prompt.

**Also done today:** `boards.json` nightly off-box backup cron added (raspi →
Workstation, `00:15` daily) — the "worth doing regardless" item from the section above
is no longer open, independent of whether authority ever moves off raspi.

## Open items

- **Check 6 above — fresh-session context test, needs the user.** Once confirmed, the
  coordinator-role transfer can be treated as fully, verifiably complete per
  `setup-plan.md`'s own bar (all 9 must pass).
- Validation of the development-machine role — see the section above.
- ESP-IDF is installed on **both** machines (2.8 GB `~/esp` + 4.8 GB `~/.espressif` each)
  purely because nine Arduino build scripts `source ~/esp/esp-idf/export.sh` to get
  `esptool` on the PATH, and `flash_guard.py` calls `sys.executable -m esptool`. Nothing
  compiles with `idf.py`. `EmonESP_MultiIO-V002/_build_common.sh` already shows the
  alternative (use the arduino-cli core's bundled esptool). Switching the scripts would let
  both machines drop ESP-IDF entirely. **Not urgent — no disk pressure on either machine —
  and deliberately parked** rather than done piecemeal.
- None outstanding from bring-up or the toolchain-parity add. `raspi`'s pre-existing
  `mosquitto.service` failure (since 2026-06-26) is unrelated to this node — see
  `nodes/raspi/status.md`.
