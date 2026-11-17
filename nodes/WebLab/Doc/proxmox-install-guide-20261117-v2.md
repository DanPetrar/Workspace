# Installing and verifying Proxmox VE on `sandbox` — step by step

Written 2026-11-17 for the owner, for a person who has never used Proxmox.
**Version 2** (2026-11-17): the changes after Fable's review (`proxmox-install-guide-review-fable-20261117.md`,
findings 1-10). The first version `proxmox-install-guide-20261117.md` is kept unchanged.
Topic: WebLab (`nodes/WebLab/INDEX.md`). This is step 1 of the plan in
`second-futro-usage-fable-20261114-part2.md` (install, repositories, update, web page opens).

**Status of this file:** nothing in it was run on `sandbox`. The machine has not been seen by Claude.
Facts from the official Proxmox pages (read 2026-11-17) are marked **[doc]**. Facts from
general knowledge, not looked up, are marked **[check]**: compare them with what you see on the screen.
The screen texts below are the ones I expect; if a screen differs, stop and write down what you see.

---

## 0. What you are doing, in plain words

**Proxmox VE** (Virtual Environment, "PVE") is an operating system (Debian Linux with extra software)
whose only job is to run other small computers inside the machine. These inner computers are of two kinds:

- **VM** (virtual machine): a full pretend computer with its own system and its own screen.
- **Container** (CT, "LXC"): a lighter pretend computer that shares the kernel of Proxmox. It starts in seconds.

You manage everything from a **web page** on another computer (your PC). The machine itself needs a screen and
keyboard only for this installation; later it can stand in a corner with only a power cable and a network cable.

Words you will meet:

| Word | Meaning |
|---|---|
| node | one Proxmox machine. Here the node is called `sandbox`. |
| host | the Proxmox system itself, as opposed to the VMs and containers inside it. |
| `root` | the all-powerful administrator user. |
| PAM realm | the login method that uses the Linux user list. You log in to the web page as `root` with realm "Linux PAM standard authentication". |
| `vmbr0` | the **bridge**: a virtual network switch inside the host. The real network cable is plugged into it; later the VMs and containers plug into it too. The installer creates it. |
| `local` | storage on the host's disk for files (ISO images, templates, backups). |
| `local-lvm` | storage (LVM-thin) for the disks of VMs and containers. It gives snapshots. |
| snapshot | a saved state of a VM or container that you can go back to. |
| subscription | a paid support plan. You do not need it. The web page shows a "No valid subscription" message at every login; that is normal. |
| enterprise repository | the paid update source. It fails without a key, so you switch it off and use the **no-subscription** source. |

**Time:** about 1 h 45 min for a first-time person (router work 10 min, download and USB 20 min, BIOS 10 min,
install 15 min, first login and updates 30 min, verification and reboot test 15 min).

**What this file does not do:** the internal network for the lab (`vmbr1`), the firewall and the container `lab1`
(steps 2-4 of the plan). They come in the next document, after this one is PASS.

---

## 1. Decisions and values to prepare (fill in before you start)

Write the values here, or in your own notes. **Do not write the root password in this file, in git or in
memory notes.** Keep it in your password manager.

| # | Item | Value | Notes |
|---|---|---|---|
| D1 | Machine name (hostname) | `sandbox` | chosen 2026-11-17 |
| D2 | Domain | `home.arpa` | **[check]** `home.arpa` is reserved for home networks (RFC 8375) and does not clash with `.local`. Use your own domain if you already have one. |
| D3 | Full name (FQDN) | `sandbox.home.arpa` | Proxmox needs a full name with a dot. **Choose it now: renaming a node later is painful once guests exist.** |
| D4 | IP address of `sandbox` | ______ | A **fixed** address on the bench LAN 192.168.20.x (the installer writes it into the host; the host never asks the router for one). It must be **free**: **first read the router's list of devices and its DHCP range.** Known as used (not a complete list): the router itself (probably .1 **[check]**), .11 (workstation), .90 (pc-gate, from the notes of 11-03 **[check]**, it may be on another LAN now), .131 (PS-Z003, from DHCP, can change), .222 (f22), .225 (raspi), .226 (futro), .242 (Waveshare). **Choose one of two ways** (see "Router work" below): **(a)** an address **outside** the DHCP range, no reservation needed; or **(b)** an address inside the range, with the router reservation made **before** you press Install. |
| D5 | Netmask / CIDR | `/24` | from the bench LAN 192.168.20.x; **[check]** confirm in the router. |
| D6 | Gateway | ______ | the router's address; read it from your PC (see 3.4). |
| D7 | DNS server | ______ | the router's address, or a public one such as `1.1.1.1`. |
| D8 | Root password | (password manager) | at least 8 characters. Long and unique. If lost: reinstall (nothing is on the machine yet). |
| D9 | E-mail for the installer | ______ | the installer requires one. It is used only for Proxmox notices. A non-personal address such as `root@sandbox.home.arpa` is accepted by the installer; notices then go nowhere (fine for now). |
| D10 | The SSD may be erased | yes / no | **The install erases the whole disk.** Say yes only when nothing on the `sandbox` SSD is needed. |

