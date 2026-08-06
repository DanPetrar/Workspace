# Network migration + futro coordinator handoff — completion plan

**Status:** Implementation (T1-T16) complete, 2026-08-06. All 9 checklist items in
`setup-plan.md` §5 re-run and passing except check 6 (fresh-session context test),
which needs the user to run manually — see `nodes/futro/status.md`'s 2026-08-06 entry
for the full checklist results and the one new finding (futro has no passwordless
sudo). See section 5 below for what's still open.

---

## 1. The problem

The LAN moved from `192.168.110.x` to `192.168.20.x` on 2026-08-01 (`ZaxModbus`
`ac5a60d`). That session fixed and verified Pi, Workstation, and the four ZaxModbus
bench units (A-D). It did **not** touch futro, and left three Workstation docs stale
despite their own stated maintenance policies. Investigated 2026-08-05/06 while
diagnosing an unrelated Unit_B data-loss incident; verified live, not assumed.

### 1.1 Three Workstation docs never updated

| File | Claim | Reality |
|---|---|---|
| `Workstation/INFRASTRUCTURE.md` | "Single authoritative map... update in the same commit" | 8 references to `192.168.110.x`; also describes units publishing to a **Pi**-hosted broker with Workstation remote-subscribing — not how it currently works (§1.3) |
| `Workstation/COORDINATION.md` | "Read this at the start of every Claude Code session on this machine" | 7 stale IP references (Pi, Workstation, Unit A/B/C) |
| `Workstation/inventory.md` | "Maintained... updated whenever..." | Dated 2026-05-27, untouched since; 3 stale references |

`Workstation/STATUS.md` is also stale (dated 2026-06-22) but honestly self-dates, so
it's lower-priority — a reader can tell it's old.

### 1.2 futro was never migrated

futro's own interface IP is correct (`192.168.20.226`, confirmed via `ip addr`), but
everything futro uses to reach the *rest* of the fleet is still on the old scheme:

- `futro:~/.ssh/config` — `ws` → `192.168.110.11`, `bench` → `192.168.110.225`. Both
  **unreachable** (`Connection timed out`, verified live).
- futro's `sshfs` mount of Pi's `boards.json` (`bench:/home/pi/shared`) is consequently
  stale — it was established over the now-dead `bench` alias, so futro currently
  **cannot read `boards.json`**, the one piece of state its own docs call
  "irreplaceable."
- `Workspace/nodes/futro/hardware.md` still shows `192.168.110.8` (itself already an
  approximation — `futro`'s IP changed subnet *and* last octet, `.8` → `.226`, not a
  straight swap). `Workspace/nodes/INDEX.md`'s futro row is correctly updated already
  — the drift is isolated to `hardware.md`.

### 1.3 The documented architecture doesn't match live reality

`INFRASTRUCTURE.md` describes: units → **Pi** broker (`mosquitto` on `.225`) →
Workstation's `zax-parser` remote-subscribes → InfluxDB. Verified live 2026-08-06:
`zax-parser` on the Workstation connects to `BROKER_HOST = "localhost"`. All bench
units publish `mqtt_host` pointed directly at the Workstation. The Pi-relay hop the
docs describe does not exist in the current data path — confirmed this predates
today, not a side effect of anything fixed this session.

### 1.4 The Pi→futro coordinator handoff was never verified complete

`Workspace/nodes/futro/setup-plan.md` §5 has its own 9-point pass/fail validation
checklist from the 2026-07-22 bring-up, with an explicit closing line: *"All 9 must
PASS before treating the coordinator-role transfer as actually complete — until then,
raspi remains the practical coordinator regardless of what the `role` field in
`nodes/INDEX.md` says."* Several of those 9 checks depend on the SSH aliases in §1.2
above and would fail right now purely from the network change (checks 1, 2, 7). There
is no record of the full 9 being re-run and passing since 2026-07-22, before or after
the network change.

### 1.5 Found, not caused by any of the above: Pi's `mosquitto` was already broken

