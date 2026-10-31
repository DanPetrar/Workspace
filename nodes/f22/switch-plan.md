# Switch: f22 replaces the raspi as the bench machine (plan, 2026-10-31)

Owner 2026-10-31 ~09:45: "i want today to make the switch from raspi to f22. there is a plan for this?" then `save`; Fable review
(`switch-plan-review-fable.md`) merged on the owner's `merge`.
Written only; nothing below has run. Each step runs on its own `go`. Base: `role-setup-plan.md` (D2-D4, "On the day the bench
moves", V1-V14 results). Done when: steps S1-S13 PASS, the raspi still lists the catalog and builds (V14), and the first Claude
session on f22 starts from its own memory with all repos at origin.

## Facts looked up 2026-10-31 09:5x-10:15 (read-only; Fable checked them again)

| Item | Now | Source |
|---|---|---|
| Validation | V1-V6, V8-V13 PASS; V7 on PS-E002: f22 part PASS (200/200), 4 test/firmware failures (owner choices open); **V14 = this file** | `role-setup-plan.md` |
| raspi USB | nothing on `/dev/serial/by-id` (all bench USB is on f22: PS-E002 + CH340) | `ls /dev/serial/by-id` |
| Catalog | authority raspi `~/shared/boards.json` (14,104 B, 10-30 19:12), `~/boards.json` -> `shared/boards.json`; f22 and futro read it over sshfs (`sshfs-boards.service`; futro `Host bench` = 192.168.20.225); f22 `~/boards.json` -> `/home/pi/pi-raspi-mnt/boards.json` (absolute) | `ls`, `systemctl cat`, futro `~/.ssh/config` |
| f22 `~/shared/` | holds `boards.json` 14,107 B, 10-30 12:51 = the home repo's git copy (last commit 10-28), not the live catalog. The home repo tracks both `boards.json` (link) and `shared/boards.json` (file); the raspi shows `M shared/boards.json` | Fable |
| Catalog backup | raspi cron `15 0 * * * rsync -a /home/pi/boards.json ws:/workspace/backups/boards-json/boards.json`. **On ws the file is a symlink `boards.json -> shared/boards.json` dated Aug 14, dangling: `rsync -a` copies the link, so no real catalog backup since 2026-08-14** | `crontab -l`, `ssh ws ls -la` |
| Other raspi cron | pitemp (`vcgencmd`, Pi only) | stays |
| futro | `flash_guard.py` old copy (md5 `5c617c11…`, raspi/f22 `deeff7b9…`): **no G3 fix**; `known_hosts` has no entry for 192.168.20.222; its key is already in f22's `authorized_keys` | Fable |
| mq1884 | `mosquitto -c ~/mq1884/mq.conf -d`, PID 1716016 since 10-25 14:49 (manual start, no service); port 1884, anonymous, persistence in `~/mq1884/` (db 1.85 MB, queued messages for the persistent `zaxlog` client); 0 clients now. **Unit_A's config: `mqtt_host` 192.168.20.225, port 1884** (last connected 10-30 ~14:40); async-mqtt branch `tools/probe_espmqtt/probe_espmqtt.ino:13` hard-codes `mqtt://192.168.20.225:1884`; `tools/zaxtest/mqlog.sh` subscribes to `127.0.0.1:1884` | `ss`, `mq.conf`, Fable |
| mosquitto 1883 (system) | running on the raspi, 0 clients now; not in D4. Tests use the ws broker 192.168.20.11 (`zaxtest/mqtt.py:6`) | `ss`, grep |
| zax_directory | `zax_directory.service` (ZaxEnergySurvey, retired), port 8088, 0 clients; nothing in Workspace, Workstation or ZaxModbus-PS/tools refers to 8088 | `systemctl cat`, Fable |
| Disabled raspi services | `zaxmodbus-poller` (old boards), `cal_collector` / `cal_reports` (moved to ws): nothing moves | Fable |
| `units.yaml` | main: PS-Z001 `mb_host: esp-devbox64` (= raspi, line 16); PS-E002 `mb_host: f22` (line 28). async-mqtt branch: PS-Z001 `esp-devbox64` at line 18 | `units.yaml`, Fable |
| Claude memory | raspi `~/.claude/projects/-home-pi/memory`: 175 files, 1.2 MB; f22 same path exists, 0 files; same user and home (`/home/pi`), so paths in memory stay valid | `ls`, `du` |
| f22 packages | no `mosquitto` (Debian candidate 2.0.21 = raspi 2.0.21), no `~/ZaxEnergySurvey`; raspi has no `sshfs`; f22 `cron` active | `dpkg -l`, `which`, Fable |
| f22 address | `iface eno1 inet dhcp` (dhcpcd), no static entry; **router reservation on .222 (owner 2026-10-31)**. raspi .225 is static | Fable |
| f22 USB (observation) | `usb usb2-port2: Cannot enable. Maybe the USB cable is bad?` every ~4 s since the 09:14 reboot (885 lines by ~10:13), 0 in the previous boot; usb2 = the 5000M root hub; PS-E002 + CH340 are on bus 1. f22 xhci controller `0000:00:15.0` (the raspi's is `0000:01:00.0`) | `dmesg`, Fable |
| Files outside git on the raspi | ZaxModbus-PS: 10 untracked paths (run data `grid-20261028/`, `grid-eth10h-20261029/`, `eth-mode-test-round2/backup/`, `Doc/Async-MQTT/bench-unitA/3-backup/`, the 4 MB `f22-V4/unitA_full_4MB_before.bin`) + `weekend-tests-20261031.md` modified, not committed; Workspace 1 untracked file; outside git: `~/mq1884`, `~/pigate-bench`, `~/ramp-an*`, `~/shared/unitA_*.json` | `git status`, Fable |
| Other references to the raspi | Workstation docs `INFRASTRUCTURE.md`, `inventory.md`, `COORDINATION.md`, `infrastructure/health-pi.sh`; Workspace `infrastructure/zax_parser.py` (`BROKER_HOST .225:1883`, a document copy; ws runs `/opt/zax-parser`); `nodes/INDEX.md`; CLAUDE.md role split and rule 5 | grep, Fable |
| raspi `/tmp` | 89 % full (815 of 923 MB, 608 MB `/tmp/claude-1000`) | Fable |

Constraints:
- Row 4 (weekend list) runs on PS-E002 through f22 until ~10:46 and writes the catalog through f22's mount (`ota_push`, #96).
  **S2-S6 start after row 4 ends.** S1 may run earlier; its sha256 check is repeated after row 4.
- One catalog writer at a time. **Freeze from S2 until the S4 check passes: no flash and no OTA from the raspi, f22 or futro.**
- No step touches a unit; Unit_B never. A unit config write (Unit_A `mqtt_host`) is not in this plan.

## Steps (one `go` each; machine named; check in the last column)

| # | Machine | What | Check | Time |
|---|---|---|---|---|
| S1 | raspi, futro, ws | Backups: raspi `~/shared/boards.json` -> `boards.json.bak-20261031`; to ws as a real file (`rsync -aL`) as `boards.json.20261031`; futro `~/.ssh/config` and `~/.ssh/known_hosts` backups; raspi `crontab -l` to a file | sha256 of the three catalog copies equal; repeated after row 4 ends | 3 min |
| S2 | f22 | Catalog authority to f22: stop + disable `sshfs-boards` on f22; copy raspi `~/shared/boards.json` -> f22 `~/shared/boards.json` (replaces the 10-28 git copy); f22 `~/boards.json` -> `shared/boards.json` (relative, as on the raspi); `git update-index --skip-worktree shared/boards.json` in f22 `~` | sha256 raspi = f22; f22 `flash_guard.py list` = 24 boards; f22 `git status` in `~` clean for both paths | 5 min |
| S3 | futro | Straight after S2. f22 host key into futro `known_hosts` (`ssh-keyscan 192.168.20.222`), fingerprint compared with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on f22; `Host bench` HostName 192.168.20.225 -> 192.168.20.222 (exact line shown first); restart futro `sshfs-boards` | fingerprints equal; futro mount source = f22; futro `flash_guard.py list` = 24. Freeze ends here | 5 min |
| S4 | raspi | raspi reads the catalog from f22: `apt install sshfs`; `sshfs-boards.service` on the raspi (copy of f22's unit, direction reversed: `pi@192.168.20.222:/home/pi/shared` -> `~/f22-mnt`); raspi `~/shared/boards.json` renamed `boards.json.pre-switch-20261031`, raspi `~/boards.json` -> `f22-mnt/boards.json`; `git update-index --skip-worktree boards.json shared/boards.json` in raspi `~` | raspi `flash_guard.py list` = 24; a scratch write from the raspi seen on f22, then removed; raspi `git status` in `~` clean for both paths | 10 min |
| S5 | f22, raspi | Backup cron to f22, fixed: f22 `15 0 * * * rsync -a /home/pi/shared/boards.json ws:/workspace/backups/boards-json/boards.json` (the real file, not the link); remove the line from the raspi crontab. Run the line once by hand | ws file is a regular file, sha256 = f22; raspi crontab has only pitemp | 5 min |
| S6 | raspi, f22 | mq1884 — **only after decision B3**. If (b) move: `apt install mosquitto mosquitto-clients` on f22, disable the system `mosquitto.service` it brings; stop raspi mq1884 by its PID first, then copy `~/mq1884/mq.conf` (+ `mosquitto.db`, optional); start f22 `mosquitto -c ~/mq1884/mq.conf -d` (manual start, does not survive a reboot, same as the raspi); write into the #79 close note: "Unit_A `mqtt_host` -> .222 at resume (unit config write, owner's word), `probe_espmqtt.ino` URI, `mqlog.sh` runs on f22". If (a) stays: nothing | (b): f22 listens on 1884, pub/sub round trip from the raspi to f22:1884; raspi 1884 closed | 10 min |
| S7 | raspi (+ f22) | zax_directory — **after decision A**. Stop (proposal): `disable --now zax_directory` on the raspi, not moved. Move: clone ZaxEnergySurvey on f22, copy the unit file, `enable --now` on f22, `disable --now` on the raspi | stop: raspi 8088 closed. Move: f22 8088 answers like the raspi did (one GET, compared) | 3-10 min |
| S8 | raspi | `units.yaml` (main) PS-Z001 `mb_host: esp-devbox64` -> `f22` (decision C); commit by name. The async-mqtt branch keeps `esp-devbox64` (line 18): noted in the #79 close note for the resume | `python3 -c` load: PS-Z001 mb_host = f22 | 3 min |
| S9 | raspi | CLAUDE.md role split and rule 5: exact new text shown (below), applied after `ok` (rule 7); file stays under 150 lines; commit by name | `grep` both lines; `wc -l` < 150 | 5 min |
| S10 | raspi | `nodes/INDEX.md`: raspi row -> standby (rollback only, until released), f22 row -> testing station + dev toolchain. A note lists the other references (Workstation `INFRASTRUCTURE.md`, `inventory.md`, `COORDINATION.md`, `health-pi.sh`; Workspace `infrastructure/zax_parser.py`), not changed | rows read back | 5 min |
| S11 | raspi, f22 | Files outside git: commit `weekend-tests-20261031.md` (by name). Rest (run data, the 4 MB backup, `~/shared/unitA_*.json`, `~/pigate-bench`, `~/ramp-an*`): **decision D** — rsync to f22, or leave on the standby raspi (reachable over ssh) | `git status` shows the weekend list committed; (rsync) file counts equal | 5-15 min |
| S12 | raspi | V14 rollback test: from the raspi, `flash_guard.py list` = 24 and one `NEWBOX=1 build_s3eth.sh --build-only` of main (no flash; it copies `partitions.csv` into the sketch folder and builds in `/tmp/arduino_build_ZaxModbus_s3eth`, 49 MB; check `/tmp` space first) | rc 0, 24 boards, image hash + build time; `git status` in ZaxModbus-PS clean after the build | 10 min |
| S13 | raspi, f22 | Last step of the raspi session: close note on the raspi, memory line, commit + push all repos; pull the 7 repos on f22 and check HEAD = origin for each; copy the memory raspi -> f22 (`rsync -a`); the raspi memory is frozen from here (no Claude session on the raspi until released) | f22 HEAD = origin x7; memory file count equal, `diff -r` empty; first `claude` on f22 in `~` shows MEMORY.md and this file as the start point | 15 min |

Order: S1 (any time) -> row 4 ends -> S1 sha256 again -> S2 -> S3 -> S4 -> S5 -> S6 (after B3) -> S7 (after A) -> S8-S10 ->
S11 (after D) -> S12 -> S13. Time from the work: ~1 h 30 min of steps after row 4, plus waiting for the owner's words.

## Decisions for the owner (asked one at a time, before the step)

- B3 (S6): mq1884 — (a) stays on the raspi (the raspi stays powered as standby; D4 was decided when the raspi was to leave), or
  (b) moves to f22 (then Unit_A's `mqtt_host` must change at the #79 resume, a unit config write).
- A (S7): zax_directory (retired, 0 clients, nothing refers to 8088) — stop it on the raspi and not move it, or move it (D4).
- C (S8): PS-Z001 `mb_host` -> f22.
- D (S11): files outside git — rsync to f22, or leave on the standby raspi.
- Confirmed (owner 2026-10-31): f22 has a router DHCP reservation on .222 (its address is written into futro, the raspi unit, CLAUDE.md, INDEX).
- Earlier decision kept: the system mosquitto on 1883 stays on the raspi (0 clients; nothing breaks while the raspi is powered).

## S9 proposal (exact text)

Role split, now: `**raspi = testing station + dev toolchain** (this machine, a home directory: the bench over USB/serial/GPIO/RS-485, Arduino
toolchain, `flash_guard.py`/`boards.json`; the current Zax work runs here). **futro = coordinator.** **f22 = raspi replacement in
validation** (Futro S940, 192.168.20.222): toolchain + offline tests; no units, no flash, memory stays on raspi until the owner moves the bench.`

Role split, new: `**f22 = testing station + dev toolchain** (Futro S940, 192.168.20.222, this machine since 2026-10-31: the bench over
USB/RS-485, Arduino toolchain, `flash_guard.py`/`boards.json` authority; the Zax work runs here). **futro = coordinator.**
**raspi = standby** (192.168.20.225): reads the catalog from f22, keeps its toolchain for a rollback (`nodes/f22/switch-plan.md` V14);
no Claude sessions until the owner releases it.`

Rule 5, now: `Known: `error -110`, `error -71`, `unable to enumerate USB device` on this Pi means
the Pi's USB controller is stuck, not the device. Fix:`

Rule 5, new: `Known on the raspi: `error -110`, `error -71`, `unable to enumerate USB device` means
the raspi's USB controller is stuck, not the device (f22: no fix recorded). Fix (raspi only):`

(The fix command line under it stays as it is.) Memory rule `feedback_usb_fault_exclude_host_first` ("Pi restart") is checked at
the session close.

## Known remaining risks

- futro's `flash_guard.py` has no G3 fix: a futro write while its mount is down creates a hidden one-MAC catalog
  (`role-setup-plan.md` G3, "separate question"). Unchanged by this plan.
- The ws backup is one file overwritten each night: a bad catalog replaces the only good backup the next night (dated copies =
  owner's choice; no change proposed).
- (closed 2026-10-31) f22's DHCP address has a router reservation on .222 (owner).

## V14 rollback (one page; run in reverse order, each line undoes one step)

| Step | Undo | Check |
|---|---|---|
| S13 memory | before any Claude session on the raspi: `rsync -a` f22 memory -> raspi (f22 is newer) | file counts equal |
| S12 | nothing (read-only build; `git status` clean) | — |
| S11 | nothing (copies only) | — |
| S10 / S9 / S8 | `git revert` of the commit (CLAUDE.md change again after `ok`) | grep |
| S7 zax_directory | raspi `enable --now zax_directory` (and f22 `disable --now` if moved) | raspi 8088 answers |
| S6 mq1884 (if moved) | kill f22 mq1884 by PID; raspi `mosquitto -c ~/mq1884/mq.conf -d`; Unit_A config not touched by this plan | raspi 1884 listens |
| S5 cron | f22 cron line removed; raspi line back, with `/home/pi/shared/boards.json` (not the link) | ws file regular, sha = raspi |
| S4 raspi mount | copy f22 `~/shared/boards.json` (newest) -> raspi `~/shared/boards.json`; raspi `~/boards.json` -> `shared/boards.json`; stop + disable the raspi `sshfs-boards`; `git update-index --no-skip-worktree boards.json shared/boards.json` in raspi `~` | raspi list = 24, sha = f22's |
| S3 futro | futro `~/.ssh/config` and `~/.ssh/known_hosts` from the S1 backups; restart futro `sshfs-boards` | futro list = 24, source raspi |
| S2 f22 | f22 `~/boards.json` -> `/home/pi/pi-raspi-mnt/boards.json` (absolute, as it was); `enable --now sshfs-boards` on f22; `git checkout -- shared/boards.json` after `--no-skip-worktree` in f22 `~` | f22 list = 24 (via the mount) |

Rule: the catalog has one writer at a time. During a rollback, no flash and no `ota_push` from any machine until the S2-S4 undo
checks pass.

## Progress

- S1 (owner `go`, 10:24): raspi `~/shared/boards.json.bak-20261031`, ws `boards.json.20261031` (regular file), futro
  `~/.ssh/config.bak-20261031` + `known_hosts.bak-20261031`, raspi `~/crontab.bak-20261031` (3 lines); sha256 ee3cff2e x3 PASS.
  After row 4 (run B exit OTA wrote PS-E002 version 1.2.23, last_flash 10:44:35): repeated as `boards.json.bak-20261031b` (raspi)
  and `boards.json.20261031b` (ws), sha256 c8710b01 x3 PASS.
- S2 (owner `go`, 11:34): f22 `sshfs-boards` stopped + disabled, mount gone; raspi catalog copied to f22 `~/shared/boards.json`
  (replaced the 10-28 git copy); f22 `~/boards.json` -> `shared/boards.json`; skip-worktree on both paths (`git ls-files -v` = S S),
  `git status` clean; sha256 raspi = f22 = c8710b01; f22 `flash_guard.py list` = 24. PASS.
- S3: f22 ed25519 fingerprint SHA256:t5WI/2dw…Kxno = futro `ssh-keyscan` (equal); appended to futro `known_hosts`; futro `Host bench`
  HostName .225 -> .222 (one-line diff vs the S1 backup); `ssh bench hostname` = f22; futro `sshfs-boards` restarted, active; futro
  mount lists only `boards.json` (= f22's `~/shared`, the raspi folder has 10 files); sha256 c8710b01; futro list = 24. PASS. Freeze ended.
- S4 (owner `go` + `ok` on the unit file, 11:37): raspi `apt install sshfs` (3.7.3); new `/etc/systemd/system/sshfs-boards.service`
  (f22's unit reversed: `pi@192.168.20.222:/home/pi/shared` -> `/home/pi/f22-mnt`), enabled + active, mountpoint OK; raspi
  `~/shared/boards.json` -> `boards.json.pre-switch-20261031` (sha c8710b01 = no raspi write between S2 and S4); `~/boards.json` ->
  `f22-mnt/boards.json`; skip-worktree on both paths, `git status` clean; raspi list = 24, sha c8710b01; scratch file written from
  the raspi read on f22, removed (f22 `~/shared` = `boards.json` only). PASS.
- S5 (owner `go`, 11:39): f22 crontab = `15 0 * * * rsync -a /home/pi/shared/boards.json ws:/workspace/backups/boards-json/boards.json`;
  run once by hand rc 0: ws `boards.json` now a regular file 14,107 B, sha c8710b01 (the dangling Aug 14 link replaced); raspi
  backup line removed, raspi crontab = pitemp only. PASS.
- Decision B3 (owner `a`): mq1884 stays on the raspi (standby, powered); Unit_A keeps `mqtt_host` .225:1884. S6 = nothing. Replaced by F3 (1) = b below ("powered" no longer holds).
  Replaces D4 for mq1884.
- Decision A (owner `a`): zax_directory stopped on the raspi, not moved (replaces D4 for it).
- S7 (owner `go`, 11:48): before `GET /` on 8088 = HTTP 200; `disable --now zax_directory` on the raspi: inactive, disabled, port
  8088 closed; unit file kept (`/etc/systemd/system/zax_directory.service`). PASS.
- Decision C (owner `a`). S8 (owner `go`, 11:51): main `units.yaml` PS-Z001 `mb_host: f22` (load check: PS-Z001 f22, PS-E002 f22).
  Committed with the row 4 records. **For the #79 resume:** the async-mqtt branch still has `mb_host: esp-devbox64` (line 18). PASS.
- S9 (owner `ok`, 11:55): CLAUDE.md line 5 (role split: f22 testing station, raspi standby with mq1884) and lines 91-92 (rule 5
  USB fix = raspi only) as shown; 139 lines; backup `~/CLAUDE.md.bak-20261031`; home repo commit. PASS.
- S10 (owner `go`, 11:56): `nodes/INDEX.md` raspi row -> standby (rollback), f22 row -> testing station + dev toolchain, active;
  note below the table lists the files still naming the raspi (unchanged). Rows read back. PASS.
- Decision D (owner `a`). S11 (11:56-12:02): rsync `--ignore-existing` raspi -> f22 of the 10 untracked ZaxModbus-PS paths (11 files, ~16 MB)
  to the same paths in f22 `~/ZaxModbus-PS`, and `~/shared/unitA_*.json` (4 files) to f22 `~/shared/`; `sha256sum -c` on f22: 15/15
  equal (rc 0). `~/ramp-an*` (163 MB) and `~/pigate-bench` (1.3 GB) stay on the raspi. PASS.
- S12 (owner `go`, 12:02:21-12:06:13, raspi): `flash_guard.py list` = 24 (catalog from f22); `NEWBOX=1 ./build_s3eth.sh --build-only`
  rc 0: 1,328,400 B, sha256 53cd4892…, built 12:06:10, string 1.2.23 (differs from 29a2b5db by the compile time, V1); nothing in
  `ota/`; ZaxModbus-PS `git status`: no tracked file changed. V14 "raspi still builds and lists the catalog": PASS.
- Times of S2-S11 corrected 12:07 from file and commit times (my first entries had guessed times).
- S13 (owner `go`, ~12:15): close note `2026-10-31-switch-close.md`; memory lines (MEMORY.md, `project_new_futro_s940.md`: IP = DHCP);
  pushed Workspace a583bbf, ZaxModbus-PS 18bc96a, home 0f065a3; f22 pulled, 7 repos HEAD = origin (home 0f065a3, ZaxModbus-PS 18bc96a,
  ZaxModbus a677d17, PiGate a30a2c7, Workspace a583bbf, Workstation a3dfbd8, EnergyCalibrator b279778); futro pulled. Memory copied
  raspi -> f22 (`rsync -a`; f22 had no memory folder): 175 = 175 files, `diff -r` empty. Raspi memory frozen from here. PASS.
  **Switch done** (S6 nothing by B3). Not yet seen: the first Claude session on f22.
- F1 (`switch-finish.md`, 13:30, f22): first Claude session on f22 started from the close note. Memory raspi -> f22 `rsync -anci --delete`:
  0 lines (control against an empty folder: 176 lines), 175 = 175 files; MEMORY.md line 99 "f22 = bench machine" present; newest raspi
  memory file 13:01. PASS. The note's `rsync -anc` has no `-i`, so it prints nothing even with differences; use `-anci` (also in F4 (4)).
  Raspi `claude` PIDs 1833542 + 1935138 still run (F4 (4)).
- F2 (owner `go`, 13:32:02, f22): futro ed25519 fingerprint keyscan = futro's key file (`SHA256:LyZhiVNz…Lw`, read over the raspi);
  `ssh -o BatchMode=yes futro hostname` = futro. PASS. `known_hosts` 12 -> 16 lines, not the 1 line on the card: keyscan's comment line + the
  ed25519 line (my 1-line guard did not stop it, not looked into), then ssh itself added futro's rsa + ecdsa keys at the first connection, hashed
  (lines 15-16, sent over the checked connection). All kept. Before: scratchpad copy of this session only.
- F3 (1) (owner `b`, 2026-10-31): mq1884 stays on the raspi; the raspi is powered on again when #79 resumes. While it is off, Unit_A has no
  MQTT broker. Nothing moved, nothing installed on f22. #79 note: `ZaxModbus-PS/Doc/Async-MQTT/2026-10-31-mq1884-raspi-off.md`.
- F3 (2) (owner `a`, 13:38:57-13:39:36): `~/ramp-an`, `ramp-an2`-`6`, `~/pigate-bench` copied raspi -> f22 (`rsync -a`, same paths; replaces decision D
  for these). Bytes (`du -sb`) and file counts equal on all 7 (files 5, 5, 6, 5, 8, 18, 437), `rsync -anci` 0 differences. Raspi copies kept. PASS.
  Owner, same reply: "the pigate will no longer be available; pc-gate will remain the on focus for Gate project."
- F4 first run (13:40-13:41, read-only, from f22): **not all PASS, no announcement.** (4) FAIL: raspi `claude` PIDs 1833542 + 1935138 still run; 0 raspi memory
  files newer than 13:01:10. (1) 16 repos found (13 + home, esp-idf, hello_world): only on the raspi ZaxModbus 2 commits + 19 untracked, ZaxEnergySurvey 6,
  EmonESP V001 1; ZaxModbus-PS 11 untracked all equal on f22 (`rsync -anci`). Not in git and not on f22, by top-level name: `mq1884`, `EmonESP_MultiIO*`,
  `ZaxEnergySurvey`, `ArduinoIDE_project`, `PiGate-spec-lab`, `s940-build`, `esp`, `.espressif`, CLAUDE.md / flash_guard `.bak` files. (2) PASS: f22 list 24, futro
  mount `bench:/home/pi/shared` + 24, sha f22 = ws c8710b01. (3) PASS: 0 clients on 1883/1884; ssh peers .222 (this check) + fe80::d0c1:9f1b:8733:7a22 (pts/0 since
  10-20, not identified). (5) PASS: crontab pitemp only, only `sshfs-boards` enabled.
- F4 re-run (13:51:48-13:51:55, after the owner's "closed"): (4) still FAIL: PID 1935138 gone; PID 1833542 runs, state `Tl` (stopped job, Ctrl-Z) on pts/0, parent bash
  1374863, 0 network connections. 0 raspi memory files newer than 13:01. (1), (2), (3) same as the first run.
- F4 final (owner `kill`, 13:55:52): PID 1833542: SIGTERM + SIGCONT at about 13:54 did not end it (`Dl`, then `Tl` again), SIGKILL ended it. All PASS: (1) raspi only ZaxModbus 2 +
  19 untracked, ZaxEnergySurvey 6, EmonESP V001 1, plus the folders of the first run; (2) f22 24, futro `bench:` 24, sha f22 = ws c8710b01; (3) 0 clients on 1883/1884, ssh peers
  .222 + fe80::d0c1:9f1b:8733:7a22; (4) no `claude`, 0 raspi memory files newer than 13:01, f22 differs only by its own later write (MEMORY.md + 1 new file); (5) pitemp only, `sshfs-boards` only.
  Power-down announcement sent to the owner. F5 runs when he says the raspi is off.
- Raspi off (owner `poweroff`, 13:57:36, `sudo -n poweroff` from f22, rc 0): no ping answer at 13:57:47. Supply cut = the owner's.
- F5 same day (13:57:54): f22 list 24; futro mount `bench:/home/pi/shared`, list 24. INDEX raspi, futro, f22 rows updated; memory line. PASS so far.
  Open: next-morning check 2026-11-01 (`journalctl -u cron` 00:14-00:16 rsync CMD line, sha256 f22 = ws); CLAUDE.md line 5 text after `ok`.
