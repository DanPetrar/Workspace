# futro — Setup Plan

**Bring-up completed 2026-07-22** — see `nodes/futro/status.md` for the executed
result. This file is kept as the historical plan; sections below are marked where
reality diverged.

## Amendment 2026-07-22 — dev-toolchain split reversed (Fable-reviewed)

Section 4.5 below and validation check #8 in section 5 originally made
arduino-cli/esptool/`flash_guard.py`/`boards.json` **raspi-exclusive**, reasoning that
testing-station work is pinned to physical cabling. **User direction 2026-07-22:**
futro is physically co-located next to the bench, so that reasoning no longer holds —
boards/USB cables can be plugged into whichever machine is doing that day's work.
Futro now gets full software-toolchain parity with raspi; raspi keeps every
capability it has today (nothing removed), narrowing only in day-to-day practice as
the machine that holds the permanent bench (Units A-D, RS-485 bus).

This was reviewed via a Fable-model pass (same review style as the original Workspace
structure) before being acted on — see that review's reasoning in the session it ran.
Net effect: section 4.5's "do not install" list is reversed (now: do install, matching
raspi's versions); check #8 is superseded (see section 5 note); `boards.json` becomes
network-shared (`sshfs` mount from raspi) rather than raspi-exclusive, so there's
never two independently-writable copies. Full corresponding updates: `nodes/INDEX.md`,
`nodes/futro/hardware.md`, `nodes/raspi/hardware.md`, `infrastructure-interaction.md`
rules 2-3.

Supersedes the "Bring-up" stub in `nodes/futro/hardware.md`, which now points here.

**Role-transfer decision this plan implements (as originally written — see the
2026-07-22 amendment above for what changed):** per the updated `role` field in
`nodes/INDEX.md`, the Futro takes over the coordinator role in full — every task
currently run by the Pi's Claude Code session, except the physically-tied
testing-station work (USB/serial/GPIO/RS-485 bench hardware, Arduino toolchain,
`flash_guard.py`/`boards.json`), which stays on `raspi` because it's pinned to
physical cabling, not compute. **The toolchain-exclusivity part of this paragraph is
superseded — see the amendment above.**

---

## 1. Linux version

Debian 13 (trixie) x86_64 — already decided, matching `raspi`'s OS exactly (see
`nodes/raspi/hardware.md`). Install media: the **netinst amd64 ISO** from
debian.org. Use whatever the current 13.x point release is at install time — don't
pin to a specific point release now, and re-verify `raspi`'s exact `/etc/os-release`
at install time rather than trusting this file.

## 2. Partition scheme

Hardware: 500 GB SSD, 8 GB DDR4, Celeron (thin-client class). Job: Claude Code CLI +
git clones of ~9 project repos — no local database, no heavy storage (that stays on
`workstation`). Design favors simplicity over flexibility not yet needed:

| Partition | Size | FS | Mount | Purpose |
|---|---|---|---|---|
| ESP | 512 MB | vfat | `/boot/efi` | EFI system partition — **only if the Futro boots UEFI**; check BIOS mode at install time (see 3.2.2) |
| swap | 8 GB | swap | — | 1:1 with RAM; safety margin for a Celeron running an agent session + tools |
| root | remainder (~490 GB) | ext4 | `/` | everything else, single partition |

No LVM, no separate `/home`/`/var`/`/tmp`. This is a single-user coordination node
with no multi-tenant or storage-growth pressure that would justify the extra layers —
if that changes later, repartition then, not speculatively now.

If the Futro's firmware turns out to be legacy BIOS only (older Fujitsu thin clients
sometimes are), drop the ESP row and use MBR partitioning instead — confirm boot mode
live during install, don't guess from this doc.

## 3. Human install prep (step by step)

**Full detail (screen-by-screen, every command, written for someone with no Linux
experience):** see [`install-guide.md`](install-guide.md). Summary of what it covers:
prepare a USB installer (balenaEtcher), boot the Futro and note UEFI vs. Legacy/BIOS,
run the Debian graphical installer end-to-end (hostname `futro`, user account, the
partition scheme from section 2 above entered manually screen-by-screen, SSH-server-only
software selection, GRUB), first-boot verification (`ip addr`, `systemctl status ssh`),
and the one unavoidable physical step — bootstrapping SSH trust by pasting the Pi's
public key into Futro's `authorized_keys` locally.

