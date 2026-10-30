# S940 fresh-install stick: verification of v2 (Fable, 2026-10-30)

Input: the owner's words 1-13 (2026-10-30), `s940-stick-plan-v2.md`, `s940-install-guide-v2.md`,
the first review `s940-review-fable.md`, v1 plan and guide.
Read-only lookups made for this verification (nothing installed, no USB device or other machine touched):
`lsblk` and `/sys/block` on the Pi, real sysfs paths of the Pi's USB devices,
`which busybox dash checkbashisms shellcheck xorriso`, `df /home/pi`,
`gh repo view` of `rpi-claude-config` and `Workspace`, `~/.gitignore`, `nodes/INDEX.md`.
Points marked **(from memory)** are my knowledge of debian-installer, not checked here.

## Verdict

**Not ready to build: 3 blockers (V1-V3), 6 fixes (V4-V9).** All first-review points are carried into v2
(table below). The owner's words 8-12 are applied: one S940 (`f22`), user `pi`, SSH password login on.
The new blockers are all in the pick-disk part (step 4), the one part that can erase the wrong disk.
V1 comes from my own first review (B3 wording); it is wrong there too.

## Blockers

**V1. The test "real path has no `/usb/`" never matches a USB disk (checked on the Pi).**
Real sysfs paths of USB devices have components `usb1`, `usb2`, `1-1`, `1-1:1.0`, never a bare `usb`:
`/sys/devices/platform/scb/fd500000.pcie/.../0000:01:00.0/usb1/1-1/1-1:1.0`.
So every USB disk passes the filter. The stick itself is still left out by the `/cdrom` rule, but a
USB disk plugged in with no internal SSD would be the one disk left, and it would be erased.
Fix: leave out a disk when its real path matches `*/usb[0-9]*`. Also accept only device names `sd*` and
`nvme*n*`, so `loop*`, `ram*`, `zram*`, `mmcblk*`, `sr*` never enter the list. Size from
`/sys/block/<dev>/size` (512-byte sectors, always).

**V2. The pick-disk script does not reach the ISO.** Step 6 maps three files (`preseed.cfg`, `grub.cfg`,
`txt.cfg`); `s940-pickdisk.sh` is not one of them, so `partman/early_command` has nothing to run.
Fix: add `-map s940-pickdisk.sh /s940-pickdisk.sh`, call it as `sh /cdrom/s940-pickdisk.sh` (no exec bit
needed on iso9660), and add it to the step 6 "extract and check" list. Or put it inline in the preseed.

