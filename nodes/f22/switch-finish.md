# Switch finish — for the Claude session on f22 (written on the raspi 2026-10-31 ~12:40)

Owner 2026-10-31: "can you prepare a note/doc for f22 claude to continue all tasks to complete the switch procedure and to anounce
me when i can power down raspi (at that moment raspi remain as a reserve and can be asigned sor separate tasks)."

Read first: `2026-10-31-switch-close.md` (state), `switch-plan.md` (S1-S13 done, V14 rollback). CLAUDE.md rules 1-9 apply: each
step below on its own `go`, decisions asked one at a time, report numbers. Weekend tests (`ZaxModbus-PS/Doc/new-hardware/weekend-tests-20261031.md`
rows 5-8) may run in between; nothing here blocks them.

**Done when:** F1-F5 PASS and the owner has the announcement line of F5. After that, F6 runs when the owner says the raspi is off.

## Facts at the handover (raspi, 12:3x, read-only)

- Catalog: authority f22 `~/shared/boards.json` (sha c8710b01 at 11:34); futro and the raspi mount it; f22 depends on nothing on the raspi
  (its `sshfs-boards` is disabled).
- Nothing on ws refers to the raspi: `/opt`, `/etc/systemd/system`, `/etc/mosquitto`, ws crontab: no `192.168.20.225` / `esp-devbox64`.
  futro crontab: none. Units and tests publish to the ws broker 192.168.20.11.
- Still only on the raspi: mq1884 (port 1884; **Unit_A's config `mqtt_host` 192.168.20.225:1884**, #79 paused; owner B3 = a "stays on
  the raspi" assumed the raspi stays powered), system mosquitto 1883 (0 clients), `~/ramp-an*` (163 MB), `~/pigate-bench` (1.3 GB),
  `~/ZaxEnergySurvey` (zax_directory stopped), the frozen raspi memory copy.
- Repos on the raspi: all pushed at 12:3x (Workspace f38bc52, ZaxModbus-PS 18bc96a, home 0f065a3).

## Steps

| # | What | Check | Who |
|---|---|---|---|
| F1 | First-session check (last part of S13): this session started from the close note and reads the copied memory | `ls ~/.claude/projects/-home-pi/memory | wc -l` = 175 (or more); MEMORY.md line "f22 = bench machine since 2026-10-31" present; one line in `switch-plan.md` progress | Claude |
| F2 | CLAUDE.md rule 6 line, proposed at the raspi close (exact text below); apply after the owner's `ok`; commit by name, push on his word | `grep` the line; `wc -l` < 150 | owner `ok` |
| F3 | f22 validation verdict. V7 on PS-E002: f22 part PASS (200/200 positive control), 4 failures are test/firmware (`PS-E002/f22-V7-20261030/v7-investigation-fable.md`). Ask the owner one question: accept V7 for f22 now, or after the row 8 rerun. Then write "f22 validated <date>" in `role-setup-plan.md` | the line in the plan | owner |
| F4 | mq1884 before the raspi goes off. Ask the owner one question: (a) move mq1884 to f22 now (plan S6 as written: `apt install mosquitto mosquitto-clients`, disable the system service it brings, stop the raspi broker by PID, copy `~/mq1884/mq.conf`, start on f22 with `-d`; Unit_A's `mqtt_host` is changed only at the #79 resume, a unit config write with his word), or (b) leave it on the raspi and power the raspi on again when #79 resumes. Record the answer in `switch-plan.md` (replaces B3) and in the #79 notes (`ZaxModbus-PS/Doc/Async-MQTT/`) | (a): f22 listens on 1884, pub/sub round trip from futro; raspi 1884 closed. (b): the note | owner |
| F5 | Power-down readiness, read-only, from f22: (1) raspi repos: `git log origin/<branch>..HEAD` = 0 in the 7 repos on the raspi, over ssh; (2) catalog: f22 list = 24, futro mount source = f22, futro list = 24, sha f22 = ws backup or newer; (3) `ss -tn` on the raspi: no established connection from units or other machines except f22's own ssh and the raspi's sshfs client; (4) nothing on the raspi that runs for others: mq1884 per F4, system 1883 0 clients, crontab pitemp only. Then send the announcement line below | all four PASS | Claude |
| F6 | After the owner says the raspi is off: f22 list = 24; futro mount + list = 24; at 00:15 the f22 backup cron runs — next morning ws `boards.json` mtime is 00:15 of that night; INDEX raspi row -> "reserve (powered off <date>)"; CLAUDE.md raspi text -> reserve (exact text shown, after `ok`); memory line. Commit by name; push on his word | the checks; one line per repo | Claude + owner words |

Announcement line (F5), when all four checks PASS:
`Raspi: you can power it down now (sudo poweroff, or the switch). Checks PASS: repos 0 unpushed x7, catalog only on f22 (24 boards), no clients on the raspi, mq1884 <moved / stays: #79 needs the raspi on at resume>. It stays the reserve; power-on = V14 rollback possible.`

## F2 exact text (rule 6)

Now: `- Details go in the record file; give the path.`
New: `- Details go in the record file, with times from a clock, a file or a commit (never estimated); give the path.`

## F6 proposal for CLAUDE.md (exact text, show again before applying)

In line 5, now: `**raspi = standby** (192.168.20.225): reads the catalog from f22, keeps mq1884 (port 1884, Unit_A #79) and its toolchain for a rollback (`nodes/f22/switch-plan.md` V14); no Claude sessions until the owner releases it.`
New: `**raspi = reserve** (192.168.20.225, powered off since <date>): toolchain kept for a rollback (`nodes/f22/switch-plan.md` V14) or separate tasks the owner assigns; no Claude sessions on it until he does.`
(If F4 = b, add after "rollback": `, mq1884 for #79`.)

## Notes for the f22 session

- The raspi memory is frozen since 12:1x; f22's copy is the only one written from now on.
- When the raspi is powered on again for a rollback or a task: its `sshfs-boards` mounts f22's catalog automatically (enabled unit),
  its mq1884 does not start by itself (manual `-d` start).
- Open owner observations, not judged: f22 `usb usb2-port2: Cannot enable` every ~4 s since the 09:14 reboot (bus 2; the bench USB is on bus 1).
