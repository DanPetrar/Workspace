# Session close 2026-10-31 ~12:15 — switch done: f22 is the bench machine; raspi = standby

Last raspi session. **The next Claude session runs on f22** (`claude` in `~`). Base: `nodes/f22/switch-plan.md` (plan, progress,
V14 rollback); Fable review `switch-plan-review-fable.md` (merged). Supersedes `2026-10-30-evening-close.md` as the start point.

## State now

- **f22** (192.168.20.222, DHCP): catalog authority `~/shared/boards.json` (`~/boards.json` -> `shared/boards.json`, skip-worktree on
  both), nightly backup cron 00:15 to ws (real file); PS-E002 (fw 1.2.23 29a2b5db, boot 58) + CH340 on its USB; CLAUDE.md role line
  says f22 = testing station.
- **raspi** (.225): standby. Reads the catalog from f22 (`sshfs-boards.service` -> `~/f22-mnt`); keeps mq1884 (port 1884, Unit_A #79,
  owner B3 = a) and system mosquitto 1883; zax_directory stopped (A = a); backup cron removed (pitemp only). No Claude session on the
  raspi until the owner releases it; its memory is frozen after the S13 copy.
- **futro**: `Host bench` -> .222, mounts f22's `~/shared`; its `flash_guard.py` still has no G3 fix (known risk).
- ws catalog backup: was a dangling link since 08-14; now a real file + dated copies `boards.json.20261031` / `…b`.

## Done today

- f22 validation complete: V8 night soak 12/12 hours PASS (`report.md` FAIL = tool, WISHLIST #99), V12 PASS, f22 reboot PASS,
  V13 CH340 PASS. Observation: since the 09:14 f22 reboot `usb usb2-port2: Cannot enable` every ~4 s (usb2 = 5000M root hub; the bench
  USB is on bus 1); not judged.
- Weekend row 4 (#67, 1800 s gap): 1.2.22 control 1000 s missing, 1.2.23 0 missing / 0 duplicates: PASS (`ZaxModbus-PS/Doc/VeryHigh-plan-analysis.md` §7).
- Switch S1-S13 (S6 = nothing by B3); decisions B3 a, A a, C a, D a.

## Next (on f22)

0. Switch finish: `nodes/f22/switch-finish.md` (F1-F6, raspi power-down announcement).
1. Weekend list `ZaxModbus-PS/Doc/new-hardware/weekend-tests-20261031.md`: rows 5-7 need the grid place (owner moves PS-E002);
   row 8 waits for the owner's V7 choices (TS_007 = #98 fix, TS_001 / TS_006 rewrite, NB_004 rule).
2. Done (owner 2026-10-31): f22 has a DHCP reservation on .222 (its address is in futro's ssh config, the raspi unit, CLAUDE.md, INDEX).
3. #79 resume notes: Unit_A `mqtt_host` stays .225:1884 (broker on the raspi); the async-mqtt branch `units.yaml` PS-Z001 still `esp-devbox64`.
4. Open from earlier: D3 option A text (restore depth in the user documents); S3-Zero 1.2.23 image on PS-Z001 when back.

## Repos at the close

See the S13 progress line in `switch-plan.md` (hashes after the push, f22 pulls).
