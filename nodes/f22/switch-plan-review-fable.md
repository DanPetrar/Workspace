# Review of switch-plan.md (f22 replaces the raspi), by Fable, 2026-10-31

Plan reviewed: `/home/pi/Workspace/nodes/f22/switch-plan.md`. Base: `role-setup-plan.md`, CLAUDE.md, `weekend-tests-20261031.md`.
Method: I only read things. I ran read-only commands on the raspi, on f22, on futro and on ws, around 10:00-10:15. I did not contact any unit and changed nothing.

## Verdict

**The plan can be used after some changes.** Its facts table is mostly correct, and its main finding is real: the ws catalog backup has been a dangling symlink since 08-14. Three things would fail or lose data if the steps run as written (B1-B3). Seven more things should be fixed before the go (S-a to S-g).

## Facts checked

| Plan fact | Seen | Result |
|---|---|---|
| raspi `~/shared/boards.json` 14,104 B, 10-30 19:12; `~/boards.json -> shared/boards.json` | same | correct |
| ws backup is a dangling symlink since Aug 14 | `/workspace/backups/boards-json/boards.json -> shared/boards.json`, and the `shared/` folder does not exist | correct |
| raspi cron: backup + pitemp | same 2 lines; root crontab empty | correct |
| mq1884 PID 1716016, port 1884, 0 clients | same; 0 established connections on 1883/1884/8088 | correct |
| zax_directory on 8088, retired | enabled + active, `WorkingDirectory=/home/pi/ZaxEnergySurvey/collector` | correct |
| `units.yaml` PS-Z001 `mb_host: esp-devbox64` (line 16), PS-E002 `f22` (line 28) | same on main; the f22 hostname is `f22` | correct |
| memory 175 files | 175 | correct |
| futro `Host bench` = 192.168.20.225 | same; futro `sshfs-boards` mounts `bench:/home/pi/shared` | correct |
| f22 has no mosquitto; the raspi has no sshfs | same; Debian candidate mosquitto 2.0.21 = raspi 2.0.21 | correct |
| **"f22 `~/shared/` exists, empty"** | **holds `boards.json` 14,107 B, 10-30 12:51 (the git copy of the home repo, last commit 10-28)** | **wrong** (see S-a) |
| (not in the plan) f22 address | `iface eno1 inet dhcp` (dhcpcd), no static entry | missing (see S-c) |
| (not in the plan) f22 USB | 885 lines `usb2-port2: Cannot enable` since the 09:14 reboot, still appearing at uptime 3537 s | missing (see S-g) |

## Blocking: fix before the step runs

**B1. futro writes the catalog to the wrong place between S2 and S4.**
- Between S2 and S4, futro still mounts the raspi's `~/shared`. Any catalog write from futro in that window goes to the old raspi file and is lost.
- After S3 renames the raspi's `shared/boards.json`, futro's `~/boards.json` link dangles.
- futro's `flash_guard.py` is the old copy: md5 `5c617c11…`, while raspi and f22 have `deeff7b9…`. It does not have the G3 fix, so a futro write in that window creates a new one-MAC `boards.json` in the raspi's `~/shared`. That is exactly the G3 failure.
- Change:
  - Extend the freeze line in S2 to futro: "no flash or OTA from the raspi or futro until the S4 check passes".
  - Run S4 straight after S2, before S3.

**B2. S4 fails on the host key.**
- futro's `known_hosts` has no entry for 192.168.20.222 and none for the `bench` alias. `sshfs-boards` runs under systemd without a terminal, so it cannot accept a new host key and the mount fails.
- futro's key is already in f22's `authorized_keys`, so login itself works.
- Change:
  - In S4, before the restart, add f22's host key to futro's `known_hosts` (by `ssh-keyscan`). Compare its fingerprint with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on f22.
  - Back up futro's `known_hosts` in S1 and add it to the rollback.