**V3. "Error screen, the installer stops before any write" is not specified and not proven.**
(from memory) A preseeded command that exits non-zero gives "Failed to run preseeded command" and
returns to the installer main menu. What runs next at priority critical is not checked. If partman
then starts without `partman-auto/disk` set and sees one disk, it can choose that disk by itself.
Fix: in the failure branch, the script writes the reason to the log and to the screen and then
**never returns** (a sleep loop). The installer stays on the partitioner progress screen. No write can follow.
Guide Part 6 step 4: add "the partitioner screen does not move for 5 min: photo, [STOP]".
Test on the hardware (owner's decision, new D5, ~5 min of hands): in Part 3, after the 32 GB SSD
is out and before the 220 GB goes in, boot the automated entry with **no internal SSD**. It must stop on
that screen. This is the only test of the fail path that can be done with no risk.

## Fixes before the build

**V4. The dry run on the Pi will not refuse as written.** `mmcblk0` is 62.5 GB
(122138624 sectors), its path has no USB part, and 62.5 GB is inside the 25-300 GB band. The v2 script
would accept it: "must refuse: SD only" is wrong. With the name filter of V1 it refuses for the right
reason. The script needs a dry-run mode: sysfs root as a parameter, and print instead of
`debconf-set` (that command does not exist on the Pi). Run the dry run with three
cases: the Pi as it is (refuse), a fake sysfs tree with one `sd*` at 220 GB (accept), and one with
`sd*` + a USB `sd*` (accept only the non-USB disk).

**V5. `bash -n` is the wrong check.** The installer runs busybox `ash`; there is no bash. `bash -n`
passes bashisms that fail there. Use `#!/bin/sh`; check with `busybox sh -n` and `dash -n` (both are on the
Pi; `checkbashisms` and `shellcheck` are not); do the dry run under `busybox sh`.

**V6. Add `d-i partman-efi/non_efi_system boolean true`** (from memory). With a UEFI boot and a disk that
holds a BIOS-mode system (eLux can be one), the installer asks "Force UEFI installation?".

**V7. Add `d-i mirror/country string manual`** to the step 3 list and the step 6 grep (from memory: without it
`mirror/http/hostname` and `directory` are not used and the mirror question returns).

**V8. Menu order and D2.** (from memory) In the Debian 12/13 netinst `boot/grub/grub.cfg`, the first entry is
**"Graphical install"**, not "Install". Guide Part 6 step 1 says the highlighted first line is plain "Install".
The plan must say that `grub.cfg` (and `txt.cfg`) are rewritten so that plain "Install" is first (or
`set default` points at it). Step 6 check: grep the first `menuentry`. Also, D2 is still "open" in the plan
table while the guide treats it as decided. Close D2, or mark Part 6 as depending on it.

**V9. S3: name the key source.** Say where the Debian CD signing key comes from
(`https://www.debian.org/CD/verify`) and compare its fingerprint with that page before `gpg --verify`. A key
fetched from the same mirror as the ISO proves little.

## Smaller points

- Plan step 5 kernel line still has `<HOSTn>`: write `f22`. Guide Part 1: "used on both S940": S940 #2 is not planned.
- Secrets: `rpi-claude-config` is **PRIVATE** (checked), `Workspace` is PUBLIC, there is no `~/.gitignore`.
  Staging by name keeps `~/s940-build/` out; the plan's `$6$` grep before the commit is right. Pi free space
  24 GB: enough for the ISO.
- `late_command`: set the owner with `in-target chown -R pi:pi /home/pi/.ssh`. The uid is the one in the
  target system, not the installer's.
- After the install, add to the check: `lsblk` shows EFI 512 MB + swap 4 GB + root, and `findmnt /boot/efi`.
  The expert recipe is the second most error-prone part after pick-disk. If DHCP gives `f22` an IP that is
  already in the Pi's `known_hosts`, `accept-new` refuses; `ssh-keygen -R <IP>` first.
- `f22` is a new node. `nodes/INDEX.md` says a node = one row + a `nodes/<name>/` folder; the S940 files are in
  `nodes/futro/`. This belongs to the role-setup plan, not the stick. The same goes for `pi` in groups `dialout`/`plugdev`
  for the bench serial ports.

## First review, item by item

| Item | In v2 | Note |
|---|---|---|
| B1 hash public | done | template + `~/s940-build` (700/600) |
| B2 hostname | done | kernel line `netcfg/hostname`; `<HOSTn>` leftover (smaller points) |
| B3 disk choice | partly | V1 (my error), V2, V3, V4, V5 |
| F1 power-off | done | both keys |
| F2 preseed keys | partly | V6, V7 missing |
| F3 no auto-start | partly | timeouts done; menu order V8 |
| F4 xorriso | partly | script not mapped (V2) |
| F5 stick write + timing | done | after 20:02, by-id, read-back of the ISO length |
| F6 SSD | done | Part 3 mandatory, [CHECK] on key/length/SATA |
| S1-S8 | done | S3 key source: V9 |
| T1 | as D3 | add D5 (V3 test) |

## Order of changes

V1 + V2 + V3 + V5 into the pick-disk script and step 4/6 -> V4 dry run with the three cases ->
V6/V7 into step 3 -> V8 menu order + close D2 -> V9 -> smaller points -> D3/D5 to the owner -> build.
