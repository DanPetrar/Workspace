# f22 role-setup plan — 2026-10-30 (draft, waits for the owner's decisions)

Base: close note `2026-10-30-close.md`. Role (owner): f22 replaces the raspi for everyday development and test.
Done when: f22 builds a ZaxModbus-PS image, reads/writes the board catalog, runs the offline tests, runs Claude Code
with the memory, and the node table and CLAUDE.md name it. Bench cables move only by the owner's hands.

## Bench facts (raspi, looked up 2026-10-30)

| Item | raspi now | On f22 |
|---|---|---|
| CPU | aarch64 (ARM) | x86_64, Intel Pentium Silver J5005 (Debian arch name `amd64`): nothing binary can be copied, fresh installs only |
| arduino-cli | 1.4.1, esp32:esp32 3.3.7 | same versions |
| Libraries | Adafruit NeoPixel, ArduinoJson 7.4.3, DallasTemperature 4.0.6, ModbusMaster 2.0.1, OneWire 2.3.8, PubSubClient 2.8, ZaxCommon 1.1.0 (local) | same |
| Python | pyserial 3.5, pymodbus 3.8.6, paho, requests, pytest 8.3.5, yaml, minimalmodbus 2.1.1 | apt packages |
| Catalog | `~/boards.json` -> `shared/boards.json` (authority); futro reads it over sshfs | see D2 |
| Home repo | `rpi-claude-config` (CLAUDE.md, flash_guard.py, boards.json, skill, scripts) | clone |
| Project repos | ZaxModbus-PS, ZaxModbus, PiGate, Workspace, Workstation, EnergyCalibrator (GitHub, SSH) | clone |
| Crons | boards.json nightly backup to ws; pitemp (vcgencmd, Pi only) | backup moves with the authority; pitemp no |
| Services | mosquitto (system), mq1884 broker (port 1884, `~/mq1884`), zax_directory (ZaxEnergySurvey, retired) | see D4 |
| Claude Code | 2.1.314, node 20, memory `~/.claude/projects/-home-pi` | see D3 |
| GPIO | no tool in ZaxModbus-PS/tools, PiGate, pigate-bench uses GPIO (grep) | f22 has none |
| f22 now | Debian 13.7, 3.6 GB RAM, 203 GB free, pi in sudo, not in dialout; only python3 present | |

Constraint: PS-E002 grid run on the raspi until 20:02. No step touches the raspi's USB; steps 1-4 touch f22 and GitHub only.

## Steps (one check each)

