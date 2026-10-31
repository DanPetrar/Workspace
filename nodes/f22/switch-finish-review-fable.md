# Review of `switch-finish.md` (Fable, 2026-10-31)

Owner's words:
1. "can you prepare a note/doc for f22 claude to continue all tasks to complete the switch procedure and to anounce me when i can power down raspi (at that moment raspi remain as a reserve and can be asigned sor separate tasks)."
2. "ask fable to review you note"

Reviewed file: `/home/pi/Workspace/nodes/f22/switch-finish.md` (53 lines, commit c435d15). I read it against these files: `2026-10-31-switch-close.md`, `switch-plan.md`, `role-setup-plan.md`, `nodes/INDEX.md` and `/home/pi/CLAUDE.md`. The facts were checked read-only on the raspi, f22, futro and ws between 13:15 and 13:30. No unit was contacted.

One thing I ran was not purely read-only: `git fetch -q` in the 7 f22 repos. It updated their remote-tracking refs only.

## Verdict

The note's structure is right. It has a focus line, a "Done when", one step per `go`, the owner's questions asked one at a time, and a ready announcement line. It is not ready to hand over yet, for four reasons:
- 1 blocker: f22 cannot read the note.
- 3 checks would fail or prove nothing as written.
- 1 gate is wider than the owner's request.

## A. Blocker