**Router work (10 min, before the install).** Open the router's page and read the DHCP range (the addresses it hands out).
- **Way (a):** D4 lies outside that range. Nothing more to do in the router.
- **Way (b):** D4 lies inside the range. Then the router must be told to keep D4 for this machine's **MAC address**
  **before** you press Install, or another device can take D4 and you get an address conflict that is hard to see
  (the web page opens sometimes and sometimes not). The installer shows the MAC on its network screen (Part C, step 7): write it
  down (D11: ______), make the reservation in the router, then go on to the summary and Install.
  (f22 is different: it takes its address from DHCP and the router reserves it. `sandbox` has a fixed address.)

Find a machine by MAC, never by an assumed IP: keep this rule for the first search, if the host does not answer at D4.

---

## 2. What you need

| Item | Check |
|---|---|
| `sandbox` machine (Futro S940), its power supply | the machine you are installing |
| a **monitor** and a **USB keyboard** | the S940 has DisplayPort outputs **[check]**: look at the back; an adapter may be needed for an HDMI or VGA monitor |
| a network cable from `sandbox` to the bench LAN switch/router | link light on |
| a **USB stick**, at least 4 GB, **it will be erased** | no data on it |
| your PC with a browser | **[doc]** Firefox, Chrome, Edge or Safari, current version |
| the value list from section 1 | filled |
| about 2 GB of free space on the PC for the ISO | |

---

## 3. Part A: prepare the installer USB stick (on your PC)

### 3.1 Download the ISO

1. Open `https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso` (the official page).
2. Under **Proxmox VE ISO Installer**, choose the **x86-64** one (the S940 has an Intel CPU: seen on f22, the same model; `sandbox` itself was not seen), **not** "arm64".
3. On 2026-11-17 the page showed **version 9.2-1**, file `proxmox-ve_9.2-1.iso`, 1.71 GB, updated 2026-05-21,
   SHA256 `4e88fe416df9b527624a175f24c9aa07c714d3332afb1ee3dbf3879573ef2c6c` **[doc]**.
   If the page shows a newer version, use the newer one and the checksum printed next to it, not the one in this file.

### 3.2 Verify the download (checksum)

The checksum proves the file arrived whole and is the official one. Open a terminal in the download folder:

- Linux: `sha256sum proxmox-ve_9.2-1.iso`
- Windows (PowerShell): `certutil -hashfile proxmox-ve_9.2-1.iso SHA256`
- macOS: `shasum -a 256 proxmox-ve_9.2-1.iso`

**PASS** = the long hexadecimal string equals the one on the page, letter for letter. If it differs: download again.
Do not write the stick from a file that fails this check.

### 3.3 Write the ISO to the USB stick

**[doc]** Do **not** use UNetbootin; it does not work with the Proxmox image. Writing erases the stick.

- **Windows, balenaEtcher** (simplest): install from etcher.io, choose the ISO, choose the USB stick, press *Flash*.
  No extra setting is needed.
- **Windows, Rufus**: choose the stick and the ISO, press *Start*; when asked to download another GRUB version
  answer **No**; in the next dialog select **DD mode**.
- **Linux**: find the stick's device name: run `lsblk`, plug the stick in, run `lsblk` again; the new line is the stick
  (check the size). Then, with `/dev/XYZ` replaced by that name (for example `/dev/sdb`, **not** a partition such as `sdb1`):
  `sudo dd bs=1M conv=fdatasync if=./proxmox-ve_9.2-1.iso of=/dev/XYZ`.
  **The wrong device name erases that disk.** Check twice.
