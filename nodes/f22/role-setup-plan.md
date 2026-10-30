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

## Validation before f22 replaces the raspi on the bench (owner `save` 2026-10-30; not run yet)

| # | Test | PASS when |
|---|---|---|
| V1 | Build parity: same commit 64fd72b + 12 host tests on both machines (raspi after 20:02) | same image size + sha256 (or a named difference); 12/12 on both |
| V2 | Network, read-only, from f22: Influx query, MQTT subscribe on the workstation broker, `/api/sysinfo` of one unit | all three answer; numbers match the same reads from the raspi |
| V3 | esptool 5.x on f22 (pip venv), read-only USB check: chip id + 4 KB read-flash | chip + MAC = `boards.json` |
| V4 | Build -> flash -> smoke on one unit from f22, through the identity guard | smoke PASS; catalog update reaches the raspi file over sshfs |
| V5 | OTA from f22 (`ota_push.py`) | unit reports the new version, image hash matches |
| V6 | pytest L0 (`-m l0 --unit <X>`) from f22 | same result as the same run from the raspi |
| V7 | RS-485/Modbus through an adapter on f22's USB (`-m modbus`) | 0 failed reads in the run |
| V8 | 4 h soak with the unit on f22's USB + one f22 reboot | no USB errors in `dmesg`; port + mount back after the reboot |

V3-V8 need the owner's hands (unit, USB-485 adapter, cables); never Unit_B. After V1-V8 PASS: bench move = catalog
authority + backup cron, Claude memory (D3), mq1884 + zax_directory (D4).