`Workspace/nodes/raspi/status.md` (written 2026-07-22) already documented
`mosquitto.service` as failed since **2026-06-26** — over a month before the network
migration, flagged but never fixed. Root cause (found today): `/etc/mosquitto/conf.d/
conn_log.conf` used `log_type connect` / `log_type disconnect`, which are not valid
mosquitto directives (valid values: `debug error warning notice information subscribe
unsubscribe websockets none all` — mosquitto 2.0.21, confirmed via `man mosquitto.conf`
on the Pi). This is unrelated to the IP migration; the timing overlap with today's
investigation is coincidental.

---

## 2. Current temporary solution (done today, 2026-08-06)

- **Pi's `mosquitto.service` restored.** `conn_log.conf` moved aside
  (`conn_log.conf.disabled-bad-syntax` — not deleted, in case the original intent is
  wanted back later; mosquitto's own defaults already log connect/disconnect at
  `notice` level, so nothing is lost). Verified: `active (running)`, listening on
  `:1883`, real pub/sub round-trip succeeded.
- **Verified, not assumed, that live bench units are unaffected**: Unit_A and Unit_B's
  own `/api/config` both correctly report `mqtt_host: 192.168.20.11` right now. (Unit_C/D
  weren't reachable to check — offline today, not a known config issue.)
  ZaxModbus's own docs/firmware/tooling were already fully fixed in the 2026-08-01
  session and again during today's separate time-sync work; not in scope for this plan.
- **Confirmed clean, no action needed**: no live process, systemd `Environment=`,
  `/opt/*-parser/*.py` deployed script, or `/etc/hosts`/SSH config on Pi or Workstation
  itself references the old subnet.
- **Nothing on futro touched yet.** Its SSH config, `hardware.md`, and the §5
  validation checklist all remain exactly as found in §1.2/§1.4 — this plan is the
  next step before any of that changes.

This is explicitly a **partial, verified-safe** state, not the target — the mosquitto
fix stops a real (if old, unrelated) outage; it does not address futro or the doc
staleness.

---

## 3. Final complete fixed situation (target state)

1. **Workstation's `mosquitto` is the sole documented production broker.** Pi's
   `mosquitto`, now running, is explicitly documented as non-production (local
   dev/testing only) — not silently left ambiguous. `INFRASTRUCTURE.md`'s data-flow
   diagram rewritten to match verified reality: units → Workstation broker directly,
   no Pi-relay hop, `zax-parser` on `localhost`.
2. **All three stale Workstation docs fully corrected** — IPs and architecture
   description both, not just a find-replace on addresses. `STATUS.md` refreshed or
   explicitly left as a dated historical snapshot (call made in the Stage 2 plan).
3. **futro's `~/.ssh/config` corrected** (`ws` → `192.168.20.11`, `bench` →
   `192.168.20.225`), verified: `ssh ws echo ok` and `ssh bench echo ok` from futro,
   both key-based, no password prompt.
4. **futro's `boards.json` sshfs mount re-established and verified readable** over the
   corrected alias.
5. **`nodes/futro/hardware.md` corrected** to `192.168.20.226`.
6. **The full 9-point checklist in `setup-plan.md` §5 re-run end-to-end and passing**,
   including check 6 (fresh-session context test — a brand-new Claude Code session on
   futro, no prior conversation, correctly describes current project state from disk
   alone). Only then is the coordinator-role transfer actually, verifiably complete —
   matching that doc's own bar, not a lower one invented for this plan.
7. **A recorded decision on `boards.json` authority** — `setup-plan.md` already flags
   it as the one irreplaceable piece of state living on Pi's SD card, its most likely
   hardware-failure point. At minimum: a periodic backup in place. Full authority
   relocation is a separate decision this plan should surface but not presume.
8. **`Workspace` docs closed out consistently**: `nodes/futro/status.md`,
   `nodes/raspi/status.md` (mosquitto entry updated to reflect the 2026-08-06 fix),
   and `nodes/INDEX.md` all agree with each other and with verified live state.

---

## 4. Stage 2 (Fable) — task breakdown, implementation plan, test plan

