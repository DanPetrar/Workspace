# Review: `proxmox-install-guide-20261117.md`

Reviewer: Fable, 2026-11-17. The owner's words: "review the document".
This is a report. The document was not changed. Nothing was run on `sandbox`.

**Verdict:** the guide is usable as written. It is correct on the main path: ISO, checksum, stick, ext4, repositories, update, checks.
Fix one point before the install: **how the address is set** (finding 1). The other findings are small corrections or clarifications.

## What I checked, and how

| Check | Source | Result |
|---|---|---|
| ISO version, file name, size, date, SHA256 (3.1) | official download page, read 2026-11-17 | **equal**: 9.2-1, `proxmox-ve_9.2-1.iso`, 1.71 GB, 2026-05-21, `4e88fe41…ef2c6c` |
| PVE 9 repository files and `Enabled: no` (7.1) | wiki Package_Repositories, read 2026-11-17 | **equal**: `pve-enterprise.sources`, `proxmox.sources`, `Enabled: no` |
| CPU of the S940 (3.1 "Intel", 4 V1 "CPU(s) 4", S9 "VT-x") | f22, the same model, `lscpu` now | Intel Pentium Silver J5005, 4 CPUs, 1 thread per core, `Virtualization: VT-x`, `/dev/kvm` present. The guide's values fit f22. `sandbox` itself is not seen |
| Disk size | f22 `lsblk` | f22 has a 240 GB SSD shown as 223.6 G. See finding 6 |
| Addresses in D4 | `nodes/INDEX.md`, f22 notes | .11, .222, .225, .226 match INDEX. Router .1 and pc-gate .90 are missing. See finding 2 |

## Findings

**1. Static address or DHCP reservation: the guide mixes the two (section 1 D4, "Router reservation", 5.7).**
The installer writes a **fixed** address into the host. The host then never asks the router (DHCP).
The guide also says "reserve it in the router by MAC, as was done for f22". f22 uses DHCP with a reservation (INDEX: "Address from DHCP with a router reservation on .222").
On a host with a fixed address, the reservation only stops the router from giving that address to another device. It does that only if it exists **before** another device takes the address.
If D4 lies inside the router's DHCP range and the reservation comes "after the install", there is a time window with an address conflict. It is hard to see: the web page sometimes opens and sometimes does not.
Proposal, one of the two, written into D4:
- (a) choose D4 **outside** the router's DHCP range (read the range in the router first). Then no reservation is needed. Or
- (b) choose D4 inside the range and make the reservation **before** the install. The MAC is needed for that; the installer shows it, so read it at the network screen, go to the router, then press Install.
Also: the line "Find a machine by MAC, never by an assumed IP" fits a DHCP machine. For a host with a fixed address you chose, the address is known. Keep the line for the first search only, if the host is not found at D4.

**2. The "do not use" list in D4 is incomplete.**
It misses the router itself (the gateway; pc-gate's notes show `192.168.20.1`, **[check]** for the bench LAN) and pc-gate (`192.168.20.90` in the pc-gate notes of 11-03; it may now be on another LAN).
`.131 (PS-Z003)` comes from DHCP and can change. Do not treat the list as complete. The guide already says "Check the router's list of devices"; put that sentence first.

**3. The `[doc]` / `[check]` marks are not used everywhere.**
The status line promises a mark on every fact. Several facts from general knowledge have no mark:
- the welcome screen text in 5.10 (the real text has dashed lines and wraps differently; the address and `sandbox login:` are what matter);
- the reboot after a kernel update (7.2.3);
- the expected outputs in 8.2 (S7 service names, S11, S13);
- "the machine has an Intel CPU" (3.1). This one was taken from f22, not from `sandbox`. Say so, as point 4.4 already does.
In 5.7 the line "Fields below are from my knowledge **[check]**:" is attached to the Hostname bullet. It reads as if only the Hostname is unchecked. Move it above the list.

**4. S11 expected text does not match what `lsblk` prints.**
`lsblk` does not show a "volume group `pve`" line. It shows the LVM volumes by name: `pve-root`, `pve-swap`, and the thin pool as `pve-data_tmeta`, `pve-data_tdata`, `pve-data-tpool`, `pve-data` (TYPE `lvm`) **[check]**.
Better expected text: "partitions on the SSD; lines `pve-root`, `pve-swap` and `pve-data…` of type `lvm`". Or add `vgs` and `lvs` as a check: VG `pve`; LVs `root`, `swap`, `data`.

**5. Ceph line in 7.1.**
The wiki shows a Ceph file `ceph.sources` with an enterprise entry (Ceph Tentacle). It does not say whether the 9.2 installer enables that entry.
The guide's "if a Ceph enterprise line shows, disable it too" is right. Add one thing: if a Ceph enterprise line stays enabled, `Refresh` and S14 fail with `401`. The symptom row in section 9 names only `enterprise.proxmox.com`, which covers both. Fine as is, but say "pve **or ceph**" in 7.2.1.

**6. Disk size in V2 and Part B.**
A "256 GB" SSD shows as about **238 G** in Linux tools and in the web page (GiB; f22's 240 GB disk shows as 223.6 G).
Write "about 238 G (256 GB)" so the owner does not stop at Part B step 3 over a unit difference.

**7. Section 5 step 2: an unclear sentence.**
"The installer starts without network configuration first; wait until the license screen." It is not clear what the owner should do or watch.
The installer tries DHCP in the background while it starts. That is why 5.7 may show a proposed address.
Proposal: "It may pause a few seconds while it looks for the network. Wait for the license screen."

**8. Section 5 step 9: the stick at the restart.**
"remove the USB stick at the moment the machine restarts" needs a hand at the exact moment. A simpler order: leave **Automatically reboot** ticked, wait for the screen that says the installation succeeded, and pull the stick when the screen goes black.
If the installer menu comes back anyway, section 9 already has the fix ("remove it and restart"). Low risk either way.

**9. SSH is open on the bench LAN after the install (section 10).**
Section 10 says correctly that the host is not yet isolated. It does not say that the installed host accepts **SSH as `root` with the password** on port 22 from the whole bench LAN, as well as the web page on 8006 **[check]**: the Proxmox default.
That is the main exposure until the firewall step. The D8 rule (long, unique password) covers it. Name it in section 10 so the owner knows why D8 matters.
Turning SSH off or limiting it is the owner's decision for the next document, not this one.

**10. Time estimate.**
1.5 h fits steps 3-8 for a first-timer. It leaves out the router work from finding 1 (reading the DHCP range, the reservation): about 10 min more.

## Correct as written (no change)

- Rufus (No to the GRUB download, then DD mode), balenaEtcher, the `dd` lines and the warning against UNetbootin match the official media page.
- ext4 with LVM-thin, giving `local` + `local-lvm`; no ZFS on 16 GB; BTRFS preview: good choices for this lab.
- Secure Boot note (8.1 and later), IPv4 *or* IPv6, Terminal UI fallback, the PAM realm, the "No valid subscription" note.
- V-checks and S-checks: `/dev/kvm` (S8) is a good proof of VT-x. The reboot test and the headless test (8.3, 8.4) are the right final gates.
- The scope limits: no `vmbr1`, firewall or `lab1`; no Claude Code, keys or guests before isolation.

## Not checked by me

`sandbox` itself (BIOS, keys, ports, disk); the router (gateway address, DHCP range, reservation); the 9.2 installer screens; whether the 9.2 installer enables the Ceph enterprise entry; `Europe/Bucharest` as the time zone.
