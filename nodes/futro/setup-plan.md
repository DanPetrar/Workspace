# futro — Setup Plan

Plan only — the Futro is not yet acquired, nothing here has been executed. Supersedes
the "Bring-up" stub in `nodes/futro/hardware.md`, which now points here.

**Role-transfer decision this plan implements:** per the updated `role` field in
`nodes/INDEX.md`, the Futro takes over the coordinator role in full — every task
currently run by the Pi's Claude Code session, except the physically-tied
testing-station work (USB/serial/GPIO/RS-485 bench hardware, Arduino toolchain,
`flash_guard.py`/`boards.json`), which stays on `raspi` because it's pinned to
physical cabling, not compute.

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

### 3.1 Prepare install media
1. Download the Debian 13 "trixie" netinst amd64 ISO: https://www.debian.org/distrib/netinst
2. Write to a USB stick: `dd if=debian-13.x.x-amd64-netinst.iso of=/dev/sdX bs=4M status=progress oflag=sync` (or Etcher/Rufus). Double-check `/dev/sdX` is the USB drive before running `dd`.

### 3.2 Boot the Futro from USB
1. Insert the USB stick, power on, press the boot-menu key at startup (F12 is typical on Fujitsu Futro — check the boot splash if not).
2. Select the USB drive. Note whether the boot menu offers a UEFI or legacy entry for it — this decides the partition scheme in section 2.

### 3.3 Run the Debian installer
1. Choose the plain "Install" option (text installer — no desktop needed, this machine runs headless).
2. Language / locale / keyboard: standard choices (English/US or as preferred).
3. **Hostname: `futro`** — matches the node name already reserved in `nodes/INDEX.md`. Domain: leave blank.
4. Network: DHCP to get through the installer. Note the assigned IP — after install, either get a router-side static reservation for it or keep DHCP with a reservation. Record the final IP in `nodes/INDEX.md` once known; this plan can't fabricate an address that hasn't been assigned.
5. Create a personal user account — pick a username and note it down; this is the SSH target going forward (parallel to `dan-linux` on `workstation`).
6. Partitioning: manual/guided-with-override, per the table in section 2.
7. Software selection (tasksel): select only **SSH server** + **standard system utilities**. Deselect any desktop environment.
8. Finish, remove the USB, reboot.

### 3.4 First boot — confirm reachability
1. Log in locally once (keyboard + monitor).
2. `ip addr` — confirm it matches the IP noted in 3.3.4.
3. `systemctl status ssh` — confirm the SSH server is active.

### 3.5 Bootstrap SSH key access (the one step that must happen physically)
The Pi can't SSH in before a key is trusted there, so this leg is manual, at the machine:
1. On the Pi: `cat ~/.ssh/id_ed25519.pub` — copy that line.
2. On the Futro (local session): 
   ```
   mkdir -p ~/.ssh && chmod 700 ~/.ssh
   echo "<paste the Pi's pubkey line>" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```
3. From the Pi: `ssh <futro-user>@<futro-ip> 'echo ok'` — must succeed with no password prompt.

**Human's part ends here.** Everything below runs remotely from the Pi's Claude Code session over that connection.

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

**Do not install:** Arduino IDE / `arduino-cli` toolchain, `esptool`, `flash_guard.py`,
`boards.json`, or any RS-485/serial tooling. These stay `raspi`-only — testing-station
work is pinned to physical cabling, not compute, and doesn't transfer.

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
8. **Role boundary held (negative check):** on Futro, `which arduino-cli esptool.py 2>&1; ls ~/boards.json 2>&1` — all should report "not found." FAIL if any are present.
9. **Workspace docs closed out:** `nodes/futro/hardware.md` has verified (non-"unverified") specs; `nodes/futro/status.md`, `inventory.md`, `setup/` exist; `nodes/INDEX.md` status for `futro` is `active`; `infrastructure/health-futro.sh` exists. FAIL if any are missing.

All 9 must PASS before treating the coordinator-role transfer as actually complete —
until then, `raspi` remains the practical coordinator regardless of what the `role`
field in `nodes/INDEX.md` says.