- **macOS**: `hdiutil convert proxmox-ve_9.2-1.iso -format UDRW -o proxmox-ve_9.2-1.dmg`; `diskutil list` before and after
  plugging in the stick to find `/dev/diskN`; `diskutil unmountDisk /dev/diskN`;
  `sudo dd if=proxmox-ve_9.2-1.dmg bs=1M of=/dev/rdiskN` (`rdisk` is intended: faster).

When it finishes, remove the stick safely (eject).

### 3.4 Read the bench LAN values from your PC (for D6 and D7)

- Windows: `ipconfig /all` → "Default Gateway" and "DNS Servers".
- Linux/macOS: `ip route | head -3` (Linux) or `route -n get default` (macOS) for the gateway; `resolvectl status` or `cat /etc/resolv.conf` for DNS.

---

## 4. Part B: connect and set up the machine (BIOS)

1. Plug in the monitor, keyboard and the **network cable**. Do not plug in the stick yet. Power on.
2. As soon as the logo appears, press the key for **BIOS setup**. **[check]** The key is shown at the bottom of the logo
   screen; on Fujitsu machines usually **F2** (setup) and **F12** (one-time boot menu). If nothing happens, restart and try `Esc`, `Del`, `F2`, `F12`.
3. Look at the information page and **write down**: CPU model, memory size, disk model and size, firmware version.
   - Expected **[check]**: 16 GB memory, 256 GB disk (as the owner described). Linux tools and the Proxmox web page show a
     256 GB disk as about **238 G** (GiB, not GB): that is the same disk. If the numbers differ more than that, tell Claude before going on.
4. Find the virtualization setting. **[check]** It is usually called **Intel Virtualization Technology** (or *VT-x*,
   *Virtualization*), under *Advanced* or *CPU*. It must be **Enabled**.
   (The bench machine f22, the same S940 model, has VT-x, seen on 2026-11-17; this machine was not seen.)
5. Leave **VT-d** at its default. It is only needed for passing hardware through to VMs, which we do not do.
6. Secure Boot: **[doc]** Proxmox installers from 8.1 on work with Secure Boot on. If the stick does not boot, turn Secure Boot **off** and try again.
7. Make sure booting from **USB** is allowed. Save and exit (usually **F10**).
8. Power off. Plug in the stick.

---

## 5. Part C: install Proxmox (at the machine)

1. Power on and press the **boot menu key** (**[check]** F12 on Fujitsu; see the logo screen). Choose the USB stick
   (its name may contain "USB" or the brand of the stick, possibly with "UEFI:" in front).
2. The Proxmox boot menu appears. **[doc]** Choose **Install Proxmox VE (Graphical)**. If the screen stays black
   or garbled, restart and choose **Install Proxmox VE (Terminal UI)**; all the questions below are the same.
   It may pause a few seconds while it looks for the network. Wait for the license screen.
3. **License (EULA):** read it, press **I agree**.
4. **Target disk screen:** **[doc]** the default is the whole disk. Check that the disk shown is the 256 GB SSD
   (**not the USB stick**). Press **Options**:
   - **Filesystem: ext4** (the default). **[doc]** ext4 uses LVM and gives the `local` and `local-lvm` storage you need for snapshots.
     Do **not** choose ZFS (it wants more RAM and we do not need it). BTRFS is only a technology preview. Do not choose it.
   - Advanced settings (`hdsize`, `swapsize`, `maxroot`, `maxvz`, `minfree`): **leave all defaults**.
   - Press **OK**, then **Next**. **Last chance before the disk is erased in the next steps: confirm D10 = yes.**
5. **Location and time zone:** country, time zone (for the bench, `Europe/Bucharest` **[check]** or your own), keyboard layout.
   Wrong time breaks later steps (certificates, updates): choose the right zone.
