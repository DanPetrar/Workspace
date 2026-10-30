# Session close 2026-10-30 19:25 — 1.2.23 done on PS-E002; f22 V8 night soak RUNNING

Supersedes the 16:52 note for the start point. Base: `nodes/f22/role-setup-plan.md`; ZaxModbus-PS
`Doc/VeryHigh-plan-analysis.md` (1.2.23 steps 1-8); weekend list `ZaxModbus-PS/Doc/new-hardware/weekend-tests-20261031.md`.

## Running: f22 V8 night soak (do not start a second copy)

f22 PID 2378 (setsid, started 19:21:10): `soak_run run --unit PS-E002 --hours 12 --period 10 --out
ZaxModbus-PS/Doc/new-hardware/PS-E002/f22-V8-night-20261030`. First records ~19:50; judged hours 20:00 -> 08:00; `report.md` ~08:02.
Start: PS-E002 fw 1.2.23 (29a2b5db), boot 54, MQTT connected; f22 dmesg -71/-110 count 0; f22 up since 16:09:14.
Rule per hour: SEC >= 3599 per phase, unreachable <= 1, Modbus 360/360, energy match, boot +0. Run: dmesg count stays 0, survives
the logout. Prediction: 12/12 PASS, boot 54 throughout. Find processes with `ps -eo pid,args | grep "[z]axtest.soak_run"`
(`pgrep -f` over ssh matches its own command line).

**Morning:** judge V8 (hours.json, report.md, dmesg); V12 (`journalctl` no suspend/sleep, uptime from 16:09); one f22 reboot
(ports, mount, 24 boards); V13 CH340 replug x3 (owner's hands); then the weekend list.

## Done today after 16:52

- V8 first run stopped by the owner at 18:2x (1 of 4 h, hour PASS); run folder `f22-V8-20261030/` on f22, not in git.
- WISHLIST: Fable priority list (`Doc/WISHLIST-by-priority-fable.md`), VeryHigh plan (`Doc/VeryHigh-plan-fable.md`), my analysis
  (`Doc/VeryHigh-plan-analysis.md`), #98 + pointers in #56 / #92.
- **1.2.23** (#89 aborted OTA, #67 replay order; owner D1-D3; code by Sonnet, reviewed): builds s3eth 29a2b5db, s3zero a431a0e8,
  TESTMODE s3eth 115a4b62; PS-E002 bench via f22: MQ-005 600 s PASS (1.2.22 control lost 399 s), aborted OTA + OTA same boot PASS.
  WISHLIST #67 / #89 fixed, #74 merged into #91 (High). Commit 0ebea84, pushed.

## Repos (19:25)

ZaxModbus-PS main 0ebea84, Workspace main 52f0c6f (+ this note), home 48c4f5d: pushed; f22 and futro pulled.
Not in git: run folders on f22 (`f22-V8-20261030/`, `f22-V8-night-20261030/`), the 4 MB Unit_A backup.
Open decisions: Fable's V7 choices (TS_007 = #98 fix, TS_001 / TS_006, NB_004 rule).