_Verified live 2026-08-06 by Fable, same standard as Stage 1 — every claim below was
re-checked against the running systems, not inferred from Stage 1's summary alone.
Several findings below are new, surfaced only during this verification pass._

### 4.0 New findings beyond Stage 1's scope (verified live)

1. **`Workspace/infrastructure-interaction.md`** calls itself the successor to
   `INFRASTRUCTURE.md` §2-3 and "owns the cross-node picture," dated "verified live
   2026-07-21" — but still shows the legacy units→Pi-broker→WS-remote-subscribe path,
   annotated "currently FAILED." Live check: `zax-parser`'s `BROKER_HOST` has been
   `"localhost"` since 2026-06-24, i.e. before the 2026-07-21 "verification" was even
   written. Also carries 4 stale `192.168.110.x` references. Needs the same
   architecture rewrite as `INFRASTRUCTURE.md`, not just IP fixes.
2. **`Workspace/nodes/workstation/status.md`** — 6 stale `192.168.110.x` references,
   missed by the 2026-08-01 migration commit.
3. **`Workspace/COORDINATION.md`** (root, distinct from the Workstation repo's file of
   the same name) — stale IP in its `ssh ws` example, and its "Node roles" table still
   says "Coordinator — raspi" with no mention of futro, inconsistent with
   `nodes/INDEX.md`'s already-updated `role: coordinator` field for futro.
4. **`Workspace/infrastructure/health-futro.sh`** still enforces the *superseded* rule
   that futro should NOT have `arduino-cli`/`esptool.py`/`boards.json` — `setup-plan.md`'s
   2026-07-22 amendment explicitly reversed this. The health script was never updated to
   match its own project's already-approved decision.
5. **`Workspace/infrastructure/health-pi.sh`** hard-`FAIL`s if `mosquitto` isn't active —
   needs downgrading to `WARN` if Pi's mosquitto is reclassified non-production (§4.1).
6. **Workstation-repo-tracked `infrastructure/zax_parser.py`** has drifted from the
   deployed `/opt/zax-parser/zax_parser.py`: different `BROKER_HOST` (repo says
   `192.168.20.225`, live is `"localhost"`), different `UNITS` dict (repo only has
   Unit_A/C, live also subscribes Unit_B `zax_E482C0` and a 4th topic `zax_F07F8C`). The
   2026-08-01 migration commit edited a value the running service doesn't even use.
7. **futro's own repo clones are stale.** `git fetch` succeeds cleanly on all 9 (passes
   checklist item 4's letter), but nothing has been `git pull`ed since bring-up:
   `Workspace` 7 commits behind, `Workstation` 14, `ZaxModbus` 17,
   `EmonESP_MultiIO-V002` 34. futro's `~/Workspace` doesn't even have
   `infrastructure/health-futro.sh` on disk yet (checklist item 9 requires it). All
   clones have clean working trees — pulling is a safe fast-forward, but must happen
   before re-running the checklist or items 6/9 check stale disk state.
