# Second Futro S940 — session close 2026-11-14

Topic of this session (owner: "this conversation will be topic Second Futro", continued in a separate session). Next ZaxModbus-PS session starts at `ZaxModbus-PS/Doc/new-hardware/2026-11-14-close.md`, not here.

## State
- Machine: second Fujitsu Futro S940, 16 GB RAM, 256 GB SSD, preparations "almost ready" (owner). Not yet seen by me: no hostname, IP or MAC known, no row in `nodes/INDEX.md`, nothing installed or changed on it.
- Owner is considering Proxmox on it. No install decided. After Fable part 2 the owner wants all Claude features tried in an isolated environment "until I completely understand the interactions".
- Claude features seen in the Artifact tool this session: Design, Design System, Data, Slides, Whiteboard. Docs and Sheets need the Claude Docs connector, not attached (owner's action, account settings). Browser/Chrome/computer-use skills need the desktop app or Chrome, not available headless on f22. The plugin/MCP state of f22 was not checked (Fable part 2 says: no plugin, no browser, connectors off, one MCP server disabled; from its own reading, unverified by me).

## Fable files (saved unedited, new files; original kept until the owner says "merge")
- Part 1 `nodes/second-futro-usage-fable-20261114.md` (+ `.pdf`): 3 best usages (web application lab, test copy of the workstation services, software twin of the gateway = weakest), 2 to avoid (another backup/reserve machine; the bench or a second bench inside Proxmox).
- Part 2 `nodes/second-futro-usage-fable-20261114-part2.md` (+ `.pdf`): isolated lab = the second S940 with Proxmox, internal network without access to 192.168.20.x; 11 steps, one check each (1-4 install, bridge, firewall, clean container, about half a day; 5-8 one feature each; 9-10 optional; 11 owner review); four ways out of isolation, each the owner's decision. Changes against part 1 listed at its end. Nothing in it was run or tested.
- PDFs: built with fpdf2 (table cells lose bold/code/links). Source of the converter: scratchpad only (`md2pdf.py`, not kept).

## Done and recorded
- PDFs on `ws:/home/dan-linux/psz001-status/docs/`, linked at the top of the ws:8091 root page (source `ZaxModbus-PS/Doc/new-hardware/Zero-4804/journal.md`, line above the list). The link line leaves the root when another journal becomes the root; the PDFs stay in `docs/`. Entry in `Workstation/INTERVENTIONS.md`.
- Commits pushed: Workspace `9e8726e` (2 md + 2 pdf), ZaxModbus-PS `2f5bab7` (journal.md). This close note and the memory line are not committed.
- PDF tool on f22: `~/.venvs/mdpdf-lib` (pip `--target`: fpdf2, markdown); `python3-venv` is missing on f22, no apt change made. errors-history entry written.

## Mistake of the session
- I called the off-host backup a gap without looking up what futro backs up. Owner: futro was the raspi backup and already covers it. Dropped from the proposals (Fable got the correction in its input).

## Open (owner decides; nothing started)
1. Proxmox lab: install yes/no, and when (part 2 steps 1-4).
2. Merge of part 1 and part 2: not said.
3. Docs connector for the account: owner's action.
4. Name and `nodes/INDEX.md` row for the second Futro, when it is on the network (find it by MAC, never by an assumed IP).

## Not checked
The second machine itself (CPU, VT-x/VT-d, BIOS), the router (VLAN, DNS for an isolated bridge), which features the account plan includes, the pc-gate operating system, what futro's backup covers beyond the gh-backup mirrors.