| # | What | Check | Time |
|---|---|---|---|
| 1 | apt: git, rsync, sshfs, curl, mosquitto-clients, python3-serial/-pytest/-yaml/-requests/-paho-mqtt, pip venv for pymodbus 3.8.6 + minimalmodbus 2.1.1; `pi` into `dialout` | `id` shows dialout; import of each module | 10 min |
| 2 | GitHub SSH key for f22 (D1) | `ssh -T git@github.com` | 5 min |
| 3 | Clone home repo into `~` and the 6 project repos | HEAD of each = origin/main hash on the raspi | 10 min |
| 4 | arduino-cli 1.4.1 + esp32 3.3.7 + the 7 libraries | compile ZaxModbus-PS (PS-Z001 FQBN, default_ffat): PASS, size vs the raspi build | 20 min |
| 5 | Catalog per D2 (sshfs to the raspi, as futro does, or move the authority) | `flash_guard.py` lists all boards; a scratch write round-trips | 10 min |
| 6 | Offline tests `ZaxModbus-PS/tools` (no unit selected) | same pass count as the raspi | 10 min |
| 7 | Claude Code install + login (owner's hands) + memory per D3 | `claude --version`; MEMORY.md readable | 15 min |
| 8 | Services/crons per D4 | broker answers on 1884 if moved | 10 min |
| 9 | Records: INDEX.md row f22 + `nodes/f22/`; CLAUDE.md role split (exact text first, after `ok`) | rows match the facts above | 10 min |

Flashing (for the bench move, not now): `build_*.sh` flash with `python -m esptool` from the ESP-IDF env (raspi: esptool 5.3.dev,
`write-flash` syntax); Debian's esptool is 4.7.0. f22 needs esptool 5.x (pip in a venv) before it flashes a unit.

Not moved: ESP-IDF (Arduino-only rule; 7.6 GB on the raspi), `.arduino15` copy (aarch64 binaries), pitemp cron.

## Progress

- 2026-10-30: owner added `/etc/sudoers.d/010_pi-nopasswd` on f22 (same as the raspi).
- Step 1 PASS: `pi` in dialout; git 2.47.3, rsync 3.5.0, sshfs (fuse 3.17.2), mosquitto-clients; pyserial 3.5, pytest 8.3.5,
  yaml 6.0.2, requests 2.32.3, paho 2.1.0, pymodbus 3.8.6 (all apt). minimalmodbus dropped (no user in ZaxModbus-PS/tools, PiGate).
- Step 2 PASS (see D1).
- Step 3 PASS: home repo d38d063 + ZaxModbus-PS 64fd72b, ZaxModbus a677d17, PiGate a30a2c7, Workspace be5432b,
  Workstation a3dfbd8, EnergyCalibrator b279778 = GitHub HEAD (all main). git user DanPetrar set on f22.
  Raspi: ZaxModbus (frozen) is checked out on `v1.2.1-newbox` 3bffc95; f22 has main. Uncommitted ZaxModbus-PS run files stay on the raspi.
- Step 4 compile PASS: arduino-cli 1.4.1 (`~/.local/bin`, sha256 OK vs `1.4.1-checksums.txt`), esp32:esp32 3.3.7, 6 libraries
  same versions, ZaxCommon main 27cde02. `NEWBOX=1 build_s3zero.sh --build-only` at 64fd72b (1.2.22): 1233347 B sketch,
  .bin 1233488 B, sha256 395884b7…40ab, built 12:58:29 (f22 clock), 123 s cold; tree clean after.
  Open: same-commit build on the raspi after 20:02 for the size/sha comparison.
- Step 5 PASS: raspi `~/.ssh/authorized_keys` + its own key (backup `authorized_keys.bak-20261030`); f22
  `/etc/systemd/system/sshfs-boards.service` (copy of futro's, user pi, `pi@192.168.20.225:/home/pi/shared` ->
  `~/pi-raspi-mnt`), enabled; f22 `~/boards.json` -> `~/pi-raspi-mnt/boards.json`, home repo `skip-worktree boards.json`.
  `flash_guard.py list` 24 boards on both; scratch write f22 -> raspi seen + removed; after an f22 reboot: service active,
  mount back, 24 boards. Note: the raspi's hostname is `esp-devbox64` (host key 13t5Sx… = this Pi).
- Step 6 PASS: plain `pytest` is NOT offline (it runs on all target units), so the offline set = 12 `host_test_*/run.sh` +
  `pytest --collect-only`. f22: apt g++ 14.2.0 + make; 12/12 host tests rc=0 (boxproto 9321, boxroute 23036,
  sec_delta 85, recpos 39, ringscan 21, clockstate 20, boxtrace 16 checks, 0 failed); collect-only 36 files / 317 tests,
  0 errors, same as the raspi. Open: the 12 host tests on the raspi after 20:02 (with the step 4 build compare).
- Step 7 PASS: Claude Code 2.1.314 (official installer, `~/.local/share/claude/versions/2.1.314`, same as the raspi);
  owner logged in; `claude -p "reply OK"` = OK. Memory, raspi settings.json (hooks, status line) not copied (D3).

## Decisions for the owner (asked one at a time)

- D1 GitHub key: **(b) copy the raspi key** (owner 2026-10-30). DONE: f22 `~/.ssh/id_ed25519` = SHA256:Aev/pp9m…HTA, `ssh -T git@github.com` = "Hi DanPetrar!" (step 2 PASS).
- D2 Catalog authority: **(a) stays on the raspi for now, f22 via sshfs** (owner 2026-10-30). After the f22 validation,
  f22 replaces the raspi on the bench; the catalog authority and its backup cron move then.
- D3 Claude memory: **(a) the raspi keeps the only memory; copy to f22 on the day the bench moves** (owner 2026-10-30).
  Step 7 now = Claude Code install + login only.
- D4 mq1884 broker + zax_directory: **(a) both stay on the raspi; they move with the bench** (owner 2026-10-30).
  Step 8 is empty until the bench moves.
- Claude setup = raspi (owner request 13:2x, `go`): f22 apt nodejs 20.19.2; raspi `settings.json` copied (+ theme
  dark-daltonized kept; f22 login file kept as `settings.json.f22-login`), `settings.local.json`, `ponytail/`, `ponytail-modes/`,
  `.ponytail-active`; jcodemunch-mcp 1.12.9 (pip --user) + `~/.code-index/config.jsonc`, `claude mcp add --scope user`,
  disabled for `/home/pi` as on the raspi (backup `.claude.json.bak-pre-mcpdisable`). `superclaude` (from `~/.bash_aliases`,
  home repo) = function on f22. Checks PASS: ponytail-activate rc 0, statusline rc 0, mcp Connected in /tmp + Disabled in ~,
  `claude -p` OK. Not copied: memory (D3), history, sessions, file-history.

## Validation before f22 replaces the raspi on the bench (owner `save` 2026-10-30; Fable additions merged on the owner's `merge`; not run yet)

Source of the additions: `validation-review-fable.md` (unedited).

### Gaps to decide before the hands session (owner decides fix or accept)

- G1 esptool: the flash path calls three esptools: `build_*.sh` sources `~/esp/esp-idf/export.sh` then `python -m esptool`
  (ESP-IDF not on f22: fails, or Debian esptool 4.7 if `python` exists); `identity_guard.py` uses the bundled one in
  `~/.arduino15/packages/esp32/tools/esptool_py/*/`; `flash_guard.py` uses `python3 -m esptool`.
  **Decision G1 (owner 2026-10-30, "as you recommend"): `python-is-python3` + esptool 5.1.0 via `pip --user` on f22 (= the
  bundled version of core 3.3.7); no ESP-IDF; no script change. Installed in V3.** Looked up: raspi export.sh esptool 5.3.dev,
  bundled 5.1.0 on both, `python3 -m esptool` missing on both.
- G2 gate skip: `units.yaml` PS-Z001 `mb_host: esp-devbox64`; `gate.py` skips a line when the hostname differs, so on f22
  the PS-Z line is skipped, not run.
  **Decision G2 (owner 2026-10-30, `a`): in V7, when the owner moves the CH340 to f22, `units.yaml` PS-Z001 `mb_host` ->
  `f22` (ZaxModbus-PS commit) and the gate runs from f22; back to `esp-devbox64` if the adapter goes back.** Looked up:
  `mb_host` is read only by `gate.py` (loud skip); `pytest -m modbus` ignores it.
- G3 catalog write lost: mount down -> `~/boards.json` dangles -> `load_catalog()` returns {} -> `save_catalog()` writes a
  local `~/pi-raspi-mnt/boards.json` with one MAC, hidden when the mount returns. futro has the same setup.
  **Decision G3 (owner 2026-10-30, `a`): fixed in the home repo: `load_catalog()` exits with an error on a dangling link
  (all writers go through flash_guard.py, OTA too); self-check in `test_flash_guard.py` (fails on the old code, passes on
  the new). V9 checks it on f22 after the pull. futro has its own copy of flash_guard.py: not updated (separate question).**
- Missing on f22 (outside git): `~/.zaxmodbus_influx_token` (influx.py, phase2/* hard-coded path); `~/.ssh/config` hosts
  `ws` and `futro` (influx.py `ssh ws`, backup cron `ws:`).

### Tests

| # | Test | PASS when | Hands |
|---|---|---|---|
| V1 | Build parity on both machines, same commit: `build_s3zero.sh`, `build_s3eth.sh` (NEWBOX) and `build_testmode.sh`, `--build-only`; 12 host tests; record the 6 library versions + ZaxCommon commit (27cde02) | equal sha256 per image (a difference only with its cause found before V4); 12/12 on both | no |
| V2 | Network read-only from f22 through the zaxtest code (`influx.py`, `mqtt.py`, `http.py`): Influx query, MQTT subscribe on the workstation broker, `/api/sysinfo` of one unit | all answer; numbers match the same reads from the raspi | no |
| V3 | The three esptools of G1 as the scripts call them: (a) `bash -c 'source ~/esp/esp-idf/export.sh; command -v python; python -m esptool version'`, (b) the `identity_guard.py` bundled path, (c) `python3 -m esptool version`; then chip id + 4 KB read-flash | all three 5.x, or the owner's written choice; chip + MAC = `boards.json` | USB part |
| V4 | Build -> flash -> smoke on one unit from f22, through the identity guard | smoke PASS showing the new version (otadata reset); hash on the unit = built sha256; version + time written by f22 appear in the raspi `~/shared/boards.json` | yes |
| V5 | OTA from f22 (`ota_push.py`) | unit reports the new version, image hash matches | yes |
| V6 | pytest L0 (`-m l0 --unit <X>`) from f22 | passed, failed AND skipped counts = the raspi run; more skips = FAIL | yes |
| V7 | RS-485/Modbus through an adapter on f22's USB (`-m modbus`) | 0 failed reads; 0 lines skipped by `gate.py` (G2); Modbus cases run = the raspi run; adapter named by `/dev/serial/by-id` | yes |
| V8 | 4 h soak with the unit on f22's USB, started with `setsid nohup` over SSH then logout; one f22 reboot | run survived the logout; no suspend (V12); no USB errors in `dmesg`; port + mount back after the reboot | yes |
| V9 | Catalog mount loss (G3): stop `sshfs-boards.service`, `flash_guard.py list`, start it again | loud error, no 0-board list (if not: owner decides a fix before V4); no local `~/pi-raspi-mnt/boards.json` left behind the mount | no |
| V10 | Git from f22: `ZaxModbus-PS/.git/hooks/pre-commit` symlink present; in a scratch clone stage a FW_VERSION change without a Doc/INDEX.md row; `git push --dry-run` on each repo | hook refuses; home repo `git status` clean (skip-worktree); every dry-run OK | no |
| V11 | Clock: `timedatectl`, offset to ws and to the raspi | synced; same NTP source as the raspi; offset < 0.5 s | no |
| V12 | Unattended safety: suspend targets + idle suspend; ModemManager / brltty; USB `power/control` of the ESP and CH340 | no suspend after 8 h idle; nothing else opens `ttyACM*`/`ttyUSB*`; no USB autosuspend on these ports | no |
| V13 | USB replug: unit USB and CH340, 3 times each | same by-id name back within 5 s; no `-71`/`-110`/`unable to enumerate` in `dmesg` | yes |
| V14 | Written one-page rollback (symlink, cron, sshfs direction) before the authority moves | the raspi still builds and lists the catalog after the move, until the owner releases it | no |

Order: (1) no hands: V1, V2, V3 a-c, V9, V10, V11, V12, with G1-G3 fixed or decided; (2) one hands session: V3 USB, V4, V5,
V6, V7, V13; then V8 overnight. Never Unit_B. Nothing on the raspi's USB before PS-E002 is judged (after 20:02).

### On the day the bench moves (after V1-V14 PASS)

- Catalog authority + backup cron to f22 (cron runs once, file appears on ws); Claude memory (D3); mq1884 + zax_directory (D4).
- Claude on f22 started in `~` loads MEMORY.md (`-home-pi`), CLAUDE.md and the `github-workflows` skill.
- `units.yaml` `mb_host` for PS-Z001 -> f22's hostname (owner's word needed).

### Results, no-hands tests (2026-10-30 ~13:45, owner `go`)

| # | Verdict | Seen |
|---|---|---|
| V2 | PASS (part) | f22 got `~/.ssh/config` (ws, futro) + `~/.zaxmodbus_influx_token` from the raspi (ws ED25519 key = raspi's zt00mcPy…). `influx.power_points("PS-E002", 09:00-10:00 UTC)`: 10806 points, same sha d54c75ee81b2 on both; `mqtt.count_sec_frames("zax_849DEC", 15)` at the same time: 17 / 17. Unit `/api/sysinfo` read: after 20:02 (PS-E002 run) |
| V3 a-c | PASS | f22 apt `python-is-python3`, pip --user esptool 5.1.0: (a) export.sh absent -> `/usr/bin/python -m esptool` 5.1.0; (b) `identity_guard.ESPTOOL` = bundled 5.1.0 (raspi 5.1.0 too); (c) `python3 -m esptool` 5.1.0. `~/identity_guard.py` was missing on f22: it is NOT in git on the raspi; copied. USB part: hands session |
| V9 | PASS | mount stopped: `list` and `update` rc 1 with "ERROR: … is missing (sshfs mount down?)"; 0 entries behind the mount; restarted: 24 boards |
| V10 | PASS after fix (owner `fix`: hook link created on f22; in the real clone FW_VERSION 9.9.99 commit refused rc 1, HEAD 64fd72b, tree clean). First run FAIL (1 of 3) | `ZaxModbus-PS/.git/hooks/pre-commit` symlink absent on f22 (fresh clone; the raspi has it). In a scratch clone with the hook: FW_VERSION 9.9.99 commit refused (rc 1, INDEX.md message). `push --dry-run` 7/7 OK; home repo clean |
| V11 | PASS | both synced, both `2.debian.pool.ntp.org` (different servers), offset to server raspi +2 ms, f22 +9 ms; over ssh vs raspi: f22 +92 ±107 ms, ws +132 ±142 ms (< 500 ms) |
| V12 | PASS (config) / NOT TESTED (8 h idle, per-port USB) | sleep targets static/inactive, logind defaults (IdleAction ignore), no desktop packages, ModemManager + brltty not installed; usbcore autosuspend 2 s (= raspi). Per-port `power/control` needs the devices plugged (hands session); 8 h idle: check the journal tomorrow |

Observation: the raspi USB shows no ESP / CH340 / Prolific / FTDI / CP210x device right now (sysfs vendor scan, 13:45).

### Results after the PS-E002 stop (owner `stop`, run stopped 14:01:40)

| # | Verdict | Seen |
|---|---|---|
| V1 | PASS (named difference, cause found) | 64fd72b on both, 4 images (s3zero, s3eth, TESTMODE s3zero, TESTMODE s3eth): rc 0, sizes equal (1233347 / 1328127 / 1241527 / 1336315 B sketch). sha256 differ; per pair 69-72 bytes: 32 = app-descriptor ELF sha (0xb0-0xcf), 33 = appended image hash, 4-7 = the core's "Software Info" compile date/time only (raspi e.g. "15:53:21 Oct 28 2026", f22 "12:58:11 Oct 30 2026" = when each machine's core cache was compiled). Host tests 12/12 on the raspi too (same check counts as f22) |
| V2 unit | PASS | PS-E002 by ETH MAC ee:f6:0a:84:9d:ed at .128 (ARP on both); `/api/sysinfo` from both: fw 1.2.22, boot_count 41 |

Consequence (fact, no action): an image's sha256 depends on the machine's core-cache compile time, so a release image
(tied by hash to the gate history) must be built on the machine whose build the gate tested.
New untracked files from V1: `ZaxModbus-PS/testmode/ZaxModbus_v1.2.22_TESTMODE_newbox_{s3zero,s3eth}.bin` on raspi and f22.

### Unit for V3-V8 (owner 2026-10-30)

Owner: "only unit-A is available for now to be able for modbus and mqtt together"; **`ok Unit_A`** = one-time exception to the
2026-10-13 standing direction (Unit_A only for #79): Unit_A for the f22 validation, on the `async-mqtt` branch (Unit_A is in
`units.yaml` only there: newbox_s3zero image, role bench, demo on, `mb_enabled` false, broker = raspi mq1884). V4 re-flashes
the same 14b image (768564b5); V7 needs a config write (`mb_enabled` + slave address) and a USB-485 adapter on its A/B.
Observation 14:4x: no serial device on the raspi or f22 (`/dev/serial/by-id` absent on both); Unit_A MAC not in the raspi ARP table.

### Results, hands session with Unit_A (owner: Unit_A + CH340 on f22 USB, 14:31)

| # | Verdict | Seen |
|---|---|---|
| V3 USB | PASS | f22 by-id: Unit_A `ttyACM0` (…3C:0F:02:E4:77:30), CH340 1a86:7523 `ttyUSB0`; esptool 5.1.0: ESP32-S3 v0.2, MAC 3c:0f:02:e4:77:30 (= catalog), 4 MB / 2 MB PSRAM; 4 KB read rc 0; `/sec` back within 60 s (no replug); dmesg -71/-110: 0 |
| V12 per-port | PASS | `power/control=on` for 303a:1001 and 1a86:7523 (no autosuspend) |
| V4 | PASS | backup first: full 4 MB read (sha 690c2a6a…, app slot = 768564b5), copied to raspi `ZaxModbus-PS/Doc/Async-MQTT/bench-unitA/f22-V4/`; f22 built 675fcf4 + step4b-diag.patch (1339839 B sketch, sha e34f9b4f…), `NEWBOX=1 NEWBOX_FLASH=1 build_s3zero.sh /dev/ttyACM0`: identity guard OK (proj 2, board 5, variant 4mb), 4 writes "Hash of data verified", SMOKE PASS, catalog row Unit_A -> 2026-10-30T14:38:40 seen in the raspi `~/shared/boards.json`; app read-back sha = built sha (e34f9b4f…); `/sec` 3 frames; config unchanged (0 keys differ); fw 1.2.18, boot 930 -> 934 (esptool resets). f22 tree restored to async-mqtt b485fc6, clean |
| V5 | PASS | f22 `tools/ota_push.py Unit_A …/14b-diag/ZaxModbus_v1.2.18_PS-Z_step4b-diag.bin` (archived 768564b5): "OTA OK — rebooting" 7.5 s, back on v1.2.18; ota_1 read-back at 0x190000 sha = 768564b5 (Unit_A back on its recorded #79 image); catalog row 2026-10-30T14:42:01 on the raspi; `/sec` 3 frames before and after the read-back; config 0 keys differ; boot 935. Side finding: WISHLIST #96 (OTA records firmware "ZaxModbus", USB "ZaxModbus-PS") |
| V6 | PASS | `pytest -m l0 --unit Unit_A` (async-mqtt b485fc6): f22 1 failed / 60 passed / 0 skipped (263 deselected); raspi (temporary on-disk worktree of async-mqtt, removed) 1 failed / 60 passed / 0 skipped. Same counts. The 1 failure is the same on both: LINT_001, 9 bare asserts in `test_mq_judge_host.py` on the async-mqtt branch (WISHLIST #97), not an f22 difference. Observation: raspi `/tmp` (tmpfs 923 MB) 91 % full; the first worktree attempt in /tmp failed for that reason |
| V7 | FAIL | Unit_A `mb_enabled` true (addr 20, baud code 5) + restart (boot 937); f22 local `units.yaml` Unit_A `slave: 20`, `mb_host: f22` (not committed, undone after). `pytest -m modbus --unit Unit_A` on f22, CH340 `usb-1a86_USB_Serial-if00-port0` = `ttyUSB0`: 23 failed, 2 passed, 5 skipped (3 "ring too fresh / 0 sec rows", 2 opt-in NET-006/TS-004), 12 min 47 s. First failure: `test_MB_self_id` "Unit_A no FC03 response at addr 20"; others: "no live SEC block", "slave 20: no live ts", `None` responses. dmesg -71/-110: 0. History: nothing found. Restored: `mb_enabled` false + restart (boot 941), yaml undone (tree clean), config = V4 backup (0 keys differ), `/sec` 3 frames |
| V7 rerun (owner `rerun V7`) | FAIL, same | 15:09:58-15:22:46, same setup and command: 23 failed, 2 passed, 5 skipped (same 23 test names, same first failure "no FC03 response at addr 20"); dmesg -71/-110: 0. Restored: `mb_enabled` false + restart (boot 946), yaml undone, config = V4 backup (0 keys differ) |
| V13 | PASS (Unit_A USB) / NOT TESTED (CH340) | watcher 15:38:38 (0.5 s poll of by-id) + dmesg. Unit_A USB 3 replugs: by-id `…3C:0F:02:E4:77:30-if00` back each time, 15:39:39.2 / 15:40:06.8 / 15:40:34.8, within 1-2 s of the kernel "new full-speed USB device" line (15:39:38 / 15:40:06 / 15:40:34; device numbers 6, 7, 8); boot 946 -> 949; `/sec` 3 frames after. CH340: no disconnect seen in the watcher log or dmesg up to the owner's `done`. dmesg -71/-110/unable to enumerate: 0 |

### Next (owner 2026-10-30 ~16:00): f22 moves to the bench, PS-E002 (not at the grid place) on f22's USB

Order (owner: "v13 after v8"): 1 f22 up at the bench (ping/SSH, mount 24 boards, by-id PS-E002 + CH340, dmesg 0 errors,
PS-E002 found by MAC); 2 f22 ZaxModbus-PS back to `main` (PS-E002 in `units.yaml`, slave 31); 3 V7 with PS-E002 (positive
control FC03 0x0014 = 31 first; `mb_host: f22` per G2); 4 V8 4 h soak of PS-E002 from f22 + one f22 reboot; 5 V13 CH340 replug.
V8 on Unit_A dropped. Unit_A leaves f22 USB on its recorded image 768564b5, config = V4 backup.

### V7 with PS-E002 at the bench (owner `go`, 16:0x-16:25)

| Step | Verdict | Seen |
|---|---|---|
| f22 up at the bench | PASS | ping 0.35 ms, mount 24 boards, by-id PS-E002 (…E8:F6:0A:84:9D:EC) + CH340, dmesg 0 errors; PS-E002 by ETH MAC at .128 (WiFi .132 silent), fw 1.2.22, boot 42, `mb_enabled` true / 31 / code 5, demo off, eth_mode 1 |
| Positive control (`a7-modbus-20261028/mbblock.py`, CH340 by-id, 31, 38400, 200) | PASS | 200/200 answered, 42/44 ms (raspi 10-28: 200/200, 41-47 ms); 0x0200 / 0x0300 exception 2; 4 energies MATCH `/api/data` |
| `mb_host: f22` (G2) | done | f22 ZaxModbus-PS main aa5066c (unpushed) |
| `pytest -m modbus --unit PS-E002` | FAIL (4) | 16:17:16-16:24:53: 4 failed, 24 passed, 2 skipped (opt-in NET-006, TS-004). NB_004 "echo counters moved: echo_extra 0 -> 40"; TS_001 "ts_source not Modbus after accepted push" (1, expected 2); TS_006 "clock should be unset with NTP disabled"; TS_007 "0x0512 2 after a manual time, expected 0". dmesg 0 errors. Raspi pytest baseline for this unit: none (NOT TESTED). History: 2026-10-15 echo_extra counters (1.2.10), no fix for these; TS: nothing found. After: config = 10-29 run start config (0 keys differ), boot 48, MQTT connected. Logs: `ZaxModbus-PS/Doc/new-hardware/PS-E002/f22-V7-20261030/` |
| V8 | NOT TESTED (stopped by the owner at 18:2x after 1 of 4 judged hours) | soak_run PID 1454 on f22 (started 16:43, setsid, survived the logout) killed by PID; owner: "we are not able to wait so long … long duration tests over the weekend". Hour 17:00-18:00: SEC 3600/3600/3600, unreachable 0, Modbus 360/360, energy match, boot 48, 0 error-log lines; all polls 591, Modbus fails 0; dmesg -71/-110 0; journal suspend/sleep 0. f22 reboot part not run. V8 and V13 CH340 move to the weekend |
| V8 night (12 h) | PASS (hour rule 12/12) | soak_run PID 2378 on f22, 19:21:10 start, setsid, survived the logout; judged 20:00 -> 08:00 (`ZaxModbus-PS/Doc/new-hardware/PS-E002/f22-V8-night-20261030/`, not in git): SEC 3600 x10 hours, 3599 at 21:00 and 05:00 (1 s holes 21:01:31 / 05:01:31, limit 3599), unreachable 0, Modbus 360/360, energy match, boot 54 throughout; f22 dmesg -71/-110 count 0. `report.md` says FAIL "only 12 of 24 hours" = tool counts against `HOURS = 24`, not `--hours` (WISHLIST #99) |
| V12 8 h idle | PASS | 2026-10-31 09:08: f22 up since 2026-10-30 16:09:14 (16 h 59 min); `journalctl` since 16:00: no suspend / sleep / hibernate event (only the boot-time "PM: hibernation: Registered nosave memory" lines) |
| V8 f22 reboot | PASS | 2026-10-31 `systemctl reboot` 09:13:53, SSH back 09:14:46 (up 09:14:22); before = after: `sshfs-boards` active, mount, `flash_guard.py list` 24 boards, by-id PS-E002 (…E8:F6:0A:84:9D:EC) + CH340, dmesg 0 errors, `power/control=on` 303a:1001 + 1a86:7523; PS-E002 fw 1.2.23 boot 54 (unchanged) |
| V13 CH340 | PASS | 2026-10-31 watcher on f22 (0.5 s poll of by-id `usb-1a86_USB_Serial-if00-port0` + `dmesg -w`), owner's 3 replugs: gone 09:24:53.6 / 09:25:23.3 / 09:25:54.9, back 09:25:03.7 / 09:25:34.8 / 09:26:06.5, each in the same second as the kernel "ch341-uart converter now attached to ttyUSB0" (same by-id name, ttyUSB0, 1-2.1.1); `-71`/`-110`/`unable to enumerate` 0. After: `mbblock.py` via CH340, addr 31 @ 38400, 5/5 answered 43 ms, 0x0200/0x0300 exception 2, 4 energies MATCH `/api/data` (PS-E002 .128) |
| Observation (f22 USB) | — | since the 09:14 reboot, `usb usb2-port2: Cannot enable. Maybe the USB cable is bad?` every 4 s (185 lines 09:14:34-09:26:48, still going); 0 such lines in the previous boot (10-30 16:09 -> 10-31 09:13); usb2 = the 5000M root hub; PS-E002 + CH340 are on bus 1 (480M hub). Not in the `-71`/`-110` count. History: nothing found |