6. **Administration password and e-mail:** enter the password from D8 twice and the e-mail from D9. **[doc]** At least 8 characters.
7. **Management network configuration** (the field names of this screen are from my knowledge **[check]**):
   - **Management interface:** the drop-down shows the network card(s). **[doc]** A filled circle means the link is UP.
     Choose the one with the filled circle. Write down the **MAC address** shown beside it **[check]** (D11).
   - **Hostname (FQDN):** `sandbox.home.arpa` (D3).
   - **IP Address (CIDR):** D4 with the prefix, for example `192.168.20.xxx/24` (D5).
   - **Gateway:** D6. **DNS Server:** D7.
   - Leave **Advanced Options** (bond, VLAN, name pinning) untouched. **[doc]** You can set an IPv4 or an IPv6 address, not both: use IPv4.
   - The installer may propose an address it got from DHCP. Replace it with D4 unless it is already D4. If you chose way (b)
     in section 1, this is the screen where you read the MAC; make the router reservation **now, before step 8 (Install)**.
8. **Summary screen:** read every line: disk, filesystem ext4, time zone, e-mail, **IP**, **hostname**.
   Use **Previous** to correct anything. Leave **Automatically reboot after successful installation** ticked (default).
   Press **Install**. Copying takes about 5-10 minutes.
9. Leave **Automatically reboot** ticked. Wait for the screen that says the installation succeeded. **[doc]** The restart comes by
   itself after a few seconds. **Pull the USB stick when the screen goes black** (otherwise the machine may boot the installer again;
   if it does, remove the stick and restart, see section 9).
10. The machine boots from the SSD. After about a minute a text screen shows:

    ```
    Welcome to the Proxmox Virtual Environment. Please use your web browser to configure this server -
    connect to:
        https://192.168.20.xxx:8006/
    sandbox login:
    ```

    The exact text and line breaks may differ **[check]**; the address and `sandbox login:` are what matter.
    **PASS** = this screen, with **your** address (D4) and the name `sandbox`. This text screen is the console;
    there is no desktop. Do not type anything yet.

If the machine boots the stick again, or shows "no bootable device": see section 9.

---

## 6. Part D: first login from your PC

1. On your PC open the browser at **`https://<D4>:8006`** (**https**, with the port **8006**; **[doc]** this is the standard Proxmox port).
2. The browser warns that the certificate is not trusted. This is expected: Proxmox made its own certificate.
   Choose *Advanced* → *Continue* / *Accept the risk*. (Only do this for the address you just installed.)
3. The login window: **User name** `root`, **Password** D8, **Realm** *Linux PAM standard authentication*, **Language** as you like.
4. A window "**No valid subscription**" appears. Press **OK**. It appears at every login. It is not an error.
5. You see the web interface: on the left the tree *Datacenter → sandbox*; in the middle *Summary*.

**PASS** = you are logged in and *sandbox* is in the tree with a **green** check or no red marks.

---

## 7. Part E: switch to the free update source and update

The installer sets up the **paid** update source. Without a key it gives errors when updating. Switch it off and
switch on the free one.

### 7.1 In the web page

1. Click **sandbox** in the tree → **Updates** → **Repositories**.
2. Under *Repositories* you will see a line with `pve-enterprise` (and possibly one for Ceph). Select the `pve-enterprise` line → press **Disable**.
   If a Ceph enterprise line shows, disable it too: if it stays enabled, **Refresh** and check S14 fail with `401`.
   (I do not know whether the 9.2 installer enables that line **[check]**.)
3. Press **Add** → in the window choose **No-Subscription** → **Add**.
   A warning that this source is "not recommended for production" is shown: fine for the lab.
4. In the list, **pve-no-subscription** must have a green tick; **pve-enterprise** must be shown as disabled.
   (**[doc]** On PVE 9 the files are `/etc/apt/sources.list.d/proxmox.sources` for the free source and
   `pve-enterprise.sources` for the paid one, with `Enabled: no` added in the latter; the buttons above do this for you.)

### 7.2 Update

1. Still under **Updates**: press **Refresh** → a task window ends with `TASK OK`. **PASS** = `TASK OK`, no red error lines.
   If you see `401 Unauthorized` for `enterprise.proxmox.com`: the pve **or the ceph** enterprise source is still on; disable it (7.1).
2. Press **Upgrade** → a console window opens, asks `Do you want to continue? [Y/n]`: type `Y`, press Enter. It can take 5-15 minutes.
   Wait for the end of the text and the line `TASK OK` (or the shell prompt), then close the window.
3. If the list included a **kernel** (`proxmox-kernel`) **[check]**, reboot: **sandbox → Reboot** (top right) → Yes. Wait 2-3 minutes; the web page reloads by itself, log in again.

