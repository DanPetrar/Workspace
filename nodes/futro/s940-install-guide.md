# Futro S940 — fresh Debian install: every step for your hands

Date: 2026-10-30. For the two new Fujitsu Futro S940 (Intel J5005, 4 GB RAM).
Method: one USB stick that installs Debian 13 automatically (preseed). Claude prepares the
stick on the Pi and does all work after the install over SSH. This file lists only what your
hands do, in order. The July guide for the current futro is `install-guide.md` (not used here).

Marks: **[STOP]** = stop and reply to Claude before you go on. **[CHECK]** = something
Claude has not looked up; check it with your eyes.

---

## Part 0 — What you need

| Item | For |
|---|---|
| The USB stick from the July futro install (>= 2 GB) | the installer; its content is erased |
| A monitor + its cable, a USB keyboard | each S940, only during the install |
| An Ethernet cable to the LAN switch (same LAN as the Pi) | each S940; the installer downloads packages |
| The replacement SSD (220 GB now, 250 GB next week) and a small screwdriver | only if you install on the bigger SSD |
| A pen or a phone camera | to note the hostname, IP and MAC at the end |

Choose the two hostnames before you start (example: `futro2`, `futro3`; your choice). Do not use
`futro` or `raspi`: those names are taken on the LAN.

---

## Part 1 — Password for the new machines (on the Pi, before the stick is built)

The same password is used on both S940 for your user (for `sudo` and the console login).
Claude never sees it in plain text: you write only its hash into a file.

1. Open **your own** terminal on the Pi (SSH or local), not the Claude prompt.
2. Type exactly this and press Enter:

   ```
   openssl passwd -6 > ~/Workspace/nodes/futro/setup/s940-pw.hash
   ```

3. It asks `Password:` — type the password, Enter. It asks `Verifying - Password:` — type it
   again, Enter. Nothing is shown while you type; that is normal.
4. Check the file has one line starting with `$6$`:

   ```
   cut -c1-3 ~/Workspace/nodes/futro/setup/s940-pw.hash
   ```

   It must print `$6$`. If not, repeat step 2.

**[STOP]** Reply `password` to Claude.

---

## Part 2 — Stick into the Pi

1. Plug the USB stick into a free USB port of the Pi. Do not plug any other USB disk at the
   same time.
2. **[STOP]** Reply `plugged`. Claude reads the stick (size, maker, content) and reports it.
   Nothing is written until you give the word for the write.
3. Claude builds the installer and writes it to the stick (about 10 min), then reads it back and
   compares it. Wait for Claude's line `stick ready`.
4. Unplug the stick from the Pi.
5. Put a label on the stick: **"AUTO INSTALL — ERASES DISK"**. Reason: if a computer boots
   from this stick and you choose the automatic entry, it erases that computer's internal disk
   without asking.

---

## Part 3 — Replace the SSD (only if you install on the bigger SSD)

Skip this part to install on the 32 GB SSD that is already inside.

**[CHECK]** Claude has not looked up the inside of the S940. Before you open it:
- read the label of the replacement SSD: it must say **SATA**. The S940 slot is assumed to be
  M.2 SATA; an **NVMe** SSD will not be seen. If it says NVMe, stop and tell Claude.
- the form factor must fit the slot (M.2 length, e.g. 2280; or 2.5" if your S940 has that bay).

1. Unplug the power cable of the S940. Wait 10 s.
2. Touch a metal part (radiator, PC case) to discharge yourself.
3. Open the case following the Fujitsu S940 manual.
4. Remove the 32 GB SSD (one screw). Put it in an antistatic bag and write "S940 #1 factory
   32 GB" on it. Keep it: it is the way back.
5. Insert the replacement SSD at the same angle, press it down, put the screw back.
6. Close the case.

---

## Part 4 — Connect the S940

1. Ethernet cable from the S940 to the LAN switch.
2. Monitor and USB keyboard to the S940.
3. The stick to a USB port of the S940.
4. Power cable last.

---

## Part 5 — Boot from the stick

1. Press the power button.
2. **At once** tap **F12** about twice per second until a boot menu appears. (F12 is the
   Fujitsu boot menu key; on the current futro, an S740, the machine booted UEFI.)
   - If the Fujitsu logo passes and no menu appears: hold the power button 5 s to switch off,
     try again. If it fails twice, tap **F2** instead: this opens the setup; look for "Boot Menu"
     or "Boot Override" and choose the stick there.
3. The menu lists devices. Choose the entry with **UEFI** and the stick's name (e.g.
   `UEFI: SanDisk ...`). If there are two entries for the stick, take the UEFI one.
   **[CHECK]** If there is no UEFI entry, take a photo of the menu and **[STOP]**.
4. Press Enter.

---

## Part 6 — The installer

1. A Debian menu appears. The first line is **"Automated install (S940, erases internal disk)"**.
   It does **not** start by itself. Make sure it is highlighted, press **Enter**.
2. Text screens pass for 1-2 minutes (hardware detection, network). No action.
3. **The only question:** `Hostname:` with a suggested name. Delete the suggestion
   (Backspace), type the hostname you chose in Part 0, press **Enter**.
4. The installer now works alone, about 10-20 minutes. You will see, in this order:
   partitioning, "Installing the base system", "Configuring apt", "Select and install
   software" (the longest), "Installing GRUB", "Finishing the installation".
5. **If any other question appears** (language, password, disk, mirror, anything):
   do not answer it. Take a photo, **[STOP]** and send Claude what it says. If it appears
   *before* the partitioning screens, it is safe to switch off (hold power 5 s); nothing was
   written yet.
6. At the end the screen goes black and the machine restarts by itself. **When the Fujitsu
   logo appears, pull the stick out.**
   - If the Debian installer menu appears again (the stick was still in): do **not** press
     Enter. Pull the stick out, hold power 5 s, press power again.

---

## Part 7 — First start: note three values

1. The machine starts from its SSD. After about 30 s the screen shows a login prompt. Above it,
   Claude's installer has written three lines:

   ```
   Host: <hostname>
   IP:   192.168.20.x
   MAC:  xx:xx:xx:xx:xx:xx
   ```

2. Write down (or photograph) the three values.
3. You do **not** need to log in.
4. **[STOP]** Reply to Claude: `up <hostname> <IP> <MAC>`. Claude connects from the Pi
   over SSH with the key, checks the machine, and continues the setup without your hands.
   - If there is no IP line, or it says `IP:` empty: the cable or the switch port has no
     link. Reply with a photo; do not change anything.

---

## Part 8 — Finish

1. When Claude says `remote setup reachable`, unplug the monitor and the keyboard.
2. Leave power and Ethernet connected. Put the S940 where it will live.

---

## Part 9 — The second S940 (with the 250 GB SSD, next week)

Repeat Part 3 (SSD) to Part 8 with the same stick and the **other hostname**. Part 1 and
Part 2 are not repeated: the stick serves both machines. The password is the same.

---

## Things not to do

- Do not boot any other computer from this stick and press Enter on the automatic entry: it
  erases that computer's internal disk.
- Do not answer installer questions other than `Hostname:`. A question means the stick is
  missing a setting; Claude fixes the stick instead.
- Do not connect the S940 to Unit_B's cabling or to any unit; it needs only power and Ethernet.