**Human's part ends once that SSH bootstrap succeeds.** Everything below runs remotely
from the Pi's Claude Code session over that connection.

## 4. Pi-Claude completes the rest

Precondition: step 3.5.3 succeeds. For convenience during bring-up only, add a
temporary `Host futro-bootstrap` block to the Pi's own `~/.ssh/config` pointing at
that user@IP; retire it once 4.6 sets up the permanent aliases.

### 4.1 System baseline
- `apt update && apt full-upgrade -y`
- Match timezone/locale to the Pi if the installer defaults didn't already.

### 4.2 Claude Code CLI
- **VERIFY the current official install method before running it** — don't assume a command. Check docs.claude.com or ask the `claude-code-guide` agent. (Reference: the Pi runs a self-updating standalone binary, `~/.local/bin/claude` → `~/.local/share/claude/versions/<version>`, currently `2.1.216` — install the same way, whatever version is current at install time.)
- Confirm `claude --version` runs after install.

### 4.3 git identity
```
git config --global user.name "DanPetrar"
git config --global user.email "delazax@zapptronic.eu"
git config --global init.defaultBranch main
```

### 4.4 GitHub CLI + auth
- Install `gh`.
- Copy `~/.config/gh/hosts.yml` from Pi to Futro over the bootstrap connection (`scp`) — reuses the existing DanPetrar OAuth token instead of an interactive device-code login. Confirm: `gh auth status` on Futro should report logged in as `DanPetrar`, protocol `ssh`, scopes `repo, admin:public_key, gist, read:org`.
- Generate a **new, Futro-specific** SSH keypair for git — do not copy the Pi's private key: `ssh-keygen -t ed25519 -C "delazax@zapptronic.eu"`.
- Register it: `gh ssh-key add ~/.ssh/id_ed25519.pub` (run on Futro, using the copied gh auth).

