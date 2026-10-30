# S940 (f22) fresh-install stick — plan v3 (2026-10-30)

v1, v2 kept. v3 applies Fable's v2 review `s940-review-v2-fable.md`: V1-V9 and the smaller points.
Guide for the owner's hands: `s940-install-guide-v3.md`.

## Decisions

| # | Decision | Needed before |
|---|---|---|
| D1 | S940 #1 hostname **`f22`**, role: replaces the raspi for everyday development and test. User **`pi`** (home `/home/pi`, paths carry over). S940 #2 not planned: one entry now, a rebuild adds the second (owner 2026-10-30) | step 3 |
| D2 | Boot menu default: plain "Install" first and highlighted (proposed, owner has not refused; guide v3 Part 6 is written for it) — open | step 5 |
| D3 | T1 = **yes** (owner 2026-10-30): first install on the factory 32 GB SSD as a test, then the 220 GB SSD (+~20 min of hands) | install day |
| D4 | SSH password login on f22 = **on** (Debian default; owner 2026-10-30) | step 3 |
| D6 | Password of `pi`: typed by the owner at install, twice (owner 2026-10-30); not preseeded, no hash file | step 3 |
| D5 | Fail-path test with no internal SSD = **no** (owner 2026-10-30): the fail path is tested by the dry run only | install day |

## Bench facts

- Pi: root on `/dev/mmcblk0` (SD, 62.5 GB); the stick will be the only `sd*` disk. Free space 24 GB (Fable checked).
- Pi USB controller hangs on USB events are known (CLAUDE.md rule 5); the fix drops every Pi USB device. The grid run is
  LAN only, but the stick is plugged in **after the 20:02 grid judgment**.
- Current futro (read 2026-10-30): locale `en_GB.UTF-8`, keyboard `us`, timezone `Europe/Bucharest`, UEFI.
- S940: M.2 SATA SSD slot (2280 per one retailer), no NVMe, no 2.5" bay; F12 boot menu, F2 setup; NIC RTL8111 (r8169);
  mPCIe WiFi socket (sources in the first review).
- Workspace repo is **public**; home repo `rpi-claude-config` is private, no `.gitignore`. Secrets live in `~/s940-build/`
  (mode 700): untracked, never staged (files are staged by name).
- USB devices in sysfs have path parts `usb1`, `usb2`, never a bare `usb` (Fable checked on the Pi).

## Steps (each with its check)

1. **Stick check, read-only.** `/dev/disk/by-id/usb-*`, size, mounts, partition table and labels. Report, stop.
2. **ISO.** `sudo apt install xorriso`. Download Debian 13 amd64 netinst + `SHA256SUMS` + `SHA256SUMS.sign` into
   `~/s940-build/`. Signing key: fingerprint taken from `https://www.debian.org/CD/verify` (not from the ISO mirror);
   key fetched from `keyring.debian.org`; fingerprints compared, then `gpg --verify`, then `sha256sum -c`.
3. **Preseed.** Template `setup/s940-preseed.template.cfg` (committed) with `@KEY_RASPI@`, `@KEY_FUTRO@`; filled copy
   `~/s940-build/preseed.cfg` (mode 600). Contents:
   - locale `en_GB.UTF-8`, keymap `us`, timezone `Europe/Bucharest`, clock UTC, NTP on;
   - `netcfg/choose_interface select auto`, `netcfg/get_domain` empty, `hw-detect/load_firmware true`;
   - `mirror/country string manual`, mirror `deb.debian.org` `/debian`, `mirror/http/proxy` empty,
     `apt-setup/cdrom/set-first false`;
   - root login off; user `pi` (in group sudo); its password is **not** preseeded: the installer asks it (D6);
   - `tasksel/first multiselect standard, ssh-server`; `popularity-contest/participate false`;
   - partman: disk from step 4, GPT, recipe EFI 512 MB + swap 4 GB + root ext4 rest; `partman-efi/non_efi_system true`;
     the full confirm set: `partman-lvm/device_remove_lvm`, `partman-md/device_remove_md`, `partman-lvm/confirm`,
     `partman-lvm/confirm_nooverwrite`, `partman-partitioning/confirm_write_new_label`, `partman/choose_partition finish`,
     `partman/confirm`, `partman/confirm_nooverwrite` (the factory disk holds Win IoT or eLux partitions);
   - `grub-installer/force-efi-extra-removable true`;
   - `finish-install/reboot_in_progress note` and `debian-installer/exit/poweroff true` (the S940 switches off at the end);
   - `preseed/late_command`: `/target/home/pi/.ssh/authorized_keys` (raspi + futro public keys), then
     `in-target chown -R pi:pi /home/pi/.ssh`, modes 700/600; `/etc/issue.d/s940.issue` with `Host: f22`,
     `MAC: <mac read at install>`, `IP: \4`. SSH password login stays on (D4).
