# futro — Status

Bring-up completed 2026-07-22, run from `raspi`'s Claude Code session per
`setup-plan.md` section 4. Verified live at close of bring-up.

## Services / setup

| Item | State |
|---|---|
| Claude Code CLI | ✅ installed, v2.1.217, `~/.local/bin/claude` |
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

## Open items

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
