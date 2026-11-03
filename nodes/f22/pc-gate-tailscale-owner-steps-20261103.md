# Owner steps: Tailscale f22 -> pc-gate (2026-11-03)

Only the steps for your hands, each with **how** to do it. My steps and the checks: `pc-gate-tailscale-plan-20261103.md` (same step numbers).

## Read this first

- **Start a step only when my reply asks for it.** Each step ends with a **reply word** to me. Type it exactly.
- **You do not edit the policy text yourself.** You copy it to me, I return the complete new text, and you replace the old text with it. That avoids comma and bracket mistakes.
- **What you need:** a computer with a web browser, your Google account (the one your Tailscale uses), and the chat with me open.
- **Sources:** the page and button names below come from the Tailscale documentation (read 2026-11-03): page **Access controls**, **JSON editor**, page **Machines**, row menu items **Edit tags** and **Disable key expiry**, page **Configuration logs** (to revert). Names marked *(not confirmed)* come from my memory. If your screen shows something else, **stop and reply what you see**. Do not guess.
- **Order:** [me 1] -> **you 2** -> [me 3] -> **you 4** -> [me 5] -> [me 6.1] -> **you 6** -> [me 7] -> **you 8** -> [me 8.3].

---

## Step 2: access policy with isolation (~15 min, browser)

**Goal:** the policy gets two tags (`tag:gate` for pc-gate, `tag:bench` for f22) and these rules: the 3 Windows machines reach only each other; f22 reaches only pc-gate, SSH (port 22); neither side can reach the other. Your answers (2026-11-03): all 3 Windows machines use your Google account; none connects to pc-gate. (Steps 2 and 2b merged, owner 2026-11-03.)

### 2.1 Open the policy
1. In the browser, type this address and press Enter: `https://login.tailscale.com/admin/acls`
2. If a login page appears: click **Sign in with Google** *(not confirmed)* and choose your Google account.
3. You should now see the admin console with a menu at the top. The active item is **Access controls**.
4. The policy is shown as text in an editor. If you see two tabs such as **Visual editor** and **JSON editor** *(not confirmed)*, click **JSON editor**. The text starts with `{` and contains words in quotes, such as `"acls"` or `"grants"`.
   - **If you see something else:** stop. Reply `2 screen` with a short description of what you see.

### 2.2 Back up the current policy (do not skip)
1. Click once **inside** the text editor.
2. Press **Ctrl+A**, which selects all the text in the editor. Check that all of it is highlighted, not the whole web page.
3. Press **Ctrl+C**, which copies it.
4. Open a text editor on your computer (Notepad on Windows, TextEdit in plain-text mode on a Mac, or any editor). Press **Ctrl+V** to paste.
5. Save the file as `tailscale-policy-before-20261103.json` in a folder you will remember, such as Documents.
6. Check: the saved file starts with `{` and ends with `}`.

### 2.3 Send the policy to me
1. First answer one question in the same message: is any Windows machine used as an **exit node** (other devices send their internet traffic through it) or a **subnet router** (it gives access to its local network)? Write `exit no`, or name the machine and which one. If you are not sure: open `https://login.tailscale.com/admin/machines`; such a machine shows an `Exit Node` or `Subnets` badge under its name *(not confirmed)*.
2. Then write `2 policy` and paste the text you copied in 2.2 (Ctrl+V) below it.
3. It contains your tailnet's rules and perhaps e-mail addresses. It does **not** contain keys or passwords.
4. Wait for my reply. It contains:
   - the **complete new policy text** in one block. It names your login e-mail (taken from the text you pasted) as the owner of the two tags. It has a `tests` block that makes the page refuse any later change that would let a Windows machine reach f22 or pc-gate, or cut f22 off from pc-gate;
   - one line listing what it replaces in your current policy (for example the **allow-all** rule, which lets every device reach every other device). Everything else stays as it was.

### 2.4 Replace the text and save
1. Back in the browser, on **Access controls** -> **JSON editor**: click inside the editor.
2. Press **Ctrl+A**, then **Delete**. The editor is now empty.
3. In my reply, copy the whole new policy block: from the first `{` to the last `}`, nothing more, without the ``` marks around it.
4. Click inside the empty editor and press **Ctrl+V**.
5. Check: the first character is `{` and the last is `}`.
6. Click the save button below or above the editor. Its label is probably **Save** *(not confirmed)*.
7. What you should see:
   - **Saved:** a short confirmation, and the text stays as pasted.
   - **Error:** a red message with a line number. Do not try to fix it. Press Ctrl+A, Delete, paste your backup file's text, and save. Reply `2 error` with the exact message.
8. Go on to 2.5 (no reply yet).

### 2.5 Check one Windows machine (~2 min)
1. On one Windows machine, use the connection to another of your Windows machines that you normally use (for example Remote Desktop or a shared folder), the same way as before.
2. It must work as before. f22 and pc-gate are not part of this check.
3. Reply `saved, windows ok`. If it fails: paste the backup `tailscale-policy-before-20261103.json` back as in "If something goes wrong", and reply `windows fail` with what failed.

---

## Step 4: approve the two machines (~5 min, browser)

**Before:** I ran the join command on pc-gate and f22. My reply shows two links that start with `https://login.tailscale.com/a/`, one marked **pc-gate** and one marked **f22**.

