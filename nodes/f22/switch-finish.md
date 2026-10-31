# Switch finish — for the Claude session on f22 (written on the raspi 2026-10-31, commit c435d15 13:16; Fable review merged)

Owner 2026-10-31: "can you prepare a note/doc for f22 claude to continue all tasks to complete the switch procedure and to anounce
me when i can power down raspi (at that moment raspi remain as a reserve and can be asigned sor separate tasks)."
Review: `switch-finish-review-fable.md` (merged on the owner's `merge`).

Read first: `2026-10-31-switch-close.md` (state), `switch-plan.md` (S1-S13 done, V14 rollback). CLAUDE.md rules 1-9 apply: each
step below on its own `go`, decisions asked one at a time, report numbers, times from a clock, a file or a commit.

**Done when (power-down):** F1, F2, F3, F4 PASS and the owner has the announcement line of F4. Then F5 runs when he says the raspi is off.
F6 and F7 (rule 6 line, V7 verdict) are separate and do not hold the power-down.

Weekend tests (`ZaxModbus-PS/Doc/new-hardware/weekend-tests-20261031.md` rows 5-8) may run in between; none uses the raspi. Rows 5-7:
the 10H grid run's `soak_run` ran on the raspi (`PS-E002/grid-eth10h-20261029/README.md` line 65); from now on such watchers run from f22.

## Facts at the handover (raspi + Fable, 13:15-13:30, read-only)

- Catalog: authority f22 `~/shared/boards.json` (sha c8710b01, f22 copy time 11:34:35); futro (`bench` = .222, folder still named
  `~/pi-raspi-mnt`) and the raspi (`~/f22-mnt`) mount it; f22 depends on nothing on the raspi (its `sshfs-boards` is disabled; the
  disabled unit file still names .225). ws backup sha c8710b01.
- Nothing on ws or futro refers to the raspi: ws `/opt`, `/etc`, crontab (6 lines) none; futro crontab `gh-backup.sh` only, no .225 in
  `/etc/systemd`, `/etc/fstab`, `~/.ssh/config`. `Workstation/infrastructure/health-pi.sh` names the raspi; no cron runs it.
  Units and tests publish to the ws broker 192.168.20.11.
- **f22 cannot ssh to futro yet:** "Host key verification failed" (`Host futro` = 192.168.20.226, user dan-futro, is in f22's
  `~/.ssh/config`; no known_hosts entry).
- Still only on the raspi:
  - mq1884 (port 1884, PID 1716016 since 10-25; `~/mq1884/mosquitto.db` 1.85 MB = persistent `zaxlog` session + up to 20,000 queued
    messages). **Unit_A's config `mqtt_host` 192.168.20.225:1884** (#79 paused). Owner B3 = a ("stays on the raspi") assumed the raspi
    stays powered. Also tied to .225:1884: async-mqtt `tools/probe_espmqtt/probe_espmqtt.ino:13`; `tools/zaxtest/mqlog.sh` subscribes
    to `127.0.0.1:1884` (runs where the broker is); async-mqtt `units.yaml` PS-Z001 `esp-devbox64`.
  - system mosquitto 1883 (0 clients).
  - `~/ramp-an*` (163 MB), `~/pigate-bench` (1.3 GB): owner D = a ("leave on the standby raspi, reachable over ssh") assumed the raspi on.
  - `~/ZaxEnergySurvey` (zax_directory stopped).
  - Commits only on the raspi (`git log --branches --not --remotes`): ZaxModbus 2 (local branch `boxlink-0.1.1`, a234b8e/aa4bbee,
    paused boxlink track), ZaxEnergySurvey 6, EmonESP_MultiIO-V001 1 (separate project, count only). Untracked: ZaxModbus 19 run files
    (PS-Z001 10-13…10-15). The 7 main repos: 0 on every branch once Workspace is pushed.
- Memory: last copy raspi -> f22 at 13:01 (MEMORY.md 13:01:06 on both), equal by checksum at 13:19 (`rsync -anc`), 175 files.
- Two `claude` processes run on the raspi at 13:27 (PID 1833542, 3 d; PID 1935138, 1 d; one is the session that wrote this note).
- The raspi is a Raspberry Pi 4 Model B on an SD card (`/dev/mmcblk0p2`); no power button.
- Observation (not judged): f22 `usb usb2-port2: Cannot enable` since the 09:14 reboot, 1,820 dmesg lines at 13:19.

## Steps (power-down path)

| # | What | Check | Who |
|---|---|---|---|
| F1 | First-session check: this session started from the close note and reads the copied memory; memory equal to the raspi copy | `rsync -anc pi@192.168.20.225:~/.claude/projects/-home-pi/memory/ ~/.claude/projects/-home-pi/memory/` lists nothing (run from f22); MEMORY.md line "f22 = bench machine since 2026-10-31" present; one line in `switch-plan.md` progress | Claude |
| F2 | futro host key on f22 (a change on f22, own `go`): `ssh-keyscan -t ed25519 192.168.20.226` on f22, fingerprint compared with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on futro (read over the raspi, or shown by the owner), then appended to f22 `~/.ssh/known_hosts` | fingerprints equal; `ssh -o BatchMode=yes futro hostname` from f22 works | Claude |
| F3 | Two owner questions, one at a time, because both earlier answers assumed the raspi stays on: (1) mq1884: (a) move it to f22 now, or (b) leave it on the raspi and power the raspi on again when #79 resumes. (2) `~/ramp-an*` + `~/pigate-bench` (~1.5 GB; f22 has ~200 GB free): copy to f22, or accept they are offline while the raspi is off. Then, if (1a): create f22 `~/mq1884/`; `apt install mosquitto mosquitto-clients`, disable the system `mosquitto.service` it brings; stop the raspi mq1884 with SIGTERM by PID (saves the db); copy `mq.conf` + `mosquitto.db` (paths `/home/pi/mq1884/` are valid on f22); start `mosquitto -c ~/mq1884/mq.conf -d` (does not survive an f22 reboot). If (2) copy: `rsync -a` raspi -> f22 same paths. Record the answers in `switch-plan.md` (replace B3 / D) and in the #79 notes (`ZaxModbus-PS/Doc/Async-MQTT/`): Unit_A `mqtt_host`, `probe_espmqtt.ino:13` URI, `mqlog.sh` place, async-mqtt `units.yaml` PS-Z001 | (1a): f22 listens on 1884, pub/sub round trip from futro (`mosquitto_pub`) to f22:1884, raspi 1884 closed. (1b): the note. (2) copy: file counts + `du` equal | owner, then Claude |
| F4 | Power-down readiness, read-only, from f22: (1) every repo under the raspi `~` (13 incl. `~/Arduino/libraries/ZaxCommon`): `git log --branches --not --remotes` count + untracked count; list what stays on the raspi disk only (expected now: ZaxModbus 2 + 19 untracked, ZaxEnergySurvey 6, EmonESP V001 1); (2) catalog: f22 list = 24; futro mount source = f22, futro list = 24; sha f22 = ws, or if different, f22 mtime > ws mtime (a catalog write since the last 00:15 run); (3) raspi `ss -tn state established '( sport = :1883 or sport = :1884 )'` = 0 lines; peers on `sport = :22` listed by IP (the owner's own login is expected); outbound connections not counted; (4) `pgrep -a claude` on the raspi = none (the owner closes the raspi sessions); if any raspi memory file is newer than 13:01, copy again and repeat the F1 check; (5) raspi crontab = pitemp only; only `sshfs-boards` enabled among the custom services. Then send the announcement line | all PASS | Claude |
| F5 | After the owner says the raspi is off: f22 list = 24; futro mount + list = 24; next morning: f22 `journalctl -u cron --since "<date> 00:14" --until "<date> 00:16"` shows the rsync CMD line and sha256 f22 = ws (cron does not log the rsync rc; the ws file keeps the source mtime). INDEX: raspi row -> "reserve (powered off <date>)", futro row: "boards.json single-authority on raspi via sshfs" -> "on f22 via sshfs (`bench` = .222)". CLAUDE.md raspi text -> reserve (exact text below, shown again, after `ok`). Memory line. Commit by name; push on his word | the checks; one line per repo | Claude + owner words |

Announcement line (F4), when all checks PASS:
`Raspi: you can power it down now: sudo poweroff (you, or I on your word), then the supply after the green LED stops. Checks PASS: catalog only on f22 (24 boards), 0 clients on 1883/1884, no Claude session on the raspi, memory equal on f22. Kept on the raspi disk only: <list from F4 (1)>. mq1884 <moved to f22 / stays: #79 needs the raspi on at resume>. It stays the reserve; power-on = V14 rollback possible.`

## Separate items (do not hold the power-down)

| # | What | Who |
|---|---|---|
| F6 | CLAUDE.md rule 6 line. It was shown to the owner in the raspi session (the reply right after the S13 push, commit 07aa923 12:18:38) and not answered; present it again on f22 as a proposal (rule 7: exact text, apply after `ok`; `wc -l` < 150; commit by name, push on his word). Now (line 100): `- Details go in the record file; give the path.` New: `- Details go in the record file, with times from a clock, a file or a commit (never estimated); give the path.` | owner `ok` |
| F7 | f22 validation verdict. V7 on PS-E002: f22 part PASS (200/200 positive control), 4 failures are test/firmware (`PS-E002/f22-V7-20261030/v7-investigation-fable.md`). One question: accept V7 for f22 now, or after the row 8 rerun. Then "f22 validated <date>" in `role-setup-plan.md` | owner |

## F5 proposal for CLAUDE.md (exact text, show again before applying)

In line 5, now: `**raspi = standby** (192.168.20.225): reads the catalog from f22, keeps mq1884 (port 1884, Unit_A #79) and its toolchain for a rollback (`nodes/f22/switch-plan.md` V14); no Claude sessions until the owner releases it.`
New: `**raspi = reserve** (192.168.20.225, powered off since <date>): toolchain kept for a rollback (`nodes/f22/switch-plan.md` V14) or separate tasks the owner assigns; no Claude sessions on it until he does.`
The rest of line 5 (` Node list: `~/Workspace/nodes/INDEX.md`.`) stays. If F3 (1) = b, add after "rollback": `, mq1884 for #79`.
If F3 (1) = a, the f22 part of line 5 also gets `, mq1884 (port 1884, Unit_A #79)` after "`flash_guard.py`/`boards.json` authority".

## Notes for the f22 session

- The raspi memory is frozen after the last copy; f22's copy is the only one written from now on.
- When the raspi is powered on again for a rollback or a task: its `sshfs-boards` mounts f22's catalog by itself (enabled unit);
  its mq1884 does not start by itself (manual `-d` start).
