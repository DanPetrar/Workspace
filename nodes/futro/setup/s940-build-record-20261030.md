# f22 stick build — record 2026-10-30 (plan `../s940-stick-plan-v3.md`, steps 2-6, owner `go`)

Build folder (private, not in any public repo): `~/s940-build/` (700). Build script `~/s940-build/build.sh` (re-run = full rebuild,
seconds). Committed here: `s940-preseed.template.cfg`, `s940-pickdisk.sh`.

| Step | Result |
|---|---|
| 2 xorriso | installed 1.5.6 (apt, raspi) |
| 2 ISO | `debian-13.7.0-amd64-netinst.iso` 792723456 B; `sha256sum -c` OK (a7ef94ac…e355) |
| 2 signature | key fingerprint `DF9B 9C49 EAA9 2984 3258 9D76 DA87 E80D 6294 BE9B` = debian.org/CD/verify; key from keyring.debian.org; GOODSIG + VALIDSIG (separate GNUPGHOME `~/s940-build/gnupg`) |
| 3 preseed | 31 of 31 keys found in the preseed extracted from the ISO (30 after D6, below); both public keys filled (raspi pi, futro dan-futro) |
| 4 pick-disk | `busybox sh -n` OK, `dash -n` OK; dry run under busybox sh, predicted = measured: (a) Pi `/sys` REFUSE 0 disks; (b) fake `sda` 220 GB ACCEPT sda (219 GB); (c) `sda` + USB `sdb` (`usb1` path) ACCEPT sda only. Extra: USB-only REFUSE; `sda`+`nvme0n1` REFUSE 2; 512 GB REFUSE; stick on `sda` REFUSE |
| 5 menus | GRUB: `set timeout=-1`, `set default=0`, order Install / Automated install f22 / Graphical install / submenus. isolinux: `txt.cfg` before `gtk.cfg`, `menu default` on Install, `timeout 0` (original), no `ontimeout`. `netcfg/hostname=f22` on both automated lines |
| 6 rebuild | `xorriso … -boot_image any replay`; the 6 files on the ISO = the built files (cmp); file count 1010 -> 1012 |
| 6 boot report | **not identical to the original as the plan said**: positions moved (catalog LBA 1028 -> 570, EFI partition start 4116 -> 2284), image 1548288 -> 1546240 sectors, new GPT GUIDs. Same structure: BIOS + UEFI El Torito images, same block counts (4 / 7360), MBR 0xef + GPT 2 partitions + APM. **EFI boot image byte-identical** (sha256 6294af7f… both as `/boot/grub/efi.img` and as the EFI partition). `isolinux.bin` differs: xorriso patches the boot-info table (LBA values) |

10:32 owner: the pi password is typed at install, not preseeded (D6). Template line `passwd/user-password-crypted` removed; rebuild:
0 password lines in the preseed on the ISO, username pi present, EFI boot image still 6294af7f…. **Final `s940.iso` sha256 9cd4cda9… 10:32.**
Step 1 (10:39, owner `plugged`): stick `usb-Generic_Flash_Disk_2E381EA9-0:0` = sda, 8054112256 B, USB, removable, only sd* disk; held a Debian 13.7.0 image
not equal to the download (first 792723456 B sha256 37e0c126…); not mounted; USB log clean.
Step 7 (owner `write`): dd 10:42:19-10:46:12, conv=fsync; caches dropped; read-back of 792002560 B = 9cd4cda9… = s940.iso: **WRITE PASS**; USB log clean.

## T1 test install on the factory 32 GB SSD (D3 yes) — PASS

Owner `f22; 4C:52:62:A6:CE:C6 ; 192.168.20.131`. ARP on the raspi: .131 = 4c:52:62:a6:ce:c6 (eno1). SSH key login as pi from the raspi OK.
hostname f22; Debian 13.7, kernel 6.12.113+deb13-amd64; UEFI (BootCurrent 0005; eLux + Diagnostic entries still in NVRAM).
Disk `sda` 29.8G SATA `DEM24-32GM41BC1DC-PC`: sda1 487M vfat /boot/efi (partman 512 MB = 10^6 units), sda2 3.8G swap, sda3 25.5G ext4 /.
pi: uid 1000, groups incl. sudo, plugdev (no dialout: role setup). authorized_keys 2 lines, .ssh 700 / file 600, owner pi.
`/etc/issue.d/s940.issue` = Host f22, MAC 4c:52:62:a6:ce:c6, IP \4. SSH offers publickey,password (D4 on).
Europe/Bucharest, NTP active + synchronized, en_GB.UTF-8, keyboard us; apt sources deb.debian.org trixie + security + updates, main non-free-firmware. RAM 3690 MB.
Not checked: login from futro's key; removable EFI path `EFI/BOOT` (needs sudo); whether other installer questions appeared; power-off at the end (owner's eyes).

## Final install on the 220 GB SSD — PASS

Owner: `new ip 192.168.20.132 on 220gb`; he will reserve a fixed IP for the MAC on his DHCP. ARP: .132 = 4c:52:62:a6:ce:c6.
Old .131 host key removed from the raspi known_hosts; new ED25519 key accepted.
hostname f22, Debian 13.7; `sda` 223.6G SATA `WDC WDS240G2G0B-00EPW0`: sda1 487M vfat /boot/efi, sda2 3.8G swap, sda3 219.3G ext4 /
(215G, 1.3G used). pi in sudo; .ssh 700 pi, authorized_keys 600 pi, 2 keys; SSH publickey,password; NTP synchronized.
Factory 32 GB SSD (DEM24-32GM41BC1DC-PC) out, holds the T1 test install.
f22 fixed IP 192.168.20.222 (owner DHCP reservation for 4c:52:62:a6:ce:c6), checked by ARP + SSH.
