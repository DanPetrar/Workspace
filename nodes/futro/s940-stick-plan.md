# S940 fresh-install stick — plan (step card as shown to the owner, 2026-10-30)

Step card — fresh-install stick (nothing executed)

1. Stick check (read-only): identify by `/dev/disk/by-id`, size, current content (expected: July netinst). Report, stop.
2. ISO: `apt install xorriso`; download Debian 13 amd64 netinst + SHA256SUMS to `~/Workspace/nodes/futro/setup/iso/` (not in git); check the hash.
3. `preseed.cfg` in `setup/` (committed): locale/timezone/keyboard as the current futro (read over ssh), user as on the current futro, root locked, sudo, openssh-server + the raspi and futro public keys, no desktop, partitions EFI 512 MB + swap 4 GB + root ext4 rest.
4. Install target = the internal SSD only, never a USB disk (a wrong target erases that disk): the preseed picks the first non-removable disk.
5. Hostname = the only question asked at install (the same stick serves both S940).
6. Rebuild the ISO with the preseed + an auto-install boot entry; check: unpack and grep the preseed and the boot entry.
7. Write the stick (replaces the July installer; no backup needed, it is a public ISO); check: read back, compare the hash.

Password: you set it at the end with `! mkpasswd -m sha-512` (hash only, I never see the plain text).
Your hands per S940: Ethernet cable, monitor + keyboard, F12 -> USB stick, type the hostname, ~15 min, remove the stick at the reboot.
Time steps 1-7: ~30-45 min of my work. The grid run is not affected.

## Changes made when the guide was written (as told to the owner)

- Password first (Part 1): you write the hash into `setup/s940-pw.hash` from your own terminal, before the stick is built (the preseed needs it; I never see the plain text).
- The install does not start by itself: you press Enter on "Automated install (S940, erases internal disk)", so a stick left in at the reboot cannot erase the disk again.
- The login screen shows hostname, IP and MAC; you send `up <hostname> <IP> <MAC>`, I take over over SSH.
- Not looked up (marked [CHECK]): S940 SSD slot (assumed M.2 SATA; NVMe would not be seen), F12 boot key (Fujitsu + S740 guide).