### 4.1 Approve pc-gate
1. Copy the **pc-gate** link from my reply and open it in the browser.
2. If asked, sign in with the same Google account.
3. A page shows the device to be added. Check that its name is **pc-gate** *(the page layout is not confirmed)*.
4. Click the button that adds it. It is probably **Connect** *(not confirmed)*.
5. The page should then say the device is connected or logged in.
   - **If it says you may not use the tag, or shows an error:** stop. Reply `4 error` with the exact text. (Fallback, in my reply then: approve without the tag and set the tag by hand in 4.4.)

### 4.2 Approve f22
Do the same as 4.1 with the **f22** link. Check that the name is **f22**.

### 4.3 Check the Machines page
1. Open `https://login.tailscale.com/admin/machines`.
2. You see a list. Each row is one device.
3. Find the row **pc-gate**. Check, in that row:
   - the tag badge `tag:gate`,
   - an address that starts with `100.`,
   - the status shows it is connected *(the exact display is not confirmed)*.
4. Find the row **f22**: tag badge `tag:bench`, an address starting with `100.`, connected.
5. **Key expiry:** tagged devices get it disabled automatically (Tailscale documentation). To check: at the far right of the **pc-gate** row, click the menu icon (often `...`). If the menu offers **Disable key expiry**, click it, because expiry is then still on. If it offers **Enable key expiry** instead, it is already disabled: close the menu, change nothing. Do the same for **f22**.

### 4.4 Only if a tag is missing (fallback)
1. In the row's menu (far right), click **Edit tags**.
2. Add `tag:gate` for pc-gate or `tag:bench` for f22, then click **Save**.
3. After a tag change by hand, do 4.3 step 5 again (key expiry) for that row.

### 4.5 Reply
Reply `approved`. If a row is missing or looks different: reply `4 check` with what you see in each row.

---

## Step 6: move pc-gate to the other LAN (~your time)

**Before:** I shut pc-gate down over SSH and reply `pc-gate is off`.

1. Look at pc-gate: its power light must be **off**. Wait 10 more seconds.
   - **If the light is still on after 2 minutes:** do not pull the power. Reply `6 still on`.
2. Unplug the **power cable** from pc-gate, then the **Ethernet cable**.
3. If the CH340 / RS-485 USB adapter is plugged into pc-gate, you may leave it or take it out. It is not part of this test; just tell me which in step 6.7.
4. Take pc-gate and **its own power supply** to the other LAN.
5. Connect an Ethernet cable from pc-gate's Ethernet port to a free port on that LAN's router, or on a switch behind it. On most routers, the port marked **WAN** or **Internet** is wrong; use a **LAN** port, often numbered 1-4. Check that the port light comes on after power-on.
6. Connect the power. If pc-gate does not start by itself within 10 s, press its power button **once**, briefly.
7. Note the time on a clock when the power light comes on. Reply: `moved HH:MM`, and `adapter in` or `adapter out`.
8. Nothing needs setting on that router: no port forwarding, no fixed address, no login.
9. Then wait for my check (up to 5 min). If I reply `not reachable`, follow "If something goes wrong" below.

---

## Step 8: network cut (~12 min, at pc-gate)

**Before:** my reply says step 7 passed and asks for step 8.

1. Pull the **Ethernet cable out of pc-gate** (not out of the router). Leave the **power on**: the power light stays on.
2. Note the time. Reply `pulled HH:MM`.
3. Wait **10 minutes** by the clock.
4. Plug the same cable back into the **same port** of pc-gate, until it clicks. The port light should come on.
5. Note the time. Reply `back HH:MM`.
6. Nothing more for your hands. pc-gate stays where it is. I check within 1 min and reply PASS or FAIL.

---

## If something goes wrong

- **Restore the policy (any time):**
  - either: Access controls -> JSON editor -> Ctrl+A, Delete -> paste your backup file's text -> Save;
  - or: open the **Configuration logs** page in the admin console, find the entry for the policy change, and revert to the time before it. If no revert button is visible there, use the first way.
- **Remove a device from Tailscale:** Machines -> the row's menu (far right) -> **Remove** *(not confirmed)* -> confirm. Only when I ask for it.
- **pc-gate not reachable after step 6** (I reply `not reachable`):
  1. Check that pc-gate's power light is on, and that the Ethernet port light is on (both ends).
  2. Power-cycle: hold the power button until the light goes off (about 5 s), wait 10 s, press it once. Reply `cycled HH:MM`.
  3. If I still reply `not reachable` after 5 min: bring pc-gate back to our LAN, connect it as before, and reply `back home`.
- **Anything on the screen that does not match this document:** stop and reply what you see. Do not guess.