---

## 8. Part F: verification (the PASS list)

Run every check. A check is **PASS** only if you saw the expected result. Mark it. Anything not PASS is written down with the
exact text on the screen (see section 9).

### 8.1 In the web page

| # | Where | Expected | PASS |
|---|---|---|---|
| V1 | sandbox → **Summary** | *Version* line shows `pve-manager/9.2.x` (or the version you installed). **Uptime** counts. CPU(s) **4**. **Memory** total about **16 GB** (a little less is normal). | ☐ |
| V2 | sandbox → **Disks** | one SSD of about **238 G** (= the 256 GB of the label; GiB vs GB); the **SMART** column says **PASSED** | ☐ |
| V3 | Datacenter → **Storage** | two entries: **local** (type *Directory*) and **local-lvm** (type *LVM-Thin*); both *Enabled* | ☐ |
| V4 | sandbox → **System → Network** | a **vmbr0** of type *Linux Bridge*, with your **IP/CIDR** (D4), your **gateway** (D6) and the network card as *Bridge ports* | ☐ |
| V5 | sandbox → **System → DNS** | your DNS server (D7), search domain `home.arpa` | ☐ |
| V6 | sandbox → **System → Time** | the *Time zone* is right and the time shown equals the time on your PC (±1 min) | ☐ |
| V7 | sandbox → **Updates → Repositories** | **no-subscription enabled**, **enterprise disabled**; after *Refresh* → `TASK OK` | ☐ |
| V8 | sandbox → **Updates** | after *Upgrade* the list is empty (or only new items after another Refresh) | ☐ |

### 8.2 On the host shell

Open the shell in the web page: **sandbox → Shell** (a black text window; you are `root`). Type each command, press Enter.
The expected outputs in this table (service names in S7, the volume lines in S11, the clock line in S13) are from my knowledge **[check]**.

| # | Command | Expected | PASS |
|---|---|---|---|
| S1 | `pveversion` | `pve-manager/9.2.x/...` | ☐ |
| S2 | `hostname -f` | `sandbox.home.arpa` | ☐ |
| S3 | `ip -br a` | the line for `vmbr0` is `UP` with your IP/CIDR; the real card is `UP` | ☐ |
| S4 | `ping -c 3 <D6 gateway>` | `0% packet loss` | ☐ |
| S5 | `ping -c 3 1.1.1.1` | `0% packet loss` (internet reachable) | ☐ |
| S6 | `ping -c 3 deb.debian.org` | answers (DNS works) | ☐ |
| S7 | `systemctl is-active pveproxy pvedaemon pve-cluster pvestatd` | four lines `active` | ☐ |
| S8 | `ls -l /dev/kvm` | the file exists (this proves that VT-x is enabled and the CPU can run VMs) | ☐ |
| S9 | `lscpu \| grep -i virtualization` | `Virtualization: VT-x` | ☐ |
| S10 | `pvesm status` | `local` and `local-lvm`, both `active` | ☐ |
| S11 | `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT` then `vgs` then `lvs` | `lsblk`: the SSD with partitions, and lines `pve-root`, `pve-swap` and `pve-data…` of type `lvm`. `vgs`: one group `pve`. `lvs`: volumes `root`, `swap`, `data` | ☐ |
| S12 | `df -h /` | the root file system has free space (more than 50 %) | ☐ |
| S13 | `timedatectl` | `System clock synchronized: yes` | ☐ |
| S14 | `apt update` | ends without `Err:` lines; may say "N packages can be upgraded" | ☐ |
| S15 | `dmesg --level=err,crit \| tail -20` | no repeating errors (a few at boot are not a fault; write down what you see) | ☐ |

### 8.3 Reboot test

1. Top right of the web page: **Reboot** → Yes. (Or in the shell: `reboot`.)
2. Watch the monitor: it must reach the same `sandbox login:` screen (section 5, point 10).
3. Within 3 minutes the web page must answer again at the same address. Log in. V1 and S3 must still be PASS.

**PASS** = back with the same address and name, with no keyboard action on the machine.

### 8.4 Power-off test and the "headless" step

1. In the shell: `shutdown -h now`. The machine switches off. Unplug the monitor and keyboard.
2. Power it on with the button. It must come back (web page) **without a monitor or keyboard** in about 3 minutes.
   **PASS** = V1 shows again. Now the machine can stand anywhere with power and network.