8. **futro's Claude Code CLI is currently behind raspi's**, not equal/ahead: futro
   `2.1.217` vs. raspi `2.1.222` (both self-updating — re-check live numbers at Stage 3
   time, don't reuse these).
9. **`Workstation/inventory.md`'s Claude Code line is wrong, not just stale**: claims
   `2.1.152 ✅ installed`; live check found no `claude` binary anywhere on the
   Workstation. May be intentional (WS is driven by direct SSH, not a local session) —
   flagged as a decision point (§4.7), not silently fixed.

### 4.1 Decision — Pi's `mosquitto` fate

**Keep it running, reclassify as local-dev/test-only. Do not disable.**

- Zero current publishers/subscribers (`ss -tnp | grep 1883` empty; no reference to Pi
  as an MQTT target anywhere in `ZaxModbus` or `Workspace`).
- The ZAX A/B/C/D path has bypassed it since 2026-06-24 — well before today — so "keep
  as fallback for that path" isn't real; there's nothing to fail over to it from.
- It was fixed today specifically to end a real (if old, unrelated) outage; disabling it
  again in the same session with no new information would be pure churn.
- Negligible resource cost, LAN-only, no security exposure beyond what already existed.
- Real minor value: always-available local broker for one-off firmware testing.

Not a destructive action (stays running as-is) — no sign-off needed for this option. **If
the user instead wants it formally disabled**, that reverses this recommendation and is
the one action in this whole plan needing explicit go-ahead before Stage 3
(`sudo systemctl disable --now mosquitto` on Pi) — flagged so it isn't done by default.

### 4.2 Decision — `STATUS.md` handling

**Leave content as-is; add one dated banner, don't refresh.** A full rewrite would just
duplicate `INFRASTRUCTURE.md`/`inventory.md` and risks drifting again independently. The
actual problem is "a reader can't tell it's old," and it already self-dates — cheap fix:

```
> **Historical snapshot only, not maintained since 2026-06-22.** For current service
> state and IPs, see `INFRASTRUCTURE.md` (architecture) and `inventory.md` (tool
> versions). Left as a dated record intentionally, not refreshed by the 2026-08 network
> migration fix.
```

### 4.3 Decision — `boards.json` authority

Surfacing the tradeoff per Stage 1's instruction, with a recommendation, not a unilateral move:

| Option | Pro | Con |
|---|---|---|
| Keep on raspi (status quo) | Co-located with the physical bench; local `flash_guard.py` calls work even if LAN is down | Single point of failure on an SD card |
| Move to Workstation | Real disk, always-on | raspi's *local* bench work would gain a network dependency to reach a file about hardware plugged into raspi itself |
| Move to futro | Consistent with the still-open "futro as primary dev machine" evaluation | Same network-dependency problem; that evaluation is explicitly unresolved — committing now would preempt it |

**Recommendation: leave authority on raspi, add a nightly off-box backup now, defer full
relocation to whenever the still-open "futro as primary" evaluation concludes** — that's
the natural, already-scheduled decision point, not this plan.

```
# raspi crontab (pi user — currently empty, confirmed)
15 0 * * *  rsync -a /home/pi/boards.json ws:/workspace/backups/boards-json/boards.json
```
`/workspace/backups/boards-json/` doesn't exist yet on WS — create it as part of this task.

### 4.4 The futro 9-point checklist

Re-run exactly the 9 checks from `setup-plan.md` §5, no new/smaller set — see §4.6.
Prerequisite: fix futro's SSH config and `git pull` all 9 repos first, or items 1/2/7
(SSH) and 6/9 (disk state) are checked against known-broken/stale state.

### 4.5 Decision — doc rewrite depth

Confirmed live (not assumed from Stage 1): the corrected architecture is **units →
Workstation broker (`:1883`, anonymous) directly → `zax-parser` on `BROKER_HOST =
"localhost"` → InfluxDB → Grafana. No Pi-relay hop exists or has existed since
2026-06-24.** Both `Workstation/INFRASTRUCTURE.md` §1/§2 **and**
`Workspace/infrastructure-interaction.md` need this rewrite (finding 1 above — Stage 1
only scoped the former). Re-verify live subscription topics at Stage 3 implementation
time rather than hardcoding today's snapshot (`zax_E47730`, `zax_E482C0`, `zax_73DA28`,
`zax_F07F8C` seen live today via `systemctl status zax-parser`).

### 4.6 Task list

