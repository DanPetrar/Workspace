# S940 fresh-install stick — plan v2 (2026-10-30)

v1 = `s940-stick-plan.md` (kept). v2 applies Fable's review `s940-review-fable.md`: B1-B3, F1-F6, S1-S8.
Guide for the owner's hands: `s940-install-guide-v2.md`.

## Open decisions (owner)

| # | Decision | Needed before |
|---|---|---|
| D1 | Hostname of S940 #1 = `f22` (owner 2026-10-30; role: replaces the raspi for everyday development and test; owner 2026-10-30). User = `pi` (owner 2026-10-30: home `/home/pi`, paths carry over). S940 #2 not planned: one entry now, a rebuild adds the second | step 3 |
| D2 | Boot menu default: plain "Install" highlighted (v2 default, F3) or an automated entry | step 5 |
| D3 | T1: first install on the factory 32 GB SSD as a test, then the 220 GB SSD (+~20 min of hands) | install day |
| D4 | SSH password login on f22 = **on** (Debian default; owner 2026-10-30) | step 3 |

## Bench facts

- Pi: root on `/dev/mmcblk0` (SD); the stick will be the only `sd*` disk (Fable checked).
- Pi USB controller hangs on USB events are known (CLAUDE.md rule 5); the fix drops every Pi USB device. The grid run is
  LAN only, but the stick is plugged in **after the 20:02 grid judgment** (F5).
- Current futro (read 2026-10-30): user `dan-futro`, locale `en_GB.UTF-8`, keyboard `us`, timezone `Europe/Bucharest`, UEFI.
- S940: M.2 SATA SSD slot (2280 per one retailer), no NVMe, no 2.5" bay; F12 boot menu, F2 setup; NIC RTL8111 (r8169);
  mPCIe WiFi socket (sources in the review).
- Workspace repo is **public**. Secrets live in `~/s940-build/` (mode 700): untracked, inside the home folder that is the
  private repo `rpi-claude-config`; never staged (files are staged by name).

## Steps (each with its check)

1. **Stick check, read-only.** `/dev/disk/by-id/usb-*`, size, mounts, partition table and labels. Report, stop.
2. **ISO.** `sudo apt install xorriso`. Download Debian 13 amd64 netinst + `SHA256SUMS` + `SHA256SUMS.sign` into
   `~/s940-build/`. Check: `gpg --verify` against the Debian CD signing key (S3), then `sha256sum -c`.
3. **Preseed.** Template `setup/s940-preseed.template.cfg` (committed) with `@PWHASH@`, `@USER@`; filled copy
   `~/s940-build/preseed.cfg` (mode 600). Contents:
   - locale `en_GB.UTF-8`, keymap `us`, timezone `Europe/Bucharest`, clock UTC, NTP on;
   - `netcfg/choose_interface select auto`, `netcfg/get_domain` empty, `hw-detect/load_firmware true`;
   - mirror `deb.debian.org` `/debian`, `mirror/http/proxy` empty, `apt-setup/cdrom/set-first false`;
   - root login off; user `@USER@` with `passwd/user-password-crypted @PWHASH@` (in group sudo);
   - `tasksel/first multiselect standard, ssh-server`; `popularity-contest/participate false`;
   - partman: disk from step 4, GPT, recipe EFI 512 MB + swap 4 GB + root ext4 rest; the full confirm set:
     `partman-lvm/device_remove_lvm`, `partman-md/device_remove_md`, `partman-lvm/confirm`, `partman-lvm/confirm_nooverwrite`,
     `partman-partitioning/confirm_write_new_label`, `partman/choose_partition finish`, `partman/confirm`,
     `partman/confirm_nooverwrite` (the factory disk holds Win IoT or eLux partitions);
   - `grub-installer/force-efi-extra-removable true`;
   - `finish-install/reboot_in_progress note` and `debian-installer/exit/poweroff true` (F1: the S940 switches off at the end);
   - `preseed/late_command`: `authorized_keys` for `@USER@` (raspi + futro public keys), mode 700/600, owner `@USER@`;
     `/etc/issue.d/s940.issue` with `Host: <name>`, `MAC: <mac read at install>`, `IP: \4` (S1);
     SSH password login stays on (D4).
4. **Disk choice (B3).** Script `setup/s940-pickdisk.sh` (committed), run by `partman/early_command`:
   disks in `/sys/block` whose real path has no `/usb/`; leave out the disk holding `/cdrom`; **exactly one** must remain,
   size 25-300 GB; then `debconf-set partman-auto/disk /dev/<it>`. Otherwise an error screen, the installer stops
   before any write (fail closed).
5. **Boot entries (B2, F2, F3).** UEFI `boot/grub/grub.cfg` and BIOS `isolinux/txt.cfg`, both:
   plain "Install" (default, D2), then "Automated install f22 (erases internal disk)". One entry: S940 #2 is not planned.
   Kernel line: `auto=true priority=critical preseed/file=/cdrom/preseed.cfg locale=en_GB.UTF-8 keymap=us netcfg/hostname=<HOSTn>`.
   No timeout: GRUB `set timeout=-1`; isolinux `timeout 0`, no `ontimeout`.
6. **Rebuild (F4).** `xorriso -indev netinst.iso -outdev s940.iso -map preseed.cfg /preseed.cfg -map grub.cfg /boot/grub/grub.cfg
   -map txt.cfg /isolinux/txt.cfg -boot_image any replay` (syntax checked against `man xorriso` first).
   Checks: `-report_el_torito plain` equals the original's; extract the three files from `s940.iso` and grep every key of
   step 3, the hostname, the timeout lines; `bash -n` and a dry run of the pick-disk script on the Pi (must refuse: SD only).
7. **Write (F5).** Target = the by-id path from step 1; nothing mounted; size matches; `dd ... conv=fsync`; read back exactly
   the ISO length (`head -c <size>`), `sha256sum` equal. ~2 min.
8. **Commit (Workspace, public).** Template, pick-disk script, plan v2, guide v2 — staged by name. Before the commit:
   `git diff --cached | grep -c '\$6\$'` must be 0.

After the install (owner `up ...`): from the Pi `ssh -o StrictHostKeyChecking=accept-new @USER@@<IP>`; check hostname,
`lsblk` (root on the internal SSD, size as expected), `/etc/issue.d`. Then the role setup = a separate plan.

My time, steps 1-8: ~60-90 min (the preseed and the pick-disk script are new work).
