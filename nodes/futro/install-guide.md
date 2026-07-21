# Futro — Installation Guide (Human Section, Step by Step)

**Who this is for:** you don't need to know Linux to follow this. Every screen you'll
see is described, every button to click/press is named, every command to type is given
exactly as you should type it. This covers the physical, at-the-machine part only —
section 3 ("Human install prep") of [`setup-plan.md`](setup-plan.md). Once you reach
the last step here, everything else is done remotely by Claude — you're finished.

**What you'll need:**
- The Fujitsu Futro S740 itself, plugged into power and to your network (ethernet
  cable) — WiFi is not assumed to be available/configured yet, use a wired connection.
- A monitor and a USB keyboard, connected directly to the Futro (temporarily — you can
  disconnect them once it's headless and working over SSH).
- A USB flash drive, at least 2 GB, that you don't mind erasing.
- Any other computer (Windows, Mac, or Linux — doesn't matter) with internet access,
  to download the installer and write it to the USB drive.
- About 30–45 minutes.

---

## Part 1 — Prepare the installer USB drive

You do this on your **other computer** (not the Futro).

### 1.1 Download Debian

1. Open a web browser and go to: **https://www.debian.org/distrib/netinst**
2. Look for a link that says something like **"Small CDs or USB sticks"** and under it
   a file named like `debian-13.x.x-amd64-netinst.iso` (the exact numbers after "13."
   will vary — always take the current one, don't search for an older version).
3. Click it and let it download. It's a few hundred MB, might take a few minutes.

### 1.2 Write it to the USB drive

The easiest tool for this, on any operating system, is **balenaEtcher** (free, no
account needed):

1. Go to **https://etcher.balena.io/** and download the version for your computer
   (Windows / Mac / Linux).
2. Install and open it.
3. Plug in your USB drive.
4. In Etcher, click **"Flash from file"** and select the `.iso` file you downloaded.
5. Click **"Select target"** and choose your USB drive. **Double-check this is the
   right drive** — everything on it will be erased.
6. Click **"Flash!"**. Wait for it to finish (it writes, then verifies — a progress
   bar shows both).
7. When it says done, safely eject the USB drive.

*(If you'd rather use Rufus on Windows instead of Etcher, that works too — same idea:
select the ISO, select the USB drive, write it. Etcher is recommended because it's
identical on every operating system.)*

---

## Part 2 — Boot the Futro from the USB drive

1. Plug the USB drive into the Futro.
2. Connect the monitor and keyboard to the Futro if you haven't already.
3. Turn the Futro on (or restart it if it was already on).
4. **Immediately** start tapping a key to open the boot menu — on Fujitsu machines
   this is usually **F12**. Watch the first screen that appears when it powers on; it
   often shows a small hint like "Press F12 for Boot Menu" in a corner. If F12 doesn't
   work, try **Esc** or **F2** (which usually opens BIOS/UEFI settings instead, where
   there's normally a "Boot Menu" or "Boot Override" option).
5. A short menu appears listing bootable devices. Look at the entries carefully:
   - If you see **two** entries for your USB drive — one plain, one labeled **"UEFI"**
     — pick the **UEFI** one, and remember: **this machine boots UEFI**.
   - If you only see **one** entry with no "UEFI" label, it's booting in **Legacy/BIOS**
     mode — remember: **this machine boots Legacy/BIOS**.
   - **Write down which one it was** — you need this in Part 3, step 3.7 (partitioning).
6. Select the USB entry and press Enter.

---

## Part 3 — Run the Debian installer

The screen will show the Debian installer boot menu after a short pause.

### 3.1 Start screen

Use the arrow keys to select **"Graphical install"** (not the plain "Install" option —
graphical is mouse-driven and much easier to follow) and press Enter.

### 3.2 Language, location, keyboard

Three simple screens, click **Continue** through each:
1. **Select a language** — pick English (or your preference), Continue.
2. **Select your location** — pick your country, Continue.
3. **Configure the keyboard** — pick your keyboard layout, Continue.

### 3.3 Network setup

The installer detects your network card and, if the ethernet cable is connected, gets
an address automatically (DHCP) — this can take a few seconds, you'll see a brief
"Configuring the network" progress screen. No action needed unless it fails; if it
does, make sure the ethernet cable is actually plugged in at both ends and retry.

### 3.4 Hostname

A screen titled **"Configure the network"** asks for a hostname:

- Type exactly: **`futro`**
- Click Continue.

Next screen asks for a **domain name** — leave it **blank**, click Continue.

### 3.5 Passwords and your user account

1. **"Set up users and passwords" — root password:** leave both password fields
   **blank** and click Continue. (Debian will ask you to confirm this is intentional —
   confirm. Leaving it blank disables the root account and instead gives your personal
   account admin rights via `sudo`, which is what we want.)
2. **Full name for the new user** — type your name (e.g. `Dan Petrar`), Continue.
3. **Username for your account** — a short lowercase name gets suggested automatically
   (e.g. `dan`). You can keep it or change it. **Write this username down** — you'll
   need it later to log in and to connect from the Pi.
4. **Choose a password** — type a password, Continue, then type it again to confirm.
   Write this down too (or use a password manager) — you'll need it a few more times
   during setup.

### 3.6 Clock

**"Configure the clock"** — pick your time zone from the list, Continue.

### 3.7 Partitioning — the important part

This is the step that needs care. **Before you start, recall what you wrote down in
Part 2, step 5: is this machine UEFI or Legacy/BIOS?** The steps below note where that
matters.

1. On the **"Partition disks"** screen, from the dropdown/list, choose:
   **"Manual"** (not "Guided"). Continue.

2. You'll see a list with your disk (something like `SCSI1 (0,0,0) (sda) - 500.1 GB`,
   the exact name doesn't matter). **Click on the disk itself** (the top-level line,
   not any partition under it — it likely has none yet).

3. It will ask: **"Create new empty partition table on this device?"** — click **Yes**.

4. The disk now shows one line: **"FREE SPACE"**. Click on it, then click
   **"Create a new partition"**.

5. **If this machine is UEFI** (from Part 2): create the EFI partition first.
   - **New partition size:** type `512` and make sure the unit is **MB** (megabytes),
     Continue.
   - **Type for the new partition:** choose **Primary**, Continue.
   - **Location for the new partition:** choose **Beginning**, Continue.
   - On the partition settings screen, find the line **"Use as:"** and click it —
     change it from the default to **"EFI System Partition"**. Leave everything else
     as shown. Click **"Done setting up the partition"**.

   **If this machine is Legacy/BIOS:** skip this whole step 5 — no EFI partition.

6. Create the swap partition. Click on the remaining **"FREE SPACE"** line, then
   **"Create a new partition"** again.
   - **New partition size:** type `8` and make sure the unit is **GB** (gigabytes),
     Continue.
   - **Type:** Primary (or Logical if the installer forces it after a few primaries —
     either is fine), Continue.
   - **Location:** Beginning, Continue.
   - On the settings screen, click **"Use as:"** and change it to **"swap area"**.
     Click **"Done setting up the partition"**.

7. Create the root partition with everything that's left. Click the remaining
   **"FREE SPACE"** line, **"Create a new partition"**.
   - **New partition size:** it will show the maximum available (roughly 490 GB) —
     just press Continue to accept all of it, don't type a smaller number.
   - **Type:** Primary, Continue.
   - On the settings screen, confirm:
     - **"Use as:"** should already say **"Ext4 journaling file system"** (that's the
       default — leave it).
     - **"Mount point:"** click it and choose **`/ — the root file system`**.
   - Click **"Done setting up the partition"**.

8. You should now see three lines under your disk (or two, if Legacy/BIOS): the EFI
   partition (if UEFI), the swap partition, and the ext4 `/` partition using the rest
   of the disk. Double check nothing says "FREE SPACE" anymore.

9. Click **"Finish partitioning and write changes to disk"**.

10. It asks **"Write the changes to disks?"** — review the summary shown, then select
    **Yes** and Continue. This is the point of no return for the disk — after this, the
    old contents of the drive are gone.

### 3.8 Base system install

The installer copies files for a few minutes — no action needed, just wait.

### 3.9 Package manager / mirror

1. **"Scan another CD or DVD?"** — select **No**.
2. **"Use a network mirror?"** — select **Yes**.
3. Pick your country, then pick any mirror from the list (the first one is fine).
4. **HTTP proxy** — leave blank, Continue.

### 3.10 Software selection — the important second part

A screen titled **"Software selection"** shows a checklist with checkboxes, something
like:

```
[*] Debian desktop environment
[ ]    ... GNOME
[ ]    ... KDE Plasma
[ ]    ... Xfce
[*] web server
[*] SSH server
[*] standard system utilities
```

(exact list varies by Debian version). Using arrow keys + **spacebar** (or clicking
with the mouse, since you're in graphical mode) to toggle each box:

- **Uncheck** "Debian desktop environment" and everything under it (GNOME/KDE/Xfce/etc.)
- **Uncheck** anything else that isn't in the list below
- **Make sure these two, and only these two, stay checked:**
  - `[*] SSH server`
  - `[*] standard system utilities`

Continue.

### 3.11 Bootloader (GRUB)

1. **"Install the GRUB boot loader?"** — select **Yes**.
2. **"Device for boot loader installation"** — choose the **whole disk** entry (e.g.
   `/dev/sda` or `/dev/nvme0n1` — it will look like the disk itself, not one of the
   partitions you created; don't pick a `...p1`/`...1` line). Continue.

### 3.12 Finish

**"Installation complete"** — click Continue. The machine reboots. **Remove the USB
drive** when the screen goes blank/restarts (before it boots again), so it boots from
the internal disk instead of starting the installer over.

---

## Part 4 — First boot: confirm it's working

After reboot you'll see a plain black screen with a login prompt (this is expected —
we chose no desktop environment on purpose).

1. Log in: type the **username** and **password** you set in step 3.5, pressing Enter
   after each.
2. Once logged in, you'll see a `$` prompt. Type this command and press Enter:
   ```
   ip addr
   ```
   Look through the output for a line starting with `inet` under an entry that isn't
   named `lo` (that one's just the machine talking to itself) — it'll look like
   `inet 192.168.110.XXX/24 ...`. **Write down that IP address** — you'll need it for
   the last step.
3. Confirm SSH is running:
   ```
   systemctl status ssh
   ```
   Look for the word **"active (running)"** in green near the top of the output. Press
   **`q`** to get back to the prompt.

If both of those worked, the installer part is done and correct.

---

## Part 5 — Connect the Pi (the one step that must happen here, physically)

The Pi can't remotely connect to this machine until it's told to trust it — that
trust has to be set up once, by hand, at the keyboard you're sitting at right now.

**On the Pi** (a different machine — ask whoever manages it to run this and read you
the result, or do it yourself if you have access):
```
cat ~/.ssh/id_ed25519.pub
```
This prints one line of text starting with `ssh-ed25519 AAAA...` — copy that **entire
line** exactly as shown.

**Back on the Futro**, at the login prompt from Part 4, type these commands one at a
time, pressing Enter after each. Where it says `<paste the line here>`, type or paste
the exact line you copied from the Pi (don't include the `<` `>` symbols):

```
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "<paste the line here>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**That's the last step.** From here, someone on the Pi runs this (using the IP address
you wrote down in Part 4, and the username from step 3.5):

```
ssh <your-futro-username>@<the-ip-address-you-wrote-down> 'echo ok'
```

If that prints `ok` with no password prompt, the connection is trusted and working —
**your part is finished.** Everything else (installing Claude Code, setting up git,
cloning the project repositories, and so on) happens automatically from the Pi over
this connection — see [`setup-plan.md`](setup-plan.md) section 4 onward.

You can now unplug the monitor and keyboard from the Futro if you'd like — it doesn't
need them anymore.