**B3. S6 cuts Unit_A off from its broker, and the plan does not say so.**
- Unit_A's config has `"mqtt_host":"192.168.20.225","mqtt_port":1884` (V4 backups, `Doc/Async-MQTT/bench-unitA/f22-V4/config-*.json`).
- On the async-mqtt branch, `tools/probe_espmqtt/probe_espmqtt.ino:13` has the address hard-coded: `mqtt://192.168.20.225:1884`.
- `tools/zaxtest/mqlog.sh` subscribes to `127.0.0.1:1884`, so it only works on the machine that runs the broker.
- Unit_A last connected to mq1884 on 10-30, around 14:40 (`mq.log`).
- After S6, resuming #79 needs a config write to Unit_A, which is a unit change and needs the owner's word.
- Add an owner decision before S6, with two options:
  - (a) mq1884 stays on the raspi. The raspi stays powered as standby, and D4 was decided when the raspi was expected to leave.
  - (b) Move it, and record in the #79 close note: "Unit_A `mqtt_host` -> .222 at resume (unit config write), `probe_espmqtt.ino` URI".

## Should fix

**S-a. f22 `~/shared/` is not empty, and the home repo tracks the live catalog.**
- The home repo tracks both `boards.json` (the link) and `shared/boards.json` (the file). The raspi already shows `M shared/boards.json`.
- After S2, f22 will show `M` as well. After S3, the raspi will show `D shared/boards.json` and a changed link.
- On f22, `git checkout -- .`, `git stash` or `reset --hard` in `~` would then replace the new catalog authority with the 10-28 copy.
- Change:
  - In S2, also run `git update-index --skip-worktree shared/boards.json` on f22, as was done for `boards.json` on 10-30. Check that `git status` is clean.
  - Do the same on the raspi after S3, for both paths.
  - Correct the facts line.

**S-b. The wait for row 4 must cover S2 as well.**
- Row 4 writes the catalog through f22's mount (`ota_push`, #96). It is running now: pytest PID 1527 on f22, started 09:38:30, `ZAX_MQ005_GAP_S=1800`.
- If S2 runs during row 4, there are two risks:
  - Once the mount is stopped, `flash_guard` stops with the G3 error and the test fails part-way.
  - A write made after the copy lands on the raspi file and is lost.
- Change: the constraint becomes "S2-S5 after row 4". S1 may run earlier, but repeat its sha256 check after row 4.

**S-c. f22's address comes from DHCP.**
- After the switch, 192.168.20.222 is written into:
  - the raspi's sshfs unit,
  - futro's `Host bench`,
  - Unit_A's `mqtt_host` (if B3 option b),
  - CLAUDE.md and INDEX.md.
- The raspi has a static address (.225, no `dynamic` flag). I could not see whether the router has a reservation for f22's MAC.
- Add one line to the facts table: "f22 IP: DHCP; reservation: owner to confirm".

**S-d. Nothing pulls the repos on f22 after the last raspi push.**
- f22's home repo is at 48c4f5d now. S8, S9 and S10 commit on the raspi (the plan does not name the machine), and S12 pushes.
- Change:
  - Name the machine in S8, S9 and S10.
  - Add to S12: pull the 7 repos on f22 and check that HEAD = origin, before the first Claude session on f22.

**S-e. Files outside git stay only on the raspi.**
- ZaxModbus-PS on the raspi has 10 untracked paths:
  - run data in `grid-20261028/`, `grid-eth10h-20261029/` and `eth-mode-test-round2/backup/`,
  - `Doc/Async-MQTT/bench-unitA/3-backup/`,
  - the 4 MB backup `f22-V4/unitA_full_4MB_before.bin`.
- It also has 1 uncommitted change: **`weekend-tests-20261031.md` (modified, not committed)**.
- Workspace has 1 untracked file. Outside git: `~/mq1884`, `~/pigate-bench`, `~/ramp-an*`, `~/shared/unitA_*.json`, `~/identity_guard.py` (already copied).
- The memory points to some of these paths, so a Claude session on f22 would not find them.
- Add a step before S12:
  - Commit or copy `weekend-tests-20261031.md`, otherwise the first f22 session starts from a stale list.
  - The owner decides for the rest: rsync the ZaxModbus-PS run files to f22, or leave them on the standby raspi, reachable over ssh.