| ID | Task | Depends on |
|---|---|---|
| T1 | Document Pi mosquitto as local-dev/test-only in `INFRASTRUCTURE.md` §1/§3 + `infrastructure-interaction.md` rule 4; downgrade `health-pi.sh` mosquitto check to `WARN` | — |
| T2 | Fix futro's `~/.ssh/config` (`ws`, `bench` `HostName`s → `192.168.20.11` / `192.168.20.225`) | — |
| T3 | `git pull --ff-only` all 9 repos on futro | — |
| T4 | Restart/verify futro's `sshfs-boards.service` mount of `boards.json` | T2 |
| T5 | Fix `nodes/futro/hardware.md` IP → `192.168.20.226` | — |
| T6 | Rewrite `Workstation/INFRASTRUCTURE.md` §1, §2, §3 rule 4, §4 zax-parser row | 4.5, T1 |
| T7 | Fix `Workstation/COORDINATION.md` IPs; refresh `Workstation/inventory.md` (IPs + live tool versions + resolve Claude-Code-not-installed discrepancy) | — |
| T8 | Add historical-snapshot banner to `Workstation/STATUS.md` | — |
| T9 | Rewrite `Workspace/infrastructure-interaction.md` data-flow/units/rule-4 sections; fix IPs | 4.5, T1 |
| T10 | Fix `Workspace/nodes/workstation/status.md` IPs + refresh services table | — |
| T11 | Fix `Workspace/COORDINATION.md` (root) IP + align "Node roles" table with `nodes/INDEX.md` | — |
| T12 | Fix `infrastructure/health-futro.sh` role-boundary check (toolchain-parity replacement per `setup-plan.md` §5 item 8); confirm `health-pi.sh` change from T1 | — |
| T13 | Sync repo-tracked `infrastructure/zax_parser.py` with the live deployed file (`BROKER_HOST`, `UNITS`) — keep the token placeholder | 4.5 |
| T14 | Re-run the full 9-point checklist end-to-end | T2, T3, T4, T5, T12 |
| T15 | Add `boards.json` nightly off-box backup cron (raspi → ws) | — |
| T16 | Close out `nodes/futro/status.md`, `nodes/raspi/status.md` (mosquitto entry), confirm `nodes/INDEX.md` consistency | T1, T14 |

### 4.7 Implementation notes

- **T2** — futro's current `~/.ssh/config` has `ws`/`bench` still on `192.168.110.x`.
  futro's ed25519 key is already trusted on both raspi and Workstation, so this is a
  pure config edit — no re-keying. Both target IPs already ping from futro.
- **T3** — `for r in <9 repos>; do git -C ~/$r pull --ff-only; done` on futro. All
  clones confirmed clean — should fast-forward cleanly.
- **T4** — `sshfs-boards.service` is currently crash-looping (10s restart cycle,
  `bench` alias dead). Should self-heal within 10s of T2 landing; force it with
  `ssh futro 'systemctl restart sshfs-boards.service'` then verify `cat ~/boards.json`
  returns real JSON.
- **T6/T9** — real rewrite of the data-flow diagram and prose, not a find-replace of
  IPs (see §4.5).
- **T7** — `inventory.md`: for the Claude-Code line, explicitly decide "not installed —
  Workstation is driven via direct SSH, no local session used" vs. actually installing
  it (only if the `COORDINATION.md` GitHub-task-spec fallback needs to be usable in
  practice) — don't leave the current false "✅ installed" claim either way.
- **T12** — `health-futro.sh`'s replacement check (per `setup-plan.md` §5 item 8):
  expect `arduino-cli version` + `arduino-cli core list` to show `esp32:esp32`
  installed, and `~/boards.json` to be a symlink into the sshfs mount (reject if it's a
  plain regular file).
- **T13** — keep `INFLUX_TOKEN` as the placeholder; never commit the real deployed token.

**Irreversible / explicit-go-ahead item:** only disabling Pi's mosquitto (§4.1's
non-default option) needs a stop-and-ask gate beyond this plan's own approval. Everything
else (SSH config edit, doc rewrites, health-script edits, a new cron, `git pull` on clean
trees, restarting an already-broken sshfs service) is low-risk and reversible by further edits.

### 4.8 Test plan

**Per-task**, in brief: T2 → `ssh futro "ssh -o BatchMode=yes ws/bench echo ok"` no
prompt; T3 → `rev-list --count HEAD..origin/main` = 0 for all 9 repos; T4 →
`cat ~/boards.json` returns real JSON, service stays `active (running)` across a 60s
recheck; T5/T6/T7/T9/T10/T11 → `grep -rn 192.168.110` on each file returns nothing, plus
a manual re-read of any rewritten architecture prose against live
`systemctl status zax-parser` output; T12 → `health-futro.sh` reports PASS on
toolchain-parity (not the old absence check), `health-pi.sh` reports WARN not FAIL if
mosquitto is ever stopped; T13 → diff between repo copy and deployed file shows only the
intentional token-placeholder line; T15 → cron-produced backup file matches
`/home/pi/boards.json` byte-for-byte.