---

## 9. When something goes wrong

At the first failure write down the **exact text** (or take a photo of the screen) before changing anything.
At this stage the machine holds nothing of value: **the cheapest fix is to install again** (Part C), which takes about 15 minutes.

| Symptom | What to do |
|---|---|
| The machine does not start from the stick | Check that the stick is in a USB port directly on the machine. In the BIOS (Part B) allow USB boot; try the boot menu key; try a different USB port (a USB 2 port is more tolerant); try Secure Boot off. Write the stick again (3.3) if the PC showed an error. |
| The graphical installer is black or garbled | Restart and choose **Terminal UI** in the boot menu. |
| Installer message that **KVM / hardware virtualization is not available** | Go to the BIOS (Part B step 4), enable *Intel Virtualization Technology*, save, and start the installer again. |
| No network card in the list, or no filled circle | Check the cable and the link light; try another cable or switch port. If the list is empty, write down the text and stop. |
| Installer says the hostname/FQDN is invalid | It needs a full name with a dot, letters, digits and hyphens only, for example `sandbox.home.arpa`. |
| The installer boots again after the restart | You left the stick in. Remove it and restart. |
| The web page does not open | (1) Is the address https and port 8006? (2) From your PC: `ping <D4>`. No answer → check the cable, the address D4 (is it free? is it inside the network 192.168.20.x?) and the gateway. (3) Try another browser. (4) At the machine's console `ip -br a` shows what address it really has. |
| The browser says "connection refused" but ping works | On the shell: `systemctl status pveproxy`. If not active, write down the text. |
| Wrong address or hostname typed at the install | Install again (fastest). Do not edit the system files on a first try. |
| `Refresh` gives `401 Unauthorized` or `enterprise.proxmox.com` errors | The enterprise source is still enabled: do 7.1 again. |
| The time is wrong | Check the time zone (V6) and `timedatectl` (S13); NTP needs the internet (S5). |
| Forgot the root password | Install again. |

---

## 10. Record what was done (the owner's hands, 5 minutes)

When all of section 8 is PASS, note for the node row in `nodes/WebLab/INDEX.md`:
**MAC (D11), IP (D4), hostname, Proxmox version (S1), install date, CPU/RAM/disk as read in Part B**, and the
way chosen in section 1 ((a) outside the DHCP range, or (b) reservation made, with its date). Claude updates the node row from these values; **never** the password.

**What is in place now:** one Proxmox host on the bench LAN with the free update source. It has **no isolation yet**:
at this moment it is a normal machine on 192.168.20.x. It accepts **SSH as `root` with the password** on port 22, and the
web page on port 8006, from the whole bench LAN **[check]** (the Proxmox default). That is the main exposure until the firewall step,
and the reason for D8 (a long, unique password). Closing or limiting SSH is a decision for the next document. Until that document (internal network `vmbr1` and firewall)
is done and checked:

- do **not** start Claude Code on the Proxmox host (never, in the end: only inside the lab container),
- do **not** create VMs or containers,
- do **not** put keys (SSH, GitHub, tokens) on it, and do **not** give f22 or futro an SSH key to it.

## 11. What comes next (not in this file)

Plan of `second-futro-usage-fable-20261114-part2.md`: step 2 internal bridge `vmbr1` with NAT; step 3 firewall (the lab cannot
reach 192.168.20.x or the host); step 4 container `lab1` with a snapshot `clean`. A separate document, written after this one is PASS.

## Sources (official, read 2026-11-17)

- Proxmox VE downloads: https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso
- Installation chapter: https://pve.proxmox.com/pve-docs/chapter-pve-installation.html and https://pve.proxmox.com/wiki/Installation
- Prepare installation media: https://pve.proxmox.com/wiki/Prepare_Installation_Media
- Package repositories: https://pve.proxmox.com/wiki/Package_Repositories

## Not checked

The machine itself (CPU, RAM, disk, BIOS keys and menu names, video ports); the router (DHCP range, reservation, gateway address,
DNS); whether the 9.2 installer enables the Ceph enterprise entry; the exact field names and look of the installer screens of 9.2 (they are from my knowledge, marked [check]); whether the
installer offers DHCP; whether `home.arpa` suits your network; the stick-writing tools on your PC.