**S-f. CLAUDE.md rule 5 has a USB fix that only fits the raspi.**
- Rule 5 tells you to unbind/rebind `0000:01:00.0`, "on this Pi". f22's xhci controller is `0000:00:15.0`.
- After S9, "this machine" is f22, so the first USB fault there would get the Pi command.
- Change: in S9, also show the exact new rule 5 text, for example "on the raspi … Fix (raspi): …; f22: no known fix recorded". Apply it after `ok`, keeping the file under 150 lines.
- The memory rule `feedback_usb_fault_exclude_host_first` ("Pi restart") should be checked at the session close.

**S-g. The f22 USB observation is not in the facts table.**
- `usb usb2-port2: Cannot enable. Maybe the USB cable is bad?` appears every ~4 s: 885 lines since 09:14 and still appearing. There were 0 in the previous boot. PS-E002 and the CH340 are on bus 1.
- This is reported as an observation only (rule 4). It belongs in the facts table so the go for S2 is given knowing it.

## Minor

- **M1, rollback of S2:** f22's link was absolute, `/home/pi/pi-raspi-mnt/boards.json`. Restore it in that form, not as a relative link.
- **M2, S6:**
  - Stop the raspi broker before copying `mosquitto.db`. It saves every 30 min; the last save was at 09:54.
  - The db (1.85 MB) holds queued messages for the persistent `zaxlog` client, so copying it is optional.
  - The versions match (2.0.21), so the db format is compatible.
  - The manual `-d` start does not survive an f22 reboot (same as on the raspi).
- **M3, S5:**
  - rsync of a regular file onto the existing symlink replaces the link, so the S5 check works.
  - f22 `cron` is active.
  - One backup file overwritten every night means a bad catalog replaces the only good backup the next night. Dated copies are the owner's choice; I propose no change.
- **M4, S11 is not fully read-only:**
  - The command needs `NEWBOX=1`; `build_s3eth.sh:44` refuses without it.
  - The script copies `partitions.csv` into the sketch folder (line 94) and builds in `/tmp/arduino_build_ZaxModbus_s3eth` (49 MB, reused).
  - The raspi's `/tmp` is 89 % full: 815 of 923 MB, of which 608 MB is `/tmp/claude-1000`.
  - Add the check: `git status` clean after the build.
- **M5, decision A:** nothing in Workspace, Workstation or ZaxModbus-PS/tools refers to port 8088. "Stop on the raspi, do not move" avoids cloning a retired project and installing its dependencies.
- **M6, facts table:** add one line for the disabled raspi services: `zaxmodbus-poller` (old boards) and `cal_collector`/`cal_reports` (moved to ws). Nothing moves.
- **M7, async-mqtt branch:** S8 changes main only. The branch still has `mb_host: esp-devbox64` for PS-Z001 at line 18, so `gate.py` would skip that line on f22 when #79 resumes.
- **M8, references to the raspi address:** the raspi system broker 1883 stays (decision B), so nothing breaks. Still, these files refer to .225 or the raspi:
  - Workstation docs: `INFRASTRUCTURE.md`, `inventory.md`, `COORDINATION.md`, `health-pi.sh`.
  - Workspace `infrastructure/zax_parser.py` (`BROKER_HOST .225:1883`). This is a document copy; ws runs `/opt/zax-parser`.

  The S10 note should list them, not only `health-pi.sh`.
- **M9, rollback table** misses:
  - futro's `known_hosts` entry,
  - the skip-worktree flags,
  - Unit_A's config (if B3 option b).
- **M10, futro's `flash_guard.py`:** it stays without the G3 fix after the switch. The plan should list this as a known remaining risk. It is still the "separate question" from `role-setup-plan.md` G3.

## Suggested order after the changes

1. S1 any time.
2. After row 4 ends: repeat the S1 sha256 check.
3. S2 with skip-worktree.
4. S4 with the host key.
5. S3.
6. S5.
7. S6 after the owner's B3 decision.
8. S7 after decision A.
9. S8-S10, naming the machine.
10. The S-e step: files outside git, and commit the weekend list.
11. S11.
12. S12, with the pull on f22.