### 4.5 Clone the project repos
`gh repo clone DanPetrar/<repo>` for each, directly under Futro's home directory
(flat layout, matching the Pi's existing convention):
`ZaxModbus`, `Workstation`, `Workspace`, `EnergyCalibrator`, `EmonESP_MultiIO`,
`EmonESP_MultiIO-V001`, `EmonESP_MultiIO-V002`, `ZaxEnergySurvey`, `ArduinoIDE_project`.

~~**Do not install:** Arduino IDE / `arduino-cli` toolchain, `esptool`, `flash_guard.py`,
`boards.json`, or any RS-485/serial tooling. These stay `raspi`-only — testing-station
work is pinned to physical cabling, not compute, and doesn't transfer.~~

**SUPERSEDED 2026-07-22 — see the amendment at the top of this file.** Futro is
co-located with the bench, so this exclusivity was reversed: `arduino-cli` (matching
raspi's version) + the ESP32 core + ESP-IDF + Arduino libraries + `flash_guard.py` are
now installed on futro too. `boards.json` is the one exception that isn't a plain
copy — it stays single-authority on raspi, reached via an `sshfs` mount, so there's
never two independently-writable catalogs.

### 4.6 SSH — both directions
- **Futro → workstation:** from the Pi (already has passwordless access), append the Futro's new public key to workstation's `authorized_keys`: `ssh ws 'echo "<futro pubkey>" >> ~/.ssh/authorized_keys'`. Add a `ws` host block to Futro's `~/.ssh/config` (`HostName 192.168.110.11`, `User dan-linux`), mirroring the Pi's existing one. Confirm `ssh ws 'echo ok'` from Futro, key-based, no prompt.
- **Futro → raspi (new — for testing-station commands):** append the Futro's public key to the Pi's own `~/.ssh/authorized_keys` (local, on the Pi). Add a host block to Futro's `~/.ssh/config`, e.g. `Host bench` → `HostName 192.168.110.225`, `User pi` — the new alias the coordinator needs to reach the Pi now that Pi is the executor for hardware tasks. Confirm `ssh bench 'echo ok'` from Futro.
- Remove the temporary `futro-bootstrap` block from the Pi's `~/.ssh/config` — no longer needed once both permanent directions work.

### 4.7 CLAUDE.md
- Copy `~/CLAUDE.md` from Pi to Futro as a starting point — not a verbatim transfer. The Environment / System Details sections describe the Pi specifically (Raspberry Pi hardware, GPIO/serial context) and will be wrong for Futro; rewrite those to describe the Futro's actual role (coordination hub, no physical bench hardware attached). Keep GitHub Integration, Interaction Rules, and Behavioral Guidelines as-is — those are account/process conventions, not machine-specific.
- Add a plain line to both machines' `CLAUDE.md` stating the split: Futro = coordinator, Pi (raspi) = testing station — so a fresh session on either machine knows its own scope without relying on memory.

### 4.8 Memory — do not attempt to transfer
- `~/.claude/projects/-home-pi/memory/` is generated by the Pi's own Claude Code instance, keyed to its own project path and session history. Copying the files to Futro would not "restore" memory — a fresh session there has no access to past conversations regardless of what sits on disk, and nothing in this bring-up should be framed as fixing that.
- What a fresh coordinator instance genuinely needs on day one is what's already durable and file-based: `CLAUDE.md` (4.7), the cloned repos (4.5), and this Workspace repo's own docs (`nodes/INDEX.md`, each node's `status.md`/`inventory.md`). Those are the actual mechanism by which any fresh session, on any machine, reconstructs current project state — bring-up's job is to keep them accurate and present, not to move memory files.
- Optional, non-essential: the Pi's raw memory files may be copied to Futro as read-only reference (e.g. `~/legacy-pi-memory/`) for manual grepping — label it clearly as reference material, not live memory, since the harness won't load it as such.

## 5. Validation / test plan

Concrete, run in order, each with an unambiguous pass/fail:

1. **Key-based SSH, Futro → workstation:** `ssh ws 'echo ok'` from Futro returns `ok`, no password prompt.
2. **Key-based SSH, Futro → raspi:** `ssh bench 'echo ok'` from Futro returns `ok`, no password prompt.
3. **gh auth:** `gh auth status` on Futro — logged in as `DanPetrar`, protocol `ssh`. FAIL on any other account/protocol.
4. **Git over SSH:** for each of the 9 cloned repos, `git -C ~/<repo> fetch` succeeds with no password/passphrase prompt. FAIL if any repo prompts or errors.
5. **Claude Code installed:** `claude --version` succeeds, version ≥ the Pi's version at time of bring-up (compare live — don't hardcode `2.1.216`, it will be stale by then).
6. **Fresh-session context test:** start a new Claude Code session on Futro, no prior conversation. Prompt: "What is the current state of the ZaxModbus project, and what's the bench fleet's firmware version?" PASS only if the answer cites specifics traceable to files on disk (a version string from `ZaxModbus`'s own docs or `Workspace/nodes/*/status.md`), not something only knowable from memory. If it hedges or has to ask for the info, FAIL — `CLAUDE.md`/repo docs aren't sufficient yet.
7. **Reverse testing-station round-trip:** from Futro, `ssh bench 'python3 ~/flash_guard.py --help'` (or another harmless read-only call) returns Pi-side output. Confirms Futro can direct testing-station work without local tooling. FAIL if unreachable or if Futro needed local tooling to get there.
8. ~~**Role boundary held (negative check):** on Futro, `which arduino-cli esptool.py 2>&1; ls ~/boards.json 2>&1` — all should report "not found." FAIL if any are present.~~ **SUPERSEDED 2026-07-22** — this check tested for the opposite of the current target state. See the amendment at the top of this file. Replacement check: `arduino-cli version` + `arduino-cli core list` (expect `esp32:esp32` installed, matching raspi's version) and `ls -la ~/boards.json` (expect a symlink into an `sshfs` mount of raspi's copy, not a local file).
9. **Workspace docs closed out:** `nodes/futro/hardware.md` has verified (non-"unverified") specs; `nodes/futro/status.md`, `inventory.md`, `setup/` exist; `nodes/INDEX.md` status for `futro` is `active`; `infrastructure/health-futro.sh` exists. FAIL if any are missing.

All 9 must PASS before treating the coordinator-role transfer as actually complete —
until then, `raspi` remains the practical coordinator regardless of what the `role`
field in `nodes/INDEX.md` says.