**The 9-point checklist** (`setup-plan.md` §5), re-run in full:

1. Key SSH futro→ws: `ssh futro "ssh -o BatchMode=yes -o ConnectTimeout=5 ws echo ok"` — PASS = `ok`, no prompt.
2. Key SSH futro→bench: same shape against `bench`.
3. `ssh futro gh auth status` — PASS = logged in as DanPetrar, protocol ssh.
4. Git fetch over SSH, all 9 repos, no prompts/errors (already reconfirmed live today).
5. `claude --version` on futro ≥ raspi's, compared live at Stage 3 execution time (today's snapshot: futro behind — re-check, don't reuse).
6. **Fresh-session context test — not scriptable.** Manual step for the user: open a
   brand-new (non-resumed) Claude Code session on futro, ask exactly
   *"What is the current state of the ZaxModbus project, and what's the bench fleet's
   firmware version?"* PASS = a specific version string traceable to a file on disk, no
   hedging. Sonnet should flag this as "waiting on you" at the end of Stage 3 rather than
   marking the checklist complete unilaterally.
7. `ssh futro "ssh bench 'python3 ~/flash_guard.py --help'"` — PASS = real usage text printed.
8. `ssh futro 'arduino-cli version; arduino-cli core list; ls -la ~/boards.json'` — PASS
   = version matches raspi's, `esp32:esp32` core listed, `boards.json` is a symlink into
   the sshfs mount (not a plain file).
9. All futro Workspace docs present + correct, checked only **after** T3 (currently
   `health-futro.sh` itself is missing from futro's stale clone).

All 9 must PASS (#6 confirmed by the user, not inferred) before treating the
coordinator-role transfer as verifiably complete. If 1-5 or 7-9 fail after the fixes
above, stop and re-diagnose before asking the user to spend time on the manual check 6.

---

## 5. Final state (2026-08-06)

All 16 tasks done. Summary of what changed:

- **futro**: SSH config fixed (both new IPs verified against independently-confirmed
  host key fingerprints, not blind-trusted); all 9 repos pulled (some were up to 34
  commits behind — never pulled since 2026-07-22 bring-up); `boards.json` sshfs mount
  restored (needed a manual unmount/reconnect beyond the config fix — systemd's own
  `Restart=on-failure` recovered it without needing sudo); `hardware.md` IP fixed;
  Claude Code self-updated to match raspi's version.
- **Workstation**: `INFRASTRUCTURE.md`, `COORDINATION.md`, `inventory.md`, `STATUS.md`,
  and the repo-tracked `zax_parser.py` all fixed — both IPs and the underlying
  architecture claim (no Pi-relay hop has existed since 2026-06-24). Committed + pushed
  (`b7305e4`).
- **Workspace**: `infrastructure-interaction.md`, root `COORDINATION.md`,
  `nodes/workstation/status.md`, `nodes/futro/hardware.md`, `nodes/futro/status.md`,
  `nodes/raspi/status.md`, and both `health-{pi,futro}.sh` scripts fixed. Also found
  and fixed: `infrastructure-interaction.md`'s own 2026-07-21 "verification" had already
  been wrong (checked Pi mosquitto's status but never re-checked `zax-parser`'s actual
  broker target) — documented as a correction, not silently overwritten.
- **Pi**: nightly `boards.json` → Workstation backup cron added and verified
  byte-identical.
- **9-point futro checklist**: 8/9 pass. Check 6 (fresh-session context test) needs the
  user — see `nodes/futro/status.md`.
- **New finding**: futro's user has no passwordless sudo — didn't block anything today,
  flagged for future tasks that need `sudo` there.

**Still open:** check 6 (user action), and the previously-surfaced-and-deferred
questions — full `boards.json` authority relocation (tied to the still-open "futro as
primary dev machine" evaluation) and whether to eventually install Claude Code on the
Workstation itself.
