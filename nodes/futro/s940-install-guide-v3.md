# Futro S940 (f22) — fresh Debian install: every step for your hands (v3)

Date: 2026-10-30. v1, v2 kept. v3 applies Fable's v2 review `s940-review-v2-fable.md` (V1-V9 and smaller points).
For the two new Fujitsu Futro S940 (Intel J5005, 4 GB RAM). Method: one USB stick that installs Debian 13
automatically (preseed). Claude prepares the stick on the Pi and does all work after the install over SSH.
This file lists only what your hands do, in order. The password of `pi` is typed at install (Part 6). Plan: `s940-stick-plan-v3.md`.

Marks: **[STOP]** = stop and reply to Claude before you go on. **[CHECK]** = compare with your eyes.

---

## Part 0 — What you need, and what you decide first

| Item | For |
|---|---|
| The USB stick from the July futro install (>= 2 GB) | the installer; its content is erased |
| A monitor + its cable, a USB keyboard | each S940, only during the install |
| An Ethernet cable to the LAN switch (same LAN as the Pi) | each S940; the installer downloads packages |
| The replacement SSDs: 220 GB (S940 #1, now), 250 GB (S940 #2, next week); a small screwdriver | Part 3 |
| A phone camera | photos of the screen at the [STOP] points |

Decide before the stick is built (Claude asks one at a time):
- the hostname of S940 #1 is **`f22`**. The user is `pi`. Both are written into the stick: at install
  you type nothing.
- the other points in the plan's "Open decisions" table.

---

## Part 1 — (none)

No step before the install: the password of `pi` is typed on the f22 screen during the install (Part 6).

---

## Part 2 — Stick into the Pi (after tonight's 20:02 grid judgment)

Reason for the time: the Pi's USB controller can hang when a USB device is plugged in, and its fix disconnects every
USB device of the Pi. After the grid run is judged nothing is at risk.

1. Plug the USB stick into a free USB port of the Pi. Do not plug any other USB disk at the same time.
2. **[STOP]** Reply `plugged`. Claude reads the stick (size, maker, content) and reports. Nothing is written until you
   give the word for the write.
3. Claude builds the installer, writes it to the stick (~2 min), reads it back and compares. Wait for `stick ready`.
4. Unplug the stick from the Pi.
5. Label the stick: **"AUTO INSTALL — ERASES DISK"**.

---

## Part 3 — Replace the SSD (S940 #1: 220 GB; S940 #2: 250 GB)

The factory 32 GB SSD is too small for the planned use. (If you chose the test install on the 32 GB SSD first, do
Part 4 to Part 7 once with the factory SSD, then come back here.)

1. Unplug the power cable of the S940. Wait 10 s.
2. Touch a metal part (radiator, PC case) to discharge yourself.
3. Open the case following the Fujitsu S940 manual.
4. Remove the 32 GB SSD (one screw). **[CHECK]** Put it next to the new SSD and compare:
   - the **connector**: same notches (key) in the same places;
   - the **length**: the same, so it reaches the screw post (expected 2280 = 80 mm);
   - the label of the new SSD says **SATA** (not NVMe).
   If any of the three differs: do not fit it, take a photo of both, **[STOP]**.
5. Put the 32 GB SSD in an antistatic bag, write "S940 #1 factory 32 GB" on it, keep it (the way back).
6. **Only if you chose the no-disk test (plan D5, ~5 min):** with **no SSD fitted**, close the case loosely, do
   Part 4 and Part 5, choose the automated entry in Part 6. Expected: the screen stops on the partitioner with
   "no single internal disk found" and does not move. Take a photo, hold power 5 s, unplug power, **[STOP]**.
   Continue only after Claude says `fail path PASS`.
7. Insert the new SSD at the same angle, press it down, put the screw back.
8. Close the case.

---

## Part 4 — Connect the S940

1. Ethernet cable from the S940 to the LAN switch.
2. Monitor and USB keyboard to the S940.
3. The stick to a USB port of the S940. No other USB disk.
4. Power cable last.

---

## Part 5 — Boot from the stick

1. Press the power button.
2. **At once** tap **F12** about twice per second until the boot menu appears (F12 = boot menu on the S940; F2 = setup).
   - If the Fujitsu logo passes without a menu: hold the power button 5 s, try again.
   - If F12 or F2 asks for a **password** (a used unit can have one set): take a photo, **[STOP]**.
3. The menu lists devices. Choose the entry with **UEFI** and the stick's name (e.g. `UEFI: SanDisk ...`).
   If there is no UEFI entry: take a photo, **[STOP]**.
4. Press Enter.

---

## Part 6 — The installer

1. The Debian menu appears and waits (it never starts by itself). The stick is built so that the highlighted first
   line is the plain **"Install"** (the usual Debian first line "Graphical install" is moved down): do **not** take it.
2. With the **arrow keys** go to **"Automated install f22 (erases internal disk)"**.
   Check the hostname on that line is the one for this machine. Press **Enter**.
3. After 1-2 minutes (hardware detection, network) the installer asks **"Choose a password for the new user"**:
   type the password for `pi`, Enter; it asks again to verify: type it again, Enter. Nothing is shown while you
   type. This is the only typing.
4. From here you type nothing. Text and progress screens pass for 10-20 minutes:
   partitioning, "Installing the base system", "Configuring apt", "Select and install software" (the longest),
   "Installing GRUB", "Finishing the installation".
5. **If any other question or an error screen appears** (for example "no single internal disk found",
   or any question): do not answer it. Take a photo, **[STOP]**, send it to Claude.
   If it appears before the partitioning screens, holding power 5 s is safe: nothing was written.
   The same if the **partitioner screen does not move for 5 minutes**: the disk check has stopped the install on
   purpose. Photo, **[STOP]**.
6. At the end the S940 **switches itself off**. Then pull the stick out.

---

## Part 7 — First start: one photo

1. Press the power button (stick out). The machine starts from its SSD.
2. After about 30 s a login prompt appears. Above it:

   ```
   Host: <hostname>
   IP:   192.168.20.x
   MAC:  xx:xx:xx:xx:xx:xx
   ```

   If the `IP:` line is empty, press **Enter** once: the screen is redrawn (the network can come up after the prompt).
3. **Take a photo** of the screen. You do not need to log in.
4. **[STOP]** Send Claude the photo, or reply `up <hostname> <IP> <MAC>`. Claude connects from the Pi over SSH and
   continues without your hands.
   - Still no IP after Enter: the cable or the switch port has no link. Send the photo; change nothing.

---

## Part 8 — Finish

1. When Claude says `remote setup reachable`, unplug the monitor and the keyboard.
2. Leave power and Ethernet connected. Put the S940 where it will live.

---

## Part 9 — The second S940 (not planned yet)

When it is planned, Claude rebuilds the stick with its entry (Part 2 again). Then Part 3 to Part 8, with the 250 GB SSD.

---

## Things not to do

- Do not boot any other computer from this stick and choose an "Automated install" entry: it erases that computer's
  internal disk.
- Do not answer any installer question other than the password. Another question means the stick is missing a setting; Claude fixes the stick.
