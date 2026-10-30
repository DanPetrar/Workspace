# S940 fresh-install stick: review (Fable, 2026-10-30)

Input: the owner's words 1-7 (2026-10-30), `s940-stick-plan.md`, `s940-install-guide.md`.
Read-only lookups made for this review (nothing installed, no USB device or other machine touched):
`hardware.md`, `inventory.md`, `setup-plan.md` (current futro), the S940 memory note,
`findmnt /` + `lsblk` on the Pi, `which openssl mkpasswd xorriso qemu-system-x86_64`,
`gh repo view DanPetrar/Workspace`, two web pages on the S940 (sources at the end).
Points marked **(from memory)** are my knowledge of debian-installer, not checked here.

## Verdict

The approach fits the owner's words 4-6: fresh install, one preseeded stick, his hands only
for SSD, cables, boot key, Enter. **Not ready to build as written: 3 blockers (B1-B3), 6 fixes
(F1-F6).** All are changes to the plan/guide text and the preseed content; none changes the
method.

## Blockers (fix before the stick is written)

**B1. The password hash would become public.** The Workspace repo is **PUBLIC** (checked with
`gh repo view`) and has no `.gitignore`. Plan step 3 commits `preseed.cfg` in `setup/`, and the
preseed has to contain the hash; guide Part 1 writes `s940-pw.hash` into the same `setup/`
folder. A published SHA-512 crypt hash can be attacked offline, and it protects `sudo` on both S940.
Fix: hash file, the filled-in preseed and the ISO go **outside every repo** (e.g. `~/s940-build/`,
mode 700). Commit only a template preseed with a placeholder (`@PWHASH@`). Guide Part 1:
change the path and add `chmod 600` to the file.

**B2. "Hostname is the only question": how it works is not stated, and the usual way does not
work.** An automated install runs with `auto=true priority=critical`. The hostname question has
priority *high*, so it is not shown: the name comes from DHCP or becomes `debian`. Setting
`netcfg/get_hostname seen false` does not lift it over the priority threshold **(from memory)**. Lowering
the priority to `high` brings back other questions (domain, mirror, interface, ...).
Two ways that work:
- (a) **recommended**: two boot entries on the stick, one per hostname, each with
  `netcfg/hostname=<name>` on the kernel line. The owner gives both names before the build
  and types nothing at install; guide Part 6 step 3 goes away.
- (b) one fixed name (e.g. `s940-new`); Claude renames the machine over SSH after the install.
Both remove the only typing step. (a) needs the two names as a reply word before Part 2.

**B3. "The preseed picks the first non-removable disk" is not safe as written.** Many USB sticks and
USB-SATA adapters report `removable=0`, and the order of the disks is not fixed. `partman-auto/disk`
needs a device name, so set it in `partman/early_command` with a short script that:
1. lists the disks whose `/sys/block/<dev>` path has no `/usb/` in it,
2. leaves out the disk that holds `/cdrom` (the installer stick itself),
3. needs **exactly one** disk left, with a size in a set band (e.g. 25-300 GB),
4. otherwise stops the installer with an error screen, before any write (fail closed).
The script is the one part that can erase the wrong disk. See T1 for how to test it first.

## Fixes before the build