4. **Disk choice.** Script `setup/s940-pickdisk.sh` (committed), `#!/bin/sh` (installer = busybox ash, no bash).
   Run by `partman/early_command` as `sh /cdrom/s940-pickdisk.sh`. Rules:
   - candidates: `/sys/block/sd*` and `/sys/block/nvme*n*` only (`loop`, `ram`, `zram`, `mmcblk`, `sr` never enter);
   - leave out a disk whose real path matches `*/usb[0-9]*`; leave out the disk holding `/cdrom`;
   - size from `/sys/block/<dev>/size` (512-byte sectors), band 25-300 GB;
   - **exactly one** must remain: `debconf-set partman-auto/disk /dev/<it>`;
   - otherwise (fail closed): reason to `/var/log/syslog` and to the screen (`/dev/console`), then a sleep loop that
     **never returns**, so no partitioning can follow. The installer stays on the partitioner screen.
   - dry-run mode: `s940-pickdisk.sh --dry-run <sysfs root> <cdrom dev>` prints the choice instead of `debconf-set`.
5. **Boot entries.** UEFI `boot/grub/grub.cfg` and BIOS `isolinux/txt.cfg` (and the menu file that includes it) are
   rewritten: **first** entry plain "Install" (default, D2), then "Automated install f22 (erases internal disk)";
   the original "Graphical install" moves below. Kernel line of the automated entry:
   `auto=true priority=critical preseed/file=/cdrom/preseed.cfg locale=en_GB.UTF-8 keymap=us netcfg/hostname=f22`.
   No timeout: GRUB `set timeout=-1`; isolinux `timeout 0`, no `ontimeout`.
6. **Rebuild.** `xorriso -indev netinst.iso -outdev s940.iso -map preseed.cfg /preseed.cfg -map s940-pickdisk.sh
   /s940-pickdisk.sh -map grub.cfg /boot/grub/grub.cfg -map txt.cfg /isolinux/txt.cfg -boot_image any replay`
   (syntax checked against `man xorriso` first). Checks:
   - `-report_el_torito plain` equals the original's;
   - extract the four files from `s940.iso`: grep every key of step 3 (including `mirror/country`, `non_efi_system`),
     `f22`, the timeout lines; the first `menuentry` in `grub.cfg` is plain "Install";
   - `busybox sh -n` and `dash -n` on the pick-disk script;
   - dry run under `busybox sh`, three cases, predicted: (a) the Pi's real `/sys` -> **refuse** (only `mmcblk0`);
     (b) fake sysfs with one non-USB `sda` 220 GB -> **accept sda**; (c) fake sysfs with non-USB `sda` 220 GB + USB `sdb`
     (path with `usb1`) -> **accept sda only**. A wrong result in any case = stop.
7. **Write.** Target = the by-id path from step 1; nothing mounted; size matches; `dd ... conv=fsync`; read back exactly
   the ISO length (`head -c <size>`), `sha256sum` equal. ~2 min.
8. **Commit (Workspace, public).** Template, pick-disk script, plan v3, guide v3 — staged by name. Before the commit:
   `git diff --cached | grep -c '\$6\$'` must be 0.

## After the install (owner `up ...`)

From the Pi: `ssh-keygen -R <IP>` if the IP is already in `known_hosts`; then
`ssh -o StrictHostKeyChecking=accept-new pi@<IP>`. Checks: `hostname` = f22; `lsblk` = EFI 512 MB + swap 4 GB + root on
the internal SSD at its size; `findmnt /boot/efi`; `/etc/issue.d/s940.issue`.
Not in this plan (role setup, separate plan): node row + `nodes/f22/` folder in `nodes/INDEX.md`, `pi` in `dialout`/`plugdev`.

My time, steps 1-8: ~60-90 min (the preseed and the pick-disk script are new work).