| # | Finding | Seen | Change |
|---|---|---|---|
| A1 | The note is not on f22. | Raspi Workspace is at `c435d15` (this note), `[ahead 1]`, not pushed. f22 Workspace is at `f38bc52`, and `ls ~/Workspace/nodes/f22/` on f22 has no `switch-finish.md`. The f22 start chain is MEMORY.md line 99, then the close note, then "Next 0: switch-finish.md", which ends at a missing file. | Push Workspace (needs the owner's word, rule 7), then pull on f22. Also correct the "Repos on the raspi" fact line: Workspace is at `c435d15`, not `f38bc52`. |

## B. Checks that fail or prove nothing as written

| # | Step | Finding | Seen | Change |
|---|---|---|---|---|
| B1 | F5 (2), F4 (a) | The f22 session cannot reach futro. | `ssh futro hostname` from f22 gives "Host key verification failed". `ssh-keygen -F 192.168.20.226` on f22 is empty. `Host futro` (192.168.20.226, user dan-futro) is in f22's `~/.ssh/config`. "futro mount source = f22, futro list = 24" and "round trip from futro" therefore cannot run "from f22". | Add a sub-step before F5, done the same way as S3: run `ssh-keyscan 192.168.20.226` on f22 and compare the fingerprint with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on futro. This adds futro's key to f22 `~/.ssh/known_hosts`, a change on f22, so it gets its own `go`. Alternative: run the futro checks from the raspi before it goes off. |
| B2 | F5 (3) | `ss -tn` on the raspi will never show "only f22's ssh + the sshfs client". | Established now: an SSH login from 192.168.20.13 over IPv6 link-local fe80::d0c1… (MAC 68:1d:ef:36:20:20, unidentified, `who`: pts/0 since 10-20), 4 outbound :443 connections to 160.79.104.10 plus 1 to 34.149.66.165 (the two `claude` processes running on the raspi, ages 3 d and 1 d), and the sshfs client to f22:22. | Define the check by listening port: `ss -tn state established '( sport = :1883 or sport = :1884 )'` = 0 lines. List each peer on `sport = :22` by IP; the owner's own login is expected. Outbound connections are not counted. |
| B3 | F6 | "ws `boards.json` mtime is 00:15" is wrong. `rsync -a` keeps the source mtime. | The ws `boards.json` mtime is 11:34:35 (= f22's copy time in S2), but the cron line was run by hand at 11:39 (the ws directory mtime is 11:39:00). After a night with no catalog write, the mtime stays the old one even when the cron ran. | Check with the f22 `journalctl -u cron --since "<date> 00:14" --until "<date> 00:16"` CMD line (rsync …) plus sha256 f22 = ws. Note that cron does not log the rsync rc. |
| B4 | F5 (1) | "`origin/<branch>..HEAD` = 0 in the 7 repos" checks only the current branch of 7 repos. It misses commits that exist only on the raspi. | `git log --branches --not --remotes`: ZaxModbus **2** (local branch `boxlink-0.1.1`, a234b8e/aa4bbee, the paused boxlink track); ZaxEnergySurvey **6** (zax_directory IPs, errors-history); EmonESP_MultiIO-V001 **1** (separate project, count only). Untracked: ZaxModbus 19 run files (PS-Z001 10-13…10-15), ZaxModbus-PS 10 (copied in S11). The 7 named repos are 0 on every branch except Workspace (A1). | Use `--branches --not --remotes` over every repo under `~` (13 found, including `~/Arduino/libraries/ZaxCommon`, which is 0/0). In the announcement, say "kept on the raspi disk only: …" rather than "0 unpushed". Whether they are pushed is the owner's call; the raspi is not wiped, so nothing is lost. |

## C. Gate and scope

| # | Finding | Change |
|---|---|---|
| C1 | The "Done when" (F1-F5 PASS) includes F2 and F3, and neither is needed to power down. F2 is a rule-6 wording change. F3 can be answered "after the row 8 rerun", and row 8 waits for the owner's V7 choices and firmware #98. That answer would hold the announcement for days. The owner asked for two things: finish the switch, and say when the raspi can go off. | Gate the announcement on F1, F4 and F5 only. Keep F2 and F3 as separate items in the same file. Or ask the owner in F3 whether V7 holds the power-down; the default is no. |
| C2 | F2 says the rule-6 line was "proposed at the raspi close". It is not in `2026-10-31-switch-close.md` or in memory. The only record is this note, so the f22 session cannot check that the owner saw it. | Say where it was shown, or present it on f22 as a new proposal (rule 7: exact text, `ok`). |
| C3 | Decision D (S11) was answered when the plan text said "leave on the standby raspi (reachable over ssh)". With the raspi off, `~/ramp-an*` (163 MB) and `~/pigate-bench` (1.3 GB) are no longer reachable. This is the same premise change as B3. F4 re-asks B3 but not D. | Add one owner question in F4 or F5: copy `ramp-an*` / `pigate-bench` to f22 (about 1.5 GB, f22 has about 200 GB free), or accept that they are offline while the raspi is off. |

## D. Corrections and smaller points

1. **Memory freeze time.** The note says "frozen since 12:1x". Raspi `MEMORY.md` and `project_new_futro_s940.md` were written at 13:01:06, and f22's `MEMORY.md` is 13:01:06.96, so a second copy was made then. At 13:19 `rsync -anc` raspi to f22 showed no differences, and both have 175 files. Write "last copy 13:01, equal by checksum". For F1, use a checksum compare instead of the count "175 (or more)".
2. **Raspi Claude sessions still open.** Two `claude` processes are running on the raspi, PID 1833542 (3 d) and 1935138 (1 d). If either writes memory at its close, the f22 copy is behind. Add to F5: no `claude` process on the raspi (`pgrep -a claude`). Any raspi memory write after 13:01 is copied again before the announcement.
3. **F4 (a), the mq1884 move:**
   - Copy `mosquitto.db` (1.85 MB) as well as `mq.conf`. It holds the persistent `zaxlog` session and up to 20,000 queued messages. Stop with SIGTERM by PID first so the database is saved.
   - Create `~/mq1884/` on f22. The `mq.conf` paths are absolute `/home/pi/mq1884/`, which is valid on f22 because the user and home are the same.
   - A `-d` start does not survive an f22 reboot (f22 rebooted today).
   - The #79 note should carry all three S6 items, not only Unit_A `mqtt_host`: `probe_espmqtt.ino:13` URI `.225:1884`, `mqlog.sh` (`127.0.0.1:1884`, then runs on f22), and the async-mqtt `units.yaml` PS-Z001 `esp-devbox64`.
   - futro has `mosquitto_pub`, so the round trip works once B1 is fixed.
4. **F5 (2) "sha f22 = ws backup or newer".** A sha cannot be newer. Write: sha equal, or, if not equal, f22 mtime > ws mtime (a catalog write since the last 00:15 run). That works because rsync keeps the mtime (B3). Now: f22 = ws = c8710b01.
5. **F6 INDEX.** The futro row still says "`boards.json` stays single-authority on raspi via `sshfs`". F6 changes only the raspi row; add the futro row. Cosmetic: futro's mount folder is still named `~/pi-raspi-mnt`, but its source is `bench` = .222 (checked).
6. **F6 CLAUDE.md "now" text.** It is a substring of line 5; the line continues with "Node list: `~/Workspace/nodes/INDEX.md`." Say that this end stays. If F4 = (a), say whether f22's part of line 5 now names mq1884 (Unit_A #79).
7. **Announcement wording.** The raspi is a Raspberry Pi 4 Model B on an SD card (`/dev/mmcblk0p2`) and has no power button. "or the switch" as an equal choice risks a cut without shutdown. Suggested: "`sudo poweroff`, then the supply after the green LED stops". Also say who runs `sudo poweroff`: the owner, or the f22 session on his word.
8. **Weekend rows.** "Nothing here blocks them" is correct; rows 5-8 do not use the raspi (grep). The 10H grid-run README records that `soak_run` ran on the raspi (line 65), so rows 5-7 now run their watchers from f22. One line in the note would prevent a lookup.
9. **Times.** "12:3x" and "12:1x" sit beside an F2 proposal that asks for times from a clock, file or commit. Use the commit times (e.g. `git log -1 --format=%ci`).

## E. Facts in the note, checked

| Fact in the note | Result |
|---|---|
| Catalog authority f22, sha c8710b01, futro + raspi mount it, f22 `sshfs-boards` disabled | Correct: f22 disabled/inactive, no fuse.sshfs mount; futro `bench:/home/pi/shared`, `Host bench` = .222; raspi `sshfs-boards` enabled/active to f22; ws sha c8710b01 |
| Nothing on ws refers to the raspi | Correct for `/etc`, `/opt` and the crontab (6 lines: cal report/prune, gap_watch, errorlog_watch, gap_backfill, none with .225). `~/Workstation/infrastructure/health-pi.sh` names it, but no cron runs it |
| futro crontab: none | futro crontab = `gh-backup.sh` only; no .225 in `/etc/systemd`, `/etc/fstab`, `~/.ssh/config` |
| f22 depends on nothing on the raspi | Correct: crontab = backup line only, no root crontab, no raspi host in `~/.ssh/config`. The unit file `/etc/systemd/system/sshfs-boards.service` still names .225 but is disabled. f22 to raspi ssh works (BatchMode, `esp-devbox64`) |
| mq1884 1884, system 1883, 0 clients | Correct: both listen, 0 established on 1883/1884. mq1884 PID 1716016 since 10-25 |
| Raspi crontab pitemp only | Correct; pitemp writes to the local syslog only. No root crontab; `/etc/cron.d` = e2scrub_all. Custom services: only `sshfs-boards` enabled; `zax_directory`, `zaxmodbus-poller`, `cal_*` disabled/inactive |
| f22 repos | 7/7 at origin (main): home 0f065a3, ZaxModbus-PS 18bc96a, ZaxModbus a677d17, PiGate a30a2c7, Workspace f38bc52 (behind the raspi by the note commit), Workstation a3dfbd8, EnergyCalibrator b279778 |
| `~/identity_guard.py` (not in git) | Same md5 on both machines (986773ab…) |
| CLAUDE.md | Same md5 on both machines (459a821d…), 139 lines; rule 6 line is line 100, as quoted in F2 |
| f22 `usb2-port2: Cannot enable` | Still active: 1,820 dmesg lines at 13:19 (f22 up 4:05). Observation only, as in the note |

## F. Suggested order on f22

1. Owner `push` on the raspi (A1), then pull on f22.
2. F1, compared by checksum (D1, D2).
3. futro host key on f22 (B1).
4. F4, including the decision-D question (C3).
5. F5 with B2/B4/D4 checks, and no `claude` process on the raspi.
6. Announcement.

F2 and F3 run separately (C1). F6 is unchanged, with the corrected B3 check and the D5/D6 text.
