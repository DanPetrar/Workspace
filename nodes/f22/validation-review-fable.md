# Fable: what to add to the f22 validation tests (2026-10-30)

Sources I read: `Workspace/nodes/f22/role-setup-plan.md` (validation section V1-V8), `nodes/futro/2026-10-30-close.md`, `ZaxModbus-PS/arduino/build_s3zero.sh`, `build_s3eth.sh`, `~/flash_guard.py`, `~/identity_guard.py`, `ZaxModbus-PS/tools/zaxtest/{gate,influx,modbus,units.yaml}`, `tools/git-hooks/pre-commit`, and the raspi crontab and services.

I did not contact f22. Everything below about f22 is a test to run, not a finding.

## Three gaps found by reading the code (V4 and V7 as written would hit them)

**G1. The flash path uses three different esptools, and V3 tests none of them.**
- `build_s3zero.sh`, lines 133-134 (`build_s3eth.sh`, line 88): `source $HOME/esp/esp-idf/export.sh > /dev/null 2>&1`, then `python -m esptool ... write-flash` (lines 244 and 259). ESP-IDF is "not moved" to f22, so this line fails without a message.
  - If Debian 13 has no `python` command, the flash step ends with "Flash failed." The PIPESTATUS check catches this, so it is safe, but it blocks V4.
  - If `python-is-python3` is installed, Debian's esptool 4.7 runs instead. I did not check whether 4.7 accepts the hyphen forms (`write-flash`, `default-reset`).
- `identity_guard.py`, line 48: uses the esptool bundled in `~/.arduino15/packages/esp32/tools/esptool_py/*/` (the x86 build on f22).
- `flash_guard.py`, lines 62 and 91: uses `sys.executable -m esptool`, which is the system `python3`.
- V3 as written ("esptool 5.x in a pip venv") checks a fourth esptool that none of the scripts calls.

**G2. On f22 the gate skips the PS-Z line instead of failing it.**
- `units.yaml` gives PS-Z001 `mb_host: esp-devbox64` (the raspi's hostname).
- `gate.py`, lines 168-176: when `gethostname()` differs from `mb_host`, it prints `[gate] SKIPPING line ...` and drops the line.
- On f22, V7 "0 failed reads" would therefore be met by a skip. A skip is not a pass.

**G3. If the catalog mount is down, a catalog write is lost without any message.**
- On f22, `~/boards.json` is a symlink into the sshfs mount. With the mount down, the link points to nothing.
- `load_catalog()` then returns `{}` with no error (lines 18-21).
- `save_catalog()` then writes `realpath` (lines 47-55). That creates a local `~/pi-raspi-mnt/boards.json` holding only the one MAC that was touched.
- When the mount comes back it hides that file, and the update is gone. `flash_guard.py list` shows 0 boards, with no error.
- futro has the same setup. This is the owner's call: fix it before V4, or accept it and add a check.

**Files outside git that the tests need, and that the plan does not list:**
- `~/.zaxmodbus_influx_token`: read by `influx.py` `TOKEN_PATH`; `phase2/*` reads it from the hard-coded path `/home/pi/...`.
- `~/.ssh/config` hosts `ws` and `futro`: `influx.py` sends its queries through `ssh ws` (`SSH_HOST = "ws"`), and the catalog backup cron uses `ws:`.

## Changes to the existing tests

| # | Add to the PASS condition |
|---|---|
| V1 | Also build `build_s3eth.sh` (NEWBOX, PS-E002 line) and `build_testmode.sh` with `--build-only` on both machines. Record the 6 library versions and the ZaxCommon commit (raspi: 27cde02). The sha256 must be equal. Accept a "named difference" only with its cause found before V4, because release images are tied by hash to the gate history (release-delivery-spec §4). |
| V2 | Run the reads through the zaxtest code (`influx.py`, `mqtt.py`, `http.py`), not with curl by hand. This proves that the token, `ssh ws` and the key work from f22. |
| V3 | Check the three esptools from G1 exactly as the scripts call them: (a) `bash -c 'source ~/esp/esp-idf/export.sh; command -v python; python -m esptool version'`; (b) the bundled esptool path in `identity_guard.py` resolves and prints its version; (c) `python3 -m esptool version`. PASS when all three are 5.x, or the owner has chosen in writing which one the scripts use on f22. Then the chip id and 4 KB read-flash. |
| V4 | Also: the version and time that f22 writes appear in the raspi's `~/shared/boards.json`; the smoke test shows the new version (otadata reset worked); the hash on the unit equals the built sha256. |
| V6 | Same counts as the raspi for passed, failed AND skipped. A higher skip count is a FAIL. |
| V7 | 0 lines skipped by `gate.py` (G2); the number of Modbus cases run equals the raspi run; the adapter is named by its `/dev/serial/by-id` name. |
| V8 | Start the soak with `setsid nohup` over SSH, then log out. PASS also needs: the run survived the logout, and nothing suspended the machine (see V12). |

## New tests

| # | Test | PASS when | Hands |
|---|---|---|---|
| V9 | Catalog mount loss (G3): stop `sshfs-boards.service` on f22, run `flash_guard.py list`, start the service again | Loud error, no 0-board list. If it fails today: the owner decides on a fix before V4. Check afterwards that no local `~/pi-raspi-mnt/boards.json` is left behind the mount. | no |
| V10 | Git from f22: `ZaxModbus-PS/.git/hooks/pre-commit` symlink present. In a scratch clone, stage a FW_VERSION change with no Doc/INDEX.md row. Run `git push --dry-run` on each repo. | Hook refuses the commit; home repo `git status` clean (boards.json skip-worktree); every dry-run OK | no |
| V11 | Clock: `timedatectl` on f22, and its offset to ws and to the raspi | Synced; same NTP source as the raspi; offset < 0.5 s (record ts and Influx comparisons depend on it) | no |
| V12 | Unattended safety: sleep/suspend targets and desktop idle suspend; `ModemManager` and `brltty` status (the raspi runs ModemManager); USB `power/control` of the ESP and the CH340 | No suspend after 8 h idle; nothing else opens `ttyACM*` or `ttyUSB*`; no USB autosuspend on these ports | no |
| V13 | USB replug: unit USB and CH340 unplugged and replugged 3 times each | Same by-id name back within 5 s each time; no `-71`/`-110`/`unable to enumerate` in `dmesg` | yes |
| V14 | Return path: written one-page rollback (symlink, cron, sshfs direction) before the authority moves | The raspi still builds and lists the catalog after the move, until the owner releases it | no |

## On the day the bench moves (after V1-V14)

- Claude on f22, started in `~`, loads MEMORY.md (project folder `-home-pi`), CLAUDE.md, and the `github-workflows` skill.
- The catalog backup cron runs once on f22 and the file appears on ws.
- The gate entry `units.yaml` `mb_host` for PS-Z001 is set to f22's hostname. The owner's word is needed for this change.

## Suggested order

1. No hands, read-only or scratch: V1, V2, V3 (a-c), V9, V10, V11, V12. Fix G1-G3 here, or record the owner's decision for each.
2. One hands session: V3 USB, V4, V5, V6, V7, V13. Then V8 runs overnight.
3. Never Unit_B. Nothing on the raspi's USB before PS-E002 is judged (after 20:02).