**F1. End of the install.** Guide Part 6 step 6 ("when the Fujitsu logo appears, pull the
stick") depends on timing. Use `d-i debian-installer/exit/poweroff boolean true`: the S940 switches off at
the end, the owner pulls the stick, then presses power. Also needed either way:
`d-i finish-install/reboot_in_progress note`. Without it the installer waits on an
"Installation complete" screen, and Part 6 step 6 is wrong.

**F2. Questions the preseed must answer on this hardware (from memory).** Put them in the plan as a list
and grep each key in the built preseed (plan step 6 check):
- locale and keymap **on the kernel line** (`locale=... keymap=...`) or the preseed placed
  in the initrd: a preseed file on the ISO is loaded after the language/keyboard step;
- `netcfg/choose_interface select auto`: the S940 has an mPCIe WiFi socket, and a fitted
  card means two interfaces, which brings a question; `netcfg/get_domain`;
- mirror country/hostname/directory, `mirror/http/proxy` (empty); `hw-detect/load_firmware true`;
- `popularity-contest/participate false`; `apt-setup/cdrom/set-first false`;
  `tasksel/first` = `standard, ssh-server`;
- the full partman confirm set: `partman-lvm/device_remove_lvm`, `partman-md/device_remove_md`,
  `partman-lvm/confirm(_nooverwrite)`, `partman-partitioning/confirm_write_new_label`,
  `partman/choose_partition finish`, `partman/confirm(_nooverwrite)`. The factory disk holds
  Win 10 IoT or eLux partitions, not an empty disk;
- `grub-installer/force-efi-extra-removable true`: thin-client UEFI sometimes loses its
  NVRAM boot entry; the removable path still boots.

**F3. "Does not start by itself": add a check.** UEFI `boot/grub/grub.cfg`: no `timeout`
line, or `set timeout=-1`. BIOS `isolinux`: `timeout 0`, no `ontimeout`. Add this to the step 6 check.
Option (owner's choice): make the **plain** installer the highlighted default and put the
automated entry or entries second. Then an Enter pressed out of habit on a stick found in a
drawer cannot erase a disk. It costs one arrow key in Part 6.

**F4. Say how the ISO is rebuilt** **(from memory, check `man xorriso`)**:
`xorriso -indev netinst.iso -outdev s940.iso -map preseed.cfg /preseed.cfg -map grub.cfg /boot/grub/grub.cfg -map txt.cfg /isolinux/txt.cfg -boot_image any replay`.
This keeps the hybrid MBR/GPT layout and the EFI image (the signed shim stays as it is, so Secure Boot
works). Check: `xorriso -indev s940.iso -report_el_torito plain` lists the same boot
images as the original ISO.

**F5. Writing the stick on the Pi.** The Pi runs from `/dev/mmcblk0` (SD), so the stick will be
the only `sdX` (checked): low risk. Still: write to the `/dev/disk/by-id/usb-...` path from step 1,
check that nothing on it is mounted and that the size matches, use `conv=fsync`, and read back
exactly the ISO length (`head -c <iso size>`), not the whole stick. Writing takes ~2 min, not 10 (guide Part 2.3).
This Pi has a known xHCI hang on USB events (error -110/-71). The fix unbinds the whole
controller, so **every USB serial device on the Pi drops**. The claim "the grid run is not affected" holds
only if nothing in the run uses Pi USB. Per memory the run is LAN-only and is judged at 20:02 today.
Safest: plug the stick in after that judgment. One line in the plan.

**F6. Which SSD.** The owner has bought bigger SSDs (words 2-3). The guide makes Part 3 optional,
and skipping it means a 32 GB install, below the need already noted (current futro uses 62 GB,
the clone plan asked >= 64 GB). Make Part 3 mandatory: S940 #1 = 220 GB now, S940 #2 = 250 GB
next week (Part 9 already says so).
Slot: retailer listings and the Fujitsu data sheet say **M.2 SATA**, one gives **2280**.
One hobby page calls it "mSATA". [CHECK] stays, in a short form: compare the connector and
length of the removed 32 GB card with the new SSD before fitting it, and stop if they differ.
NVMe is not supported (no source says it is). Delete the "2.5-inch bay" line: no source shows one.

## Smaller points

- **S1** Part 7: agetty can print an empty or old IP line if DHCP finishes after the prompt.
  Tell the owner: press Enter once to redraw before he decides "no link". There is no agetty escape
  for the MAC: the plan must list the late_command that writes `/etc/issue.d/`. A photo of
  the screen is enough; three values typed by hand can carry a typo.
- **S2** Password: `openssl passwd -6` (present on the Pi) prompts twice: correct. The plan
  still says `mkpasswd -m sha-512` (`mkpasswd` is not installed). Make the plan match the guide.
- **S3** SHA256SUMS only proves that the file matches the server's list. Also check
  `SHA256SUMS.sign` with gpg against the Debian CD signing key (~2 min).
- **S4** `authorized_keys` through late_command: owner `dan-futro` (or the chosen user),
  mode 700/600. Check from the Pi with `ssh -o StrictHostKeyChecking=accept-new`. Turning off password
  login over SSH is the owner's decision; it is not in the plan.
- **S5** User name "as on the current futro" (`dan-futro`): the memory note says one S940
  replaces the raspi, and Claude's memory folder follows the home path. The plan does not say the role
  of each S940. The install does not need it, but the hostnames and the user name do. One question to
  the owner before the build.
- **S6** Guide Part 5: F12 = boot menu, F2 = setup, confirmed for the S940 (parkytowers);
  the [CHECK] on F12 can go. A used unit may have a BIOS password set: if F2/F12 asks for one,
  [STOP].
- **S7** NIC = Realtek RTL8111 (parkytowers lspci). r8169 driver; its firmware is on the Debian 13 netinst.
- **S8** "Things not to do": add "store the stick: it holds the password hash".

## T1. Test before the 220 GB SSD goes in (owner's decision, Extra)

QEMU x86 is not installed on the Pi (checked); a VM on the workstation would mean touching another machine.
A cheaper test that is safe: **first install on S940 #1 with the factory 32 GB SSD still in**,
and only that disk and the stick connected. It checks B2 (name), B3 (disk choice), F1 (power-off),
F2 (no questions) and SSH. The 32 GB disk holds nothing to keep (the owner confirms Win IoT or eLux is not
wanted). Then Part 3 (fit the 220 GB SSD) and install again: +~20 min of his hands, once.

## What is good

Hash-only password; Enter required, no auto-start; a label on the stick; [STOP] points with reply
words; the factory SSD kept as the way back; read-back after the write; a photo of any unexpected
question instead of answering it.

## Order of changes

B1 -> B2 (needs 2 hostnames + user name: S5) -> B3 -> F2/F3/F4 into the preseed and plan step 6 check
-> F1, F5, F6 into the guide -> S1-S8 -> T1 decision -> build.

## Sources

- [parkytowers: Futro S940 firmware (F12/F2, USB boot)](https://www.parkytowers.me.uk/thin/Futro/s940/firmware.shtml)
- [parkytowers: Futro S940 (M.2/mSATA SATA, mPCIe WiFi socket, RTL8111)](https://www.parkytowers.me.uk/thin/Futro/s940/)
- [mrmemory: S940 SSD upgrades (M.2 2280 SATA)](https://www.mrmemory.co.uk/ssd-upgrades/fujitsu-siemens/futro/s940)
- [Fujitsu S940 data sheet (1x M.2 SSD SATA)](https://manualmachine.com/fujitsu/s940/7708995-service-manual)
